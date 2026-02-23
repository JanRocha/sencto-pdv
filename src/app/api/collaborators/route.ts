import { AppRole, ROLES } from "@/lib/roles";
import { NextRequest } from "next/server";
import { logAudit } from "@/lib/audit";
import { hashPassword } from "@/lib/auth";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { collaboratorSchema } from "@/lib/validation";

const ALLOWED: AppRole[] = [ROLES.ADMINISTRADOR, ROLES.GERENTE];

export async function GET() {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const users = await prisma.user.findMany({
    orderBy: { fullName: "asc" },
    select: {
      id: true,
      fullName: true,
      cpf: true,
      email: true,
      phone: true,
      role: true,
      active: true,
      lastAccessAt: true,
      createdAt: true,
    },
  });

  return ok(users);
}

export async function POST(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const parsed = collaboratorSchema.safeParse(body);
  if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());
  if (!parsed.data.password) return fail("Senha obrigatória para novo colaborador", 422);

  try {
    const passwordHash = await hashPassword(parsed.data.password);
    const user = await prisma.user.create({
      data: {
        fullName: parsed.data.fullName,
        cpf: parsed.data.cpf,
        email: parsed.data.email,
        phone: parsed.data.phone,
        role: parsed.data.role,
        active: parsed.data.active,
        passwordHash,
      },
    });

    await logAudit({
      userId: auth.user.id,
      action: "USER_CREATE",
      targetType: "USER",
      targetId: user.id,
      details: JSON.stringify({ cpf: user.cpf, role: user.role }),
    });

    return ok(user, 201);
  } catch (error) {
    return fail("Erro ao criar colaborador (verifique duplicidade de CPF/e-mail)", 500, error);
  }
}

export async function PUT(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");
  if (!id) return fail("ID obrigatório", 422);

  const body = await req.json();
  const parsed = collaboratorSchema.safeParse(body);
  if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

  try {
    const updateData: {
      fullName: string;
      email: string;
      phone: string;
      role: AppRole;
      active: boolean;
      passwordHash?: string;
    } = {
      fullName: parsed.data.fullName,
      email: parsed.data.email,
      phone: parsed.data.phone,
      role: parsed.data.role,
      active: parsed.data.active,
    };

    if (parsed.data.password) {
      updateData.passwordHash = await hashPassword(parsed.data.password);
    }

    const user = await prisma.user.update({ where: { id }, data: updateData });

    await logAudit({
      userId: auth.user.id,
      action: "USER_UPDATE",
      targetType: "USER",
      targetId: id,
      details: JSON.stringify({ role: user.role, active: user.active }),
    });

    return ok(user);
  } catch (error) {
    return fail("Erro ao atualizar colaborador", 500, error);
  }
}

export async function DELETE(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");
  if (!id) return fail("ID obrigatório", 422);

  if (auth.user.id === id) {
    return fail("Não é permitido excluir o próprio usuário", 422);
  }

  await prisma.user.delete({ where: { id } });
  await logAudit({
    userId: auth.user.id,
    action: "USER_DELETE",
    targetType: "USER",
    targetId: id,
  });

  return ok({ message: "Colaborador excluído" });
}
