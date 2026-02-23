import { NextRequest } from "next/server";
import { requireUser } from "@/lib/guard";
import { fail, ok } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ROLES } from "@/lib/roles";
import { fiscalIssueSchema } from "@/lib/validation";

const ALLOWED = [ROLES.ADMINISTRADOR, ROLES.GERENTE];

export async function GET(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const { searchParams } = new URL(req.url);
  const status = searchParams.get("status");

  const config = await prisma.fiscalConfig.findFirst();
  const invoices = await prisma.fiscalInvoice.findMany({
    where: { status: status ?? undefined },
    orderBy: { issuedAt: "desc" },
    take: 200,
  });

  return ok({ config, invoices });
}

export async function POST(req: NextRequest) {
  const auth = await requireUser(ALLOWED);
  if (!auth.user) return fail(auth.error ?? "Sem permissão", 403);

  const body = await req.json();
  const action = body?.action as string;

  if (action === "ISSUE") {
    const parsed = fiscalIssueSchema.safeParse(body);
    if (!parsed.success) return fail("Dados inválidos", 422, parsed.error.flatten());

    const config = await prisma.fiscalConfig.findFirst();
    if (!config) return fail("Configuração fiscal não encontrada", 404);

    const number = parsed.data.type === "NFE" ? config.nextNfeNumber : config.nextNfceNumber;

    const invoice = await prisma.fiscalInvoice.create({
      data: {
        number,
        series: config.series,
        type: parsed.data.type,
        customerName: parsed.data.customerName,
        customerDoc: parsed.data.customerDoc,
        totalValue: parsed.data.totalValue,
        status: "AUTORIZADA",
        operatorName: auth.user.name,
        xmlPath: `/fiscal/xml/${parsed.data.type}-${number}.xml`,
        danfePath: `/fiscal/danfe/${parsed.data.type}-${number}.pdf`,
      },
    });

    await prisma.fiscalConfig.update({
      where: { id: config.id },
      data:
        parsed.data.type === "NFE"
          ? { nextNfeNumber: { increment: 1 } }
          : { nextNfceNumber: { increment: 1 } },
    });

    return ok(invoice, 201);
  }

  if (action === "CANCEL") {
    const { invoiceId, justification } = body;
    if (!invoiceId || !justification) return fail("Nota e justificativa são obrigatórias", 422);

    const invoice = await prisma.fiscalInvoice.update({
      where: { id: invoiceId },
      data: { status: "CANCELADA" },
    });

    await prisma.fiscalCancellation.create({
      data: {
        invoiceId: invoice.id,
        justification,
        operatorName: auth.user.name,
      },
    });

    return ok(invoice);
  }

  if (action === "UPDATE_CONFIG") {
    const { environment, series, nextNfeNumber, nextNfceNumber } = body;
    const config = await prisma.fiscalConfig.findFirst();
    if (!config) return fail("Configuração fiscal não encontrada", 404);

    const updated = await prisma.fiscalConfig.update({
      where: { id: config.id },
      data: {
        environment: environment ?? config.environment,
        series: series ?? config.series,
        nextNfeNumber: nextNfeNumber ?? config.nextNfeNumber,
        nextNfceNumber: nextNfceNumber ?? config.nextNfceNumber,
      },
    });

    return ok(updated);
  }

  if (action === "TEST_SEFAZ") {
    const cert = await prisma.digitalCertificate.findFirst({ orderBy: { importedAt: "desc" } });
    return ok({
      certificateValid: Boolean(cert && cert.validUntil > new Date()),
      environmentReachable: true,
      sefazResponding: true,
      message: "Teste simulado: pronto para integrar com provedor SEFAZ real",
    });
  }

  return fail("Ação inválida", 422);
}
