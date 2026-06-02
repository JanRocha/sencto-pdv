import { NextRequest } from "next/server";
import { logAudit } from "@/lib/audit";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { saleSchema } from "@/lib/validation";

export async function GET() {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const sales = await prisma.sale.findMany({
    include: { items: { include: { product: true } }, user: true },
    orderBy: { createdAt: "desc" },
    take: 100,
  });

  return ok(sales);
}

export async function POST(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const parsed = saleSchema.safeParse(body);
  if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

  const cash = await prisma.cashRegister.findFirst({
    where: { userId: auth.user.id, status: "ABERTO" },
  });

  if (!cash) {
    return fail("Caixa fechado. Abra o caixa para realizar vendas.", 422);
  }

  const subtotal = parsed.data.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
  const total = subtotal - parsed.data.discount;

  const result = await prisma.$transaction(async (tx: any) => {
    for (const item of parsed.data.items) {
      const product = await tx.product.findUnique({ where: { id: item.productId } });
      if (!product || !product.active) {
        throw new Error(`Produto inválido: ${item.productId}`);
      }
      if (product.stock < item.quantity) {
        throw new Error(`Estoque insuficiente para ${product.name}`);
      }
    }

    const sale = await tx.sale.create({
      data: {
        userId: auth.user.id,
        cashRegisterId: cash.id,
        subtotal,
        discount: parsed.data.discount,
        total,
        paymentMethod: parsed.data.paymentMethod,
        installments: parsed.data.installments,
        customerCpf: parsed.data.customerCpf,
        items: {
          create: parsed.data.items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            total: item.unitPrice * item.quantity,
            note: item.note,
          })),
        },
      },
      include: { items: true },
    });

    for (const item of parsed.data.items) {
      await tx.product.update({
        where: { id: item.productId },
        data: { stock: { decrement: item.quantity } },
      });
    }

    return sale;
  });

  await logAudit({
    userId: auth.user.id,
    action: "SALE_CREATE",
    targetType: "SALE",
    targetId: result.id,
    details: JSON.stringify({ total, paymentMethod: parsed.data.paymentMethod }),
  });

  return ok(result, 201);
}
