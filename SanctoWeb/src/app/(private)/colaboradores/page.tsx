"use client";

import { FormEvent, useEffect, useState } from "react";

type Collaborator = {
  id: string;
  fullName: string;
  cpf: string;
  email: string;
  phone: string;
  role: "ADMINISTRADOR" | "GERENTE" | "OPERACIONAL";
  active: boolean;
  lastAccessAt?: string;
};

export default function ColaboradoresPage() {
  const [users, setUsers] = useState<Collaborator[]>([]);
  const [msg, setMsg] = useState("");
  const [form, setForm] = useState({ fullName: "", cpf: "", email: "", phone: "", role: "OPERACIONAL", password: "", active: true });

  async function load() {
    const res = await fetch("/api/collaborators");
    const body = await res.json();
    setUsers(body.data ?? []);
  }

  useEffect(() => {
    load();
  }, []);

  async function saveUser(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/collaborators", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });

    const body = await res.json();
    setMsg(body.ok ? "Colaborador criado" : body.message);

    if (body.ok) {
      setForm({ fullName: "", cpf: "", email: "", phone: "", role: "OPERACIONAL", password: "", active: true });
      load();
    }
  }

  async function removeUser(id: string) {
    const okConfirm = confirm("Tem certeza que deseja excluir permanentemente este colaborador?");
    if (!okConfirm) return;

    const res = await fetch(`/api/collaborators?id=${id}`, { method: "DELETE" });
    const body = await res.json();
    setMsg(body.ok ? "Colaborador excluído" : body.message);
    if (body.ok) load();
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Colaboradores</h1>

      <form onSubmit={saveUser} className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Cadastro de Colaborador</h2>
        <div className="grid gap-2 md:grid-cols-3">
          <input className="rounded border px-3 py-2" placeholder="Nome completo" value={form.fullName} onChange={(e) => setForm((f) => ({ ...f, fullName: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="CPF" value={form.cpf} onChange={(e) => setForm((f) => ({ ...f, cpf: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="E-mail" value={form.email} onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Telefone" value={form.phone} onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))} required />
          <select className="rounded border px-3 py-2" value={form.role} onChange={(e) => setForm((f) => ({ ...f, role: e.target.value as Collaborator["role"] }))}>
            <option value="ADMINISTRADOR">Administrador</option>
            <option value="GERENTE">Gerente</option>
            <option value="OPERACIONAL">Operacional</option>
          </select>
          <input type="password" className="rounded border px-3 py-2" placeholder="Senha" value={form.password} onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))} required />
          <button className="rounded bg-sky-600 px-3 py-2 text-white md:col-span-3">Salvar</button>
        </div>
      </form>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Lista de Colaboradores</h2>
        <div className="overflow-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left">
                <th className="py-2">Nome</th><th>CPF</th><th>E-mail</th><th>Perfil</th><th>Status</th><th>Último acesso</th><th>Ações</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} className="border-b">
                  <td className="py-2">{u.fullName}</td>
                  <td>{u.cpf}</td>
                  <td>{u.email}</td>
                  <td>{u.role}</td>
                  <td>{u.active ? "Ativo" : "Inativo"}</td>
                  <td>{u.lastAccessAt ? new Date(u.lastAccessAt).toLocaleString() : "-"}</td>
                  <td>
                    <button className="rounded bg-rose-100 px-2 py-1 text-rose-700" onClick={() => removeUser(u.id)}>Excluir</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {msg && <p className="rounded bg-slate-200 p-2 text-sm">{msg}</p>}
    </div>
  );
}
