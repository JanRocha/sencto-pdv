import { getSessionUser } from "@/lib/auth";

export async function requireUser(roles?: string[]) {
  const user = await getSessionUser();
  if (!user) return { user: null, error: "Não autenticado" };
  if (roles && !roles.includes(user.role)) {
    return { user: null, error: "Sem permissão" };
  }
  return { user, error: null };
}
