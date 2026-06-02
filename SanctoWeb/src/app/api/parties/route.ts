import { NextRequest } from "next/server";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { partySchema } from "@/lib/validation";

export async function GET(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const month = Number(searchParams.get("month") ?? new Date().getMonth() + 1);
  const year = Number(searchParams.get("year") ?? new Date().getFullYear());

  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);

  const parties = await prisma.party.findMany({
    where: { date: { gte: start, lt: end } },
    include: { package: true },
    orderBy: [{ date: "asc" }, { timeSlot: "asc" }],
  });

  const revenue = parties.reduce((sum: number, p: { amountTotal: unknown }) => sum + Number(p.amountTotal), 0);
  const packageCount = parties.reduce<Record<string, number>>((acc: Record<string, number>, p: { package: { name: string } }) => {
    acc[p.package.name] = (acc[p.package.name] ?? 0) + 1;
    return acc;
  }, {});
  const topPackage = (Object.entries(packageCount) as [string, number][]).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "-";
  const packages = await prisma.partyPackage.findMany({ orderBy: { name: "asc" } });

  return ok({ parties, packages, stats: { totalParties: parties.length, estimatedRevenue: revenue, topPackage } });
}

export async function POST(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const action = body?.action as string;

  if (action === "CREATE") {
    const parsed = partySchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const duplicate = await prisma.party.findFirst({
      where: { date: new Date(parsed.data.date), timeSlot: parsed.data.timeSlot, status: { not: "CANCELADA" } },
    });

    if (duplicate) return fail("Já existe festa agendada para data/horário", 422);

    const party = await prisma.party.create({
      data: {
        birthdayChildName: parsed.data.birthdayChildName,
        tutorName: parsed.data.tutorName,
        tutorCpf: parsed.data.tutorCpf,
        tutorEmail: parsed.data.tutorEmail,
        tutorPhone: parsed.data.tutorPhone,
        tutorAddress: parsed.data.tutorAddress,
        date: new Date(parsed.data.date),
        timeSlot: parsed.data.timeSlot,
        packageId: parsed.data.packageId,
        holidayCustom: parsed.data.holidayCustom,
        amountTotal: parsed.data.amountTotal,
        amountPaid: parsed.data.amountPaid,
        notes: parsed.data.notes,
      },
      include: { package: true },
    });

    return ok(party, 201);
  }

  if (action === "CANCEL") {
    const { id, reason } = body;
    if (!id || !reason) return fail("ID e justificativa são obrigatórios", 422);

    const party = await prisma.party.update({
      where: { id },
      data: { status: "CANCELADA", cancelReason: reason },
      include: { package: true },
    });

    return ok(party);
  }

  return fail("Ação inválida", 422);
}
