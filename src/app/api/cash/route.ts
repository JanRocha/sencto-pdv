import { NextRequest } from "next/server";
import { logAudit } from "@/lib/audit";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { cashMovementSchema, cashOpenSchema } from "@/lib/validation";

export async function GET() {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const current = await prisma.cashRegister.findFirst({
    where: { userId: auth.user.id, status: "ABERTO" },
    include: { movements: { orderBy: { createdAt: "desc" } } },
    orderBy: { openedAt: "desc" },
  });

  return ok(current);
}

export async function POST(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const action = body?.action as string;

  if (action === "OPEN") {
    const parsed = cashOpenSchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const alreadyOpen = await prisma.cashRegister.findFirst({
      where: { userId: auth.user.id, status: "ABERTO" },
    });

    if (alreadyOpen) return fail("Já existe caixa aberto para este usuário", 422);

    const cash = await prisma.cashRegister.create({
      data: {
        userId: auth.user.id,
        initialAmount: parsed.data.initialAmount,
        observations: parsed.data.observations,
      },
    });

    await logAudit({
      userId: auth.user.id,
      action: "CASH_OPEN",
      targetType: "CASH_REGISTER",
      targetId: cash.id,
      details: JSON.stringify({ initialAmount: parsed.data.initialAmount }),
    });

    return ok(cash, 201);
  }

  if (action === "MOVE") {
    const parsed = cashMovementSchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const opened = await prisma.cashRegister.findFirst({
      where: { userId: auth.user.id, status: "ABERTO" },
    });

    if (!opened) return fail("Não há caixa aberto", 422);

    const movement = await prisma.cashMovement.create({
      data: {
        cashRegisterId: opened.id,
        userId: auth.user.id,
        type: parsed.data.type,
        amount: parsed.data.amount,
        reason: parsed.data.reason,
      },
    });

    await logAudit({
      userId: auth.user.id,
      action: `CASH_${parsed.data.type}`,
      targetType: "CASH_MOVEMENT",
      targetId: movement.id,
      details: JSON.stringify({ amount: parsed.data.amount, reason: parsed.data.reason }),
    });

    return ok(movement, 201);
  }

  if (action === "CLOSE") {
    const opened = await prisma.cashRegister.findFirst({
      where: { userId: auth.user.id, status: "ABERTO" },
      include: {
        sales: true,
        movements: true,
      },
    });

    if (!opened) return fail("Não há caixa aberto", 422);

    const salesTotal = opened.sales.reduce((sum: number, sale: { total: unknown }) => sum + Number(sale.total), 0);
    const movementAdjust = opened.movements.reduce((sum: number, mv: { amount: unknown; type: string }) => {
      const value = Number(mv.amount);
      return mv.type === "SUPRIMENTO" ? sum + value : sum - value;
    }, 0);

    const expected = Number(opened.initialAmount) + salesTotal + movementAdjust;

    const counted = Number(body?.countedAmount ?? expected);
    const difference = counted - expected;

    const closed = await prisma.cashRegister.update({
      where: { id: opened.id },
      data: {
        status: "FECHADO",
        closedAt: new Date(),
        observations: [opened.observations, `COUNTED:${counted}`, `EXPECTED:${expected}`, `DIFF:${difference}`]
          .filter(Boolean)
          .join(" | "),
      },
    });

    await logAudit({
      userId: auth.user.id,
      action: "CASH_CLOSE",
      targetType: "CASH_REGISTER",
      targetId: opened.id,
      details: JSON.stringify({ expected, counted, difference }),
    });

    return ok({ cash: closed, expected, counted, difference });
  }

  return fail("Ação inválida", 422);
}
