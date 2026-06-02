export type FiscalHealth = {
  environmentReachable: boolean;
  sefazResponding: boolean;
  message: string;
};

export type FiscalIssueInput = {
  environment: string;
  type: "NFE" | "NFCE";
  number: number;
  series: number;
  customerName?: string;
  customerDoc?: string;
  totalValue: number;
};

export type FiscalIssueResult = {
  accepted: boolean;
  protocol?: string;
  message: string;
};

export type FiscalCancelInput = {
  environment: string;
  invoiceNumber: number;
  justification: string;
};

export type FiscalCancelResult = {
  accepted: boolean;
  protocol?: string;
  message: string;
};

export interface FiscalProvider {
  readonly name: string;
  testConnection(input: { environment: string; hasCertificate: boolean }): Promise<FiscalHealth>;
  issueInvoice(input: FiscalIssueInput): Promise<FiscalIssueResult>;
  cancelInvoice(input: FiscalCancelInput): Promise<FiscalCancelResult>;
}

export interface MessagingProvider {
  readonly name: string;
  sendStayLimitAlert(input: {
    tutorPhone: string;
    childName: string;
    minutesRemaining: number;
  }): Promise<{ queued: boolean; message: string }>;
}

export interface ErpProvider {
  readonly name: string;
  syncSale(input: { saleId: string }): Promise<{ synced: boolean; message: string }>;
}
