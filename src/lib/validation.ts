import { z } from "zod";

export const loginSchema = z.object({
  cpf: z.string().min(11, "CPF obrigatório"),
  password: z.string().min(6, "Senha obrigatória"),
});

export const productSchema = z.object({
  name: z.string().min(2),
  description: z.string().optional().nullable(),
  barcode: z.string().min(3),
  internalCode: z.string().optional().nullable(),
  categoryName: z.string().min(2),
  salePrice: z.number().nonnegative(),
  promoPrice: z.number().nonnegative().optional().nullable(),
  costPrice: z.number().nonnegative().optional().nullable(),
  stock: z.number().int().nonnegative(),
  minStock: z.number().int().nonnegative(),
  unit: z.string().min(1),
  type: z.string().min(1),
  ncm: z.string().min(3),
  cfop: z.string().min(3),
  cstOrCsosn: z.string().min(2),
  icmsRate: z.number().nonnegative(),
  pisRate: z.number().nonnegative(),
  cofinsRate: z.number().nonnegative(),
  fiscalOrigin: z.string().optional().nullable(),
  active: z.boolean().default(true),
  imageUrl: z.string().optional().nullable(),
  internalNotes: z.string().optional().nullable(),
  sellByCommand: z.boolean().default(false),
  supplier: z.string().optional().nullable(),
});

export const collaboratorSchema = z.object({
  fullName: z.string().min(3),
  cpf: z.string().min(11),
  email: z.string().email(),
  phone: z.string().min(10),
  role: z.enum(["ADMINISTRADOR", "GERENTE", "OPERACIONAL"]),
  password: z.string().min(6).optional(),
  active: z.boolean().default(true),
});

export const cashOpenSchema = z.object({
  initialAmount: z.number().nonnegative(),
  observations: z.string().optional(),
});

export const cashMovementSchema = z.object({
  type: z.enum(["SANGRIA", "SUPRIMENTO"]),
  amount: z.number().positive(),
  reason: z.string().min(3),
});

export const saleSchema = z.object({
  items: z.array(
    z.object({
      productId: z.string(),
      quantity: z.number().int().positive(),
      unitPrice: z.number().positive(),
      note: z.string().optional(),
    }),
  ).min(1),
  discount: z.number().nonnegative().default(0),
  paymentMethod: z.enum(["DINHEIRO", "CREDITO", "DEBITO", "PIX", "COMANDA"]),
  installments: z.number().int().positive().optional(),
  customerCpf: z.string().optional(),
});

export const tutorSchema = z.object({
  fullName: z.string().min(3),
  cpf: z.string().min(11),
  birthDate: z.string(),
  email: z.string().email(),
  phone1: z.string().min(10),
  phone2: z.string().optional(),
  address: z.string().min(5),
});

export const childSchema = z.object({
  tutorId: z.string(),
  fullName: z.string().min(2),
  birthDate: z.string(),
  specialDiscount: z.boolean().default(false),
  consumeLimit: z.number().nonnegative().optional(),
});

export const partySchema = z.object({
  birthdayChildName: z.string().min(2),
  tutorName: z.string().min(3),
  tutorCpf: z.string().min(11),
  tutorEmail: z.string().email(),
  tutorPhone: z.string().min(10),
  tutorAddress: z.string().min(5),
  date: z.string(),
  timeSlot: z.string(),
  packageId: z.string(),
  holidayCustom: z.boolean().default(false),
  amountTotal: z.number().positive(),
  amountPaid: z.number().nonnegative().default(0),
  notes: z.string().optional(),
});

export const fiscalIssueSchema = z.object({
  type: z.enum(["NFE", "NFCE"]),
  customerName: z.string().min(2),
  customerDoc: z.string().min(11),
  totalValue: z.number().positive(),
});
