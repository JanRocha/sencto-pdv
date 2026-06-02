"use client";

import { useRouter } from "next/navigation";

export function LogoutButton() {
  const router = useRouter();

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/");
    router.refresh();
  }

  return (
    <button
      onClick={handleLogout}
      className="rounded-lg bg-rose-500 px-3 py-2 text-sm font-semibold text-white hover:bg-rose-600"
    >
      Sair
    </button>
  );
}
