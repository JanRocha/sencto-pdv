import {
  ErpProvider,
  FiscalCancelInput,
  FiscalCancelResult,
  FiscalHealth,
  FiscalIssueInput,
  FiscalIssueResult,
  FiscalProvider,
  MessagingProvider,
} from "@/lib/integrations/contracts";

class MockFiscalProvider implements FiscalProvider {
  readonly name = "mock";

  async testConnection(input: { environment: string; hasCertificate: boolean }): Promise<FiscalHealth> {
    const environmentReachable = true;
    const sefazResponding = input.environment === "producao" ? input.hasCertificate : true;

    return {
      environmentReachable,
      sefazResponding,
      message: sefazResponding
        ? `Conectividade fiscal simulada (${input.environment}) OK`
        : "Conectividade simulada sem resposta válida (certificado ausente)",
    };
  }

  async issueInvoice(input: FiscalIssueInput): Promise<FiscalIssueResult> {
    return {
      accepted: true,
      protocol: `MOCK-${input.type}-${input.number}-${Date.now()}`,
      message: `Emissão simulada concluída em ${input.environment}`,
    };
  }

  async cancelInvoice(input: FiscalCancelInput): Promise<FiscalCancelResult> {
    return {
      accepted: true,
      protocol: `MOCK-CANCEL-${input.invoiceNumber}-${Date.now()}`,
      message: `Cancelamento simulado concluído em ${input.environment}`,
    };
  }
}

class RealFiscalProvider implements FiscalProvider {
  readonly name = "real";

  async testConnection(input: { environment: string; hasCertificate: boolean }): Promise<FiscalHealth> {
    if (!input.hasCertificate) {
      return {
        environmentReachable: false,
        sefazResponding: false,
        message: "Certificado digital não configurado para operação real",
      };
    }

    return {
      environmentReachable: false,
      sefazResponding: false,
      message: `Provider real (${input.environment}) preparado, aguardando conector SEFAZ homologado`,
    };
  }

  async issueInvoice(input: FiscalIssueInput): Promise<FiscalIssueResult> {
    return {
      accepted: false,
      message: `Provider real selecionado para ${input.type}, mas emissão ainda não homologada com SEFAZ`,
    };
  }

  async cancelInvoice(input: FiscalCancelInput): Promise<FiscalCancelResult> {
    return {
      accepted: false,
      message: `Provider real selecionado para NF ${input.invoiceNumber}, mas cancelamento ainda não homologado com SEFAZ`,
    };
  }
}

class MockMessagingProvider implements MessagingProvider {
  readonly name = "mock";

  async sendStayLimitAlert(input: {
    tutorPhone: string;
    childName: string;
    minutesRemaining: number;
  }): Promise<{ queued: boolean; message: string }> {
    return {
      queued: true,
      message: `Alerta mock enfileirado para ${input.tutorPhone} (${input.childName} - ${input.minutesRemaining} min)`,
    };
  }
}

class RealMessagingProvider implements MessagingProvider {
  readonly name = "real";

  async sendStayLimitAlert(input: {
    tutorPhone: string;
    childName: string;
    minutesRemaining: number;
  }): Promise<{ queued: boolean; message: string }> {
    return {
      queued: false,
      message: `Provider real selecionado para ${input.tutorPhone}, aguardando credenciais e template homologado no WhatsApp Business`,
    };
  }
}

class MockErpProvider implements ErpProvider {
  readonly name = "mock";

  async syncSale(input: { saleId: string }): Promise<{ synced: boolean; message: string }> {
    return {
      synced: true,
      message: `Venda ${input.saleId} sincronizada em modo mock`,
    };
  }
}

export function getFiscalProvider(): FiscalProvider {
  const provider = process.env.FISCAL_PROVIDER ?? "mock";
  if (provider === "mock") return new MockFiscalProvider();
  if (provider === "real") return new RealFiscalProvider();
  return new MockFiscalProvider();
}

export function getMessagingProvider(): MessagingProvider {
  const provider = process.env.WHATSAPP_PROVIDER ?? "mock";
  if (provider === "mock") return new MockMessagingProvider();
  if (provider === "real") return new RealMessagingProvider();
  return new MockMessagingProvider();
}

export function getErpProvider(): ErpProvider {
  const provider = process.env.ERP_PROVIDER ?? "mock";
  if (provider === "mock") return new MockErpProvider();
  return new MockErpProvider();
}
