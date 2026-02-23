import { NextRequest } from "next/server";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";

export async function GET(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const start = searchParams.get("start") ? new Date(searchParams.get("start") as string) : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  const end = searchParams.get("end") ? new Date(searchParams.get("end") as string) : new Date();

  const sales = await prisma.sale.findMany({
    where: { createdAt: { gte: start, lte: end } },
    include: { items: { include: { product: true } }, user: true },
  });

  const total = sales.reduce((sum: number, s: { total: unknown }) => sum + Number(s.total), 0);

  const byPayment = sales.reduce<Record<string, number>>((acc: Record<string, number>, s: { paymentMethod: string; total: unknown }) => {
    acc[s.paymentMethod] = (acc[s.paymentMethod] ?? 0) + Number(s.total);
    return acc;
  }, {});

  const products = sales.flatMap((s: { items: Array<{ product: { name: string }; quantity: number; total: unknown }> }) => s.items);
  const topProductsMap = products.reduce<Record<string, { quantity: number; value: number }>>((acc: Record<string, { quantity: number; value: number }>, item: { product: { name: string }; quantity: number; total: unknown }) => {
    const name = item.product.name;
    if (!acc[name]) acc[name] = { quantity: 0, value: 0 };
    acc[name].quantity += item.quantity;
    acc[name].value += Number(item.total);
    return acc;
  }, {});

  const topProducts = (Object.entries(topProductsMap) as [string, { quantity: number; value: number }][])
    .map(([name, data]) => ({ name, quantity: data.quantity, value: data.value }))
    .sort((a, b) => b.quantity - a.quantity)
    .slice(0, 10);

  const tickets = await prisma.product.findMany({
    where: { type: { contains: "Ingresso" } },
    select: { id: true, name: true },
  });

  return ok({
    period: { start, end },
    totalSales: total,
    salesCount: sales.length,
    byPayment,
    topProducts,
    ticketTypes: tickets,
  });
}
