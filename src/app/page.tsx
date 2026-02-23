"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [cpf, setCpf] = useState("00000000000");
  const [password, setPassword] = useState("admin123");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ cpf, password }),
    });

    const data = await response.json();
    setLoading(false);

    if (!response.ok || !data.ok) {
      setMessage(data.message ?? "Falha no login");
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-br from-sky-100 to-fuchsia-100 p-4">
      <section className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
        <h1 className="text-2xl font-bold text-sky-700">SANCTO PDV</h1>
        <p className="mt-1 text-sm text-slate-500">Login por usuário ativo com perfil operacional, gerente ou administrador.</p>

        <form onSubmit={handleSubmit} className="mt-5 space-y-3">
          <label className="block text-sm font-medium">Usuário (CPF)</label>
          <input
            value={cpf}
            onChange={(e) => setCpf(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2"
            placeholder="CPF"
            required
          />

          <label className="block text-sm font-medium">Senha</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2"
            placeholder="Senha"
            required
          />

          <button
            disabled={loading}
            className="w-full rounded-lg bg-sky-600 py-2 font-semibold text-white hover:bg-sky-700 disabled:opacity-60"
          >
            {loading ? "Entrando..." : "Entrar"}
          </button>
        </form>

        {message && <p className="mt-3 rounded bg-rose-100 p-2 text-sm text-rose-700">{message}</p>}
        <p className="mt-4 text-xs text-slate-500">Acesso inicial: CPF 00000000000 / senha admin123.</p>
      </section>
    </main>
  );
}
