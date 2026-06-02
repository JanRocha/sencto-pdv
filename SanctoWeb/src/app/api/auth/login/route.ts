import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { comparePassword, setSessionCookie, signToken } from "@/lib/auth";
import { fail, ok } from "@/lib/http";
import { loginSchema } from "@/lib/validation";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = loginSchema.safeParse(body);
    if (!parsed.success) {
      return fail("Dados de login inválidos", 422, parsed.error.flatten());
    }

    const { cpf, password } = parsed.data;
    const user = await prisma.user.findUnique({ where: { cpf } });

    if (!user || !user.active) {
      return fail("Usuário não encontrado ou inativo", 401);
    }

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      return fail("Usuário bloqueado temporariamente por tentativas inválidas", 423);
    }

    const valid = await comparePassword(password, user.passwordHash);
    if (!valid) {
      const attempts = user.failedLoginAttempts + 1;
      const lockUntil = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null;
      await prisma.user.update({
        where: { id: user.id },
        data: {
          failedLoginAttempts: attempts >= 5 ? 0 : attempts,
          lockedUntil: lockUntil,
        },
      });
      return fail("Senha inválida", 401);
    }

    await prisma.user.update({
      where: { id: user.id },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
        lastAccessAt: new Date(),
      },
    });

    const token = signToken({ id: user.id, name: user.fullName, cpf: user.cpf, role: user.role });
    await setSessionCookie(token);

    return ok({ id: user.id, name: user.fullName, role: user.role });
  } catch (error) {
    return fail("Erro ao autenticar", 500, error);
  }
}
