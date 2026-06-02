import { NextRequest } from "next/server";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { childSchema, tutorSchema } from "@/lib/validation";

export async function GET(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const cpf = searchParams.get("cpf") ?? undefined;
  const name = searchParams.get("name") ?? undefined;

  const tutors = await prisma.tutor.findMany({
    where: {
      cpf: cpf ? { contains: cpf } : undefined,
      fullName: name ? { contains: name } : undefined,
    },
    include: {
      children: true,
      visits: {
        include: {
          child: true,
          items: { include: { product: true } },
        },
        orderBy: { createdAt: "desc" },
      },
    },
    take: 50,
  });

  return ok(tutors);
}

export async function POST(req: NextRequest) {
  const auth = await requireUser([ROLES.ADMINISTRADOR, ROLES.GERENTE, ROLES.OPERACIONAL]);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const action = body?.action;

  if (action === "CREATE_TUTOR") {
    const parsed = tutorSchema.safeParse(body);
    if (!parsed.success) return fail("Tutor inválido", 422, parsed.error.flatten());

    const tutor = await prisma.tutor.create({
      data: {
        fullName: parsed.data.fullName,
        cpf: parsed.data.cpf,
        birthDate: new Date(parsed.data.birthDate),
        email: parsed.data.email,
        phone1: parsed.data.phone1,
        phone2: parsed.data.phone2,
        address: parsed.data.address,
      },
    });

    return ok(tutor, 201);
  }

  if (action === "CREATE_CHILD") {
    const parsed = childSchema.safeParse(body);
    if (!parsed.success) return fail("Criança inválida", 422, parsed.error.flatten());

    const child = await prisma.child.create({
      data: {
        tutorId: parsed.data.tutorId,
        fullName: parsed.data.fullName,
        birthDate: new Date(parsed.data.birthDate),
        specialDiscount: parsed.data.specialDiscount,
        consumeLimit: parsed.data.consumeLimit,
      },
    });

    return ok(child, 201);
  }

  if (action === "START_VISIT") {
    const { tutorId, childId, ticketProductId } = body;
    if (!tutorId || !childId || !ticketProductId) {
      return fail("Tutor, criança e ingresso são obrigatórios", 422);
    }

    const ticket = await prisma.product.findUnique({ where: { id: ticketProductId } });
    if (!ticket) return fail("Ingresso não encontrado", 404);

    const minutes =
      ticket.name.includes("30") ? 30 :
      ticket.name.includes("120") ? 120 :
      ticket.name.toLowerCase().includes("dia livre") ? 720 :
      60;

    const entryAt = new Date();
    const expectedExitAt = new Date(entryAt.getTime() + minutes * 60 * 1000);

    const visit = await prisma.visit.create({
      data: {
        tutorId,
        childId,
        ticketProductId,
        entryAt,
        expectedExitAt,
      },
    });

    return ok(visit, 201);
  }

  return fail("Ação inválida", 422);
}
