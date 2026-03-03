import { NextRequest } from "next/server";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { getMessagingProvider } from "@/lib/integrations";
import { ROLES } from "@/lib/roles";
import { whatsappTestAlertSchema } from "@/lib/validation";

const ALLOWED = [ROLES.ADMINISTRADOR, ROLES.GERENTE];

export async function POST(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const parsed = whatsappTestAlertSchema.safeParse(body);
  if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

  const provider = getMessagingProvider();
  const result = await provider.sendStayLimitAlert(parsed.data);

  return ok({
    provider: provider.name,
    queued: result.queued,
    message: result.message,
  });
}
