import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";

export async function GET() {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const [todaySales, openVisits, lowStock, todayInvoices] = await Promise.all([
    prisma.sale.aggregate({
      _sum: { total: true },
      where: { createdAt: { gte: todayStart } },
    }),
    prisma.visit.count({ where: { status: "ABERTA" } }),
    prisma.product.count({ where: { stock: { lte: 5 }, active: true } }),
    prisma.fiscalInvoice.count({ where: { issuedAt: { gte: todayStart } } }),
  ]);

  return ok({
    totalVendasHoje: Number(todaySales._sum.total ?? 0),
    visitasAbertas: openVisits,
    estoqueBaixo: lowStock,
    notasHoje: todayInvoices,
  });
}
