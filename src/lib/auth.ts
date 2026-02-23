import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { cookies } from "next/headers";

const TOKEN_NAME = "sancto_token";

export type SessionUser = {
  id: string;
  name: string;
  cpf: string;
  role: string; // Now accepts string from database
};

type JwtPayload = SessionUser & { exp: number };

export async function hashPassword(password: string) {
  return bcrypt.hash(password, 12);
}

export async function comparePassword(password: string, hash: string) {
  return bcrypt.compare(password, hash);
}

export function signToken(user: SessionUser) {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET não configurado");

  return jwt.sign(user, secret, { expiresIn: "12h" });
}

export function verifyToken(token: string): SessionUser | null {
  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) return null;
    const decoded = jwt.verify(token, secret) as JwtPayload;
    return {
      id: decoded.id,
      name: decoded.name,
      cpf: decoded.cpf,
      role: decoded.role,
    };
  } catch {
    return null;
  }
}

export async function setSessionCookie(token: string) {
  const cookieStore = await cookies();
  const appUrl = process.env.APP_URL ?? process.env.NEXT_PUBLIC_APP_URL;
  const cookieSecureEnv = process.env.COOKIE_SECURE;
  const usesHttps = cookieSecureEnv
    ? cookieSecureEnv === "true"
    : appUrl
      ? appUrl.startsWith("https://")
      : false;
  cookieStore.set(TOKEN_NAME, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: usesHttps,
    path: "/",
    maxAge: 60 * 60 * 12,
  });
}

export async function clearSessionCookie() {
  const cookieStore = await cookies();
  cookieStore.delete(TOKEN_NAME);
}

export async function getSessionUser() {
  const cookieStore = await cookies();
  const token = cookieStore.get(TOKEN_NAME)?.value;
  if (!token) return null;
  return verifyToken(token);
}

export async function requireRoles(roles: string[]) {
  const user = await getSessionUser();
  if (!user) return null;
  if (!roles.includes(user.role)) return null;
  return user;
}
