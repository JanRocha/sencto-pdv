export const ROLES = {
  ADMINISTRADOR: "ADMINISTRADOR",
  GERENTE: "GERENTE",
  OPERACIONAL: "OPERACIONAL",
} as const;

export type AppRole = (typeof ROLES)[keyof typeof ROLES];
