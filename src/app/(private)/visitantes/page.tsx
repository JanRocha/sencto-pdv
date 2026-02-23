"use client";

import { FormEvent, useEffect, useState } from "react";

type Tutor = { id: string; fullName: string; cpf: string; children: { id: string; fullName: string }[] };
type Product = { id: string; name: string; type: string };

export default function VisitantesPage() {
  const [tutors, setTutors] = useState<Tutor[]>([]);
  const [tickets, setTickets] = useState<Product[]>([]);
  const [msg, setMsg] = useState("");
  const [tutorForm, setTutorForm] = useState({ fullName: "", cpf: "", birthDate: "", email: "", phone1: "", phone2: "", address: "" });
  const [childForm, setChildForm] = useState({ tutorId: "", fullName: "", birthDate: "", specialDiscount: false, consumeLimit: 0 });
  const [visitForm, setVisitForm] = useState({ tutorId: "", childId: "", ticketProductId: "" });

  async function load() {
    const [tutorsRes, productsRes] = await Promise.all([fetch("/api/visitors"), fetch("/api/products")]);
    const tutorsBody = await tutorsRes.json();
    const productsBody = await productsRes.json();
    setTutors(tutorsBody.data ?? []);
    setTickets((productsBody.data ?? []).filter((p: Product) => p.type.toLowerCase().includes("ingresso")));
  }

  useEffect(() => {
    load();
  }, []);

  async function createTutor(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/visitors", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "CREATE_TUTOR", ...tutorForm }) });
    const body = await res.json();
    setMsg(body.ok ? "Tutor salvo" : body.message);
    if (body.ok) {
      setTutorForm({ fullName: "", cpf: "", birthDate: "", email: "", phone1: "", phone2: "", address: "" });
      load();
    }
  }

  async function createChild(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/visitors", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "CREATE_CHILD", ...childForm }) });
    const body = await res.json();
    setMsg(body.ok ? "Criança vinculada" : body.message);
    if (body.ok) load();
  }

  async function startVisit(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/visitors", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "START_VISIT", ...visitForm }) });
    const body = await res.json();
    setMsg(body.ok ? "Visita iniciada" : body.message);
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Visitantes</h1>
      <div className="grid gap-4 xl:grid-cols-3">
        <form onSubmit={createTutor} className="rounded-xl bg-white p-4 shadow-sm">
          <h2 className="mb-2 font-semibold">Novo Tutor</h2>
          <div className="space-y-2">
            <input className="w-full rounded border px-3 py-2" placeholder="Nome" value={tutorForm.fullName} onChange={(e) => setTutorForm((f) => ({ ...f, fullName: e.target.value }))} required />
            <input className="w-full rounded border px-3 py-2" placeholder="CPF" value={tutorForm.cpf} onChange={(e) => setTutorForm((f) => ({ ...f, cpf: e.target.value }))} required />
            <input type="date" className="w-full rounded border px-3 py-2" value={tutorForm.birthDate} onChange={(e) => setTutorForm((f) => ({ ...f, birthDate: e.target.value }))} required />
            <input className="w-full rounded border px-3 py-2" placeholder="E-mail" value={tutorForm.email} onChange={(e) => setTutorForm((f) => ({ ...f, email: e.target.value }))} required />
            <input className="w-full rounded border px-3 py-2" placeholder="Telefone" value={tutorForm.phone1} onChange={(e) => setTutorForm((f) => ({ ...f, phone1: e.target.value }))} required />
            <input className="w-full rounded border px-3 py-2" placeholder="Endereço" value={tutorForm.address} onChange={(e) => setTutorForm((f) => ({ ...f, address: e.target.value }))} required />
            <button className="w-full rounded bg-sky-600 py-2 text-white">Salvar Tutor</button>
          </div>
        </form>

        <form onSubmit={createChild} className="rounded-xl bg-white p-4 shadow-sm">
          <h2 className="mb-2 font-semibold">Nova Criança</h2>
          <div className="space-y-2">
            <select className="w-full rounded border px-3 py-2" value={childForm.tutorId} onChange={(e) => setChildForm((f) => ({ ...f, tutorId: e.target.value }))} required>
              <option value="">Selecione tutor</option>
              {tutors.map((t) => <option key={t.id} value={t.id}>{t.fullName}</option>)}
            </select>
            <input className="w-full rounded border px-3 py-2" placeholder="Nome da criança" value={childForm.fullName} onChange={(e) => setChildForm((f) => ({ ...f, fullName: e.target.value }))} required />
            <input type="date" className="w-full rounded border px-3 py-2" value={childForm.birthDate} onChange={(e) => setChildForm((f) => ({ ...f, birthDate: e.target.value }))} required />
            <input type="number" step="0.01" className="w-full rounded border px-3 py-2" placeholder="Limite consumo" value={childForm.consumeLimit} onChange={(e) => setChildForm((f) => ({ ...f, consumeLimit: Number(e.target.value) }))} />
            <button className="w-full rounded bg-emerald-600 py-2 text-white">Vincular Criança</button>
          </div>
        </form>

        <form onSubmit={startVisit} className="rounded-xl bg-white p-4 shadow-sm">
          <h2 className="mb-2 font-semibold">Iniciar Visita</h2>
          <div className="space-y-2">
            <select className="w-full rounded border px-3 py-2" value={visitForm.tutorId} onChange={(e) => setVisitForm((f) => ({ ...f, tutorId: e.target.value, childId: "" }))} required>
              <option value="">Tutor</option>
              {tutors.map((t) => <option key={t.id} value={t.id}>{t.fullName}</option>)}
            </select>
            <select className="w-full rounded border px-3 py-2" value={visitForm.childId} onChange={(e) => setVisitForm((f) => ({ ...f, childId: e.target.value }))} required>
              <option value="">Criança</option>
              {tutors.find((t) => t.id === visitForm.tutorId)?.children.map((c) => <option key={c.id} value={c.id}>{c.fullName}</option>)}
            </select>
            <select className="w-full rounded border px-3 py-2" value={visitForm.ticketProductId} onChange={(e) => setVisitForm((f) => ({ ...f, ticketProductId: e.target.value }))} required>
              <option value="">Ingresso</option>
              {tickets.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
            <button className="w-full rounded bg-fuchsia-600 py-2 text-white">Iniciar nova visita</button>
          </div>
        </form>
      </div>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Tutores cadastrados</h2>
        <div className="grid gap-2 md:grid-cols-2">
          {tutors.map((t) => (
            <div key={t.id} className="rounded border p-2">
              <p className="font-medium">{t.fullName}</p>
              <p className="text-sm text-slate-500">CPF {t.cpf} • Crianças: {t.children.length}</p>
            </div>
          ))}
        </div>
      </section>

      {msg && <p className="rounded bg-slate-200 p-2 text-sm">{msg}</p>}
    </div>
  );
}
