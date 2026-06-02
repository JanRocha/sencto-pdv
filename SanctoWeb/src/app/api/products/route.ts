import { NextRequest } from "next/server";
import { logAudit } from "@/lib/audit";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { productSchema } from "@/lib/validation";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get("search") ?? "";
  const category = searchParams.get("category") ?? undefined;
  const status = searchParams.get("status");

  const products = await prisma.product.findMany({
    where: {
      name: { contains: search },
      category: category ? { name: category } : undefined,
      active: status === "all" || !status ? undefined : status === "active",
    },
    include: { category: true },
    orderBy: { name: "asc" },
  });

  return ok(products);
}

export async function POST(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  try {
    const body = await req.json();
    const parsed = productSchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const data = parsed.data;
    const category = await prisma.category.upsert({
      where: { name: data.categoryName },
      update: {},
      create: { name: data.categoryName, active: true },
    });

    const product = await prisma.product.create({
      data: {
        name: data.name,
        description: data.description,
        barcode: data.barcode,
        internalCode: data.internalCode,
        categoryId: category.id,
        salePrice: data.salePrice,
        promoPrice: data.promoPrice,
        costPrice: data.costPrice,
        stock: data.stock,
        minStock: data.minStock,
        unit: data.unit,
        type: data.type,
        ncm: data.ncm,
        cfop: data.cfop,
        cstOrCsosn: data.cstOrCsosn,
        icmsRate: data.icmsRate,
        pisRate: data.pisRate,
        cofinsRate: data.cofinsRate,
        fiscalOrigin: data.fiscalOrigin,
        active: data.active,
        imageUrl: data.imageUrl,
        internalNotes: data.internalNotes,
        sellByCommand: data.sellByCommand,
        supplier: data.supplier,
      },
      include: { category: true },
    });

    await logAudit({
      userId: auth.user.id,
      action: "PRODUCT_CREATE",
      targetType: "PRODUCT",
      targetId: product.id,
      details: JSON.stringify({ name: product.name }),
    });

    return ok(product, 201);
  } catch (error) {
    return fail("Erro ao criar produto", 500, error);
  }
}

export async function PUT(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");
  if (!id) return fail("ID do produto é obrigatório", 422);

  try {
    const body = await req.json();
    const parsed = productSchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const data = parsed.data;
    const category = await prisma.category.upsert({
      where: { name: data.categoryName },
      update: {},
      create: { name: data.categoryName, active: true },
    });

    const product = await prisma.product.update({
      where: { id },
      data: {
        name: data.name,
        description: data.description,
        barcode: data.barcode,
        internalCode: data.internalCode,
        categoryId: category.id,
        salePrice: data.salePrice,
        promoPrice: data.promoPrice,
        costPrice: data.costPrice,
        stock: data.stock,
        minStock: data.minStock,
        unit: data.unit,
        type: data.type,
        ncm: data.ncm,
        cfop: data.cfop,
        cstOrCsosn: data.cstOrCsosn,
        icmsRate: data.icmsRate,
        pisRate: data.pisRate,
        cofinsRate: data.cofinsRate,
        fiscalOrigin: data.fiscalOrigin,
        active: data.active,
        imageUrl: data.imageUrl,
        internalNotes: data.internalNotes,
        sellByCommand: data.sellByCommand,
        supplier: data.supplier,
      },
      include: { category: true },
    });

    await logAudit({
      userId: auth.user.id,
      action: "PRODUCT_UPDATE",
      targetType: "PRODUCT",
      targetId: product.id,
      details: JSON.stringify({ name: product.name }),
    });

    return ok(product);
  } catch (error) {
    return fail("Erro ao atualizar produto", 500, error);
  }
}

export async function DELETE(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");
  if (!id) return fail("ID do produto é obrigatório", 422);

  const saleItemsCount = await prisma.saleItem.count({ where: { productId: id } });

  if (saleItemsCount > 0) {
    const deactivated = await prisma.product.update({ where: { id }, data: { active: false } });
    await logAudit({
      userId: auth.user.id,
      action: "PRODUCT_DEACTIVATE",
      targetType: "PRODUCT",
      targetId: id,
      details: "Produto com venda registrada, apenas desativado",
    });
    return ok({ message: "Produto desativado", product: deactivated });
  }

  await prisma.product.delete({ where: { id } });
  await logAudit({
    userId: auth.user.id,
    action: "PRODUCT_DELETE",
    targetType: "PRODUCT",
    targetId: id,
  });

  return ok({ message: "Produto removido" });
}
