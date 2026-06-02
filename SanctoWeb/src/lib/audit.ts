import { prisma } from "@/lib/prisma";

type AuditInput = {
  userId: string;
  action: string;
  targetType: string;
  targetId: string;
  details?: string;
  ipAddress?: string;
};

export async function logAudit(input: AuditInput) {
  await prisma.auditLog.create({
    data: input,
  });
}
