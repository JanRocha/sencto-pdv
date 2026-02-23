"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";

type Party = {
  id: string;
  birthdayChildName: string;
  tutorName: string;
  date: string;
  timeSlot: string;
  status: string;
  amountTotal: number;
  cancelReason?: string | null;
  package: { id: string; name: string };
};

type Package = { id: string; name: string; weekdayPrice: number; weekendPrice: number; maxGuests: number };

export default function FestasPage() {
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());
  const [parties, setParties] = useState<Party[]>([]);
  const [stats, setStats] = useState({ totalParties: 0, estimatedRevenue: 0, topPackage: "-" });
  const [packages, setPackages] = useState<Package[]>([]);
  const [msg, setMsg] = useState("");
  const [form, setForm] = useState({
    birthdayChildName: "",
    tutorName: "",
    tutorCpf: "",
    tutorEmail: "",
    tutorPhone: "",
    tutorAddress: "",
    date: "",
    timeSlot: "14:00 às 16:30",
    packageId: "",
    holidayCustom: false,
    amountTotal: 0,
    amountPaid: 0,
    notes: "",
  });

  const timeSlots = useMemo(() => ["14:00 às 16:30", "19:00 às 21:30", "15:30 às 18:00"], []);

  async function load() {
    const partyRes = await fetch(`/api/parties?month=${month}&year=${year}`);
    const partyBody = await partyRes.json();
    setParties(partyBody.data?.parties ?? []);
    setStats(partyBody.data?.stats ?? { totalParties: 0, estimatedRevenue: 0, topPackage: "-" });
    setPackages(partyBody.data?.packages ?? []);
  }

  useEffect(() => {
    load();
  }, [month, year]);

  async function createParty(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/parties", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "CREATE", ...form }) });
    const body = await res.json();
    setMsg(body.ok ? "Festa agendada com sucesso" : body.message);
    if (body.ok) {
      setForm({ ...form, birthdayChildName: "", tutorName: "", tutorCpf: "", tutorEmail: "", tutorPhone: "", tutorAddress: "", date: "", amountTotal: 0, amountPaid: 0, packageId: "" });
      load();
    }
  }

  async function cancelParty(id: string) {
    const reason = prompt("Motivo do cancelamento:");
    if (!reason) return;
    const res = await fetch("/api/parties", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "CANCEL", id, reason }) });
    const body = await res.json();
    setMsg(body.ok ? "Festa cancelada" : body.message);
    if (body.ok) load();
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Agendamento de Festas</h1>

      <section className="grid gap-3 md:grid-cols-4">
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Festas no mês</p><p className="text-2xl font-bold">{stats.totalParties}</p></div>
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Receita estimada</p><p className="text-2xl font-bold">R$ {Number(stats.estimatedRevenue).toFixed(2)}</p></div>
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Pacote mais vendido</p><p className="text-2xl font-bold">{stats.topPackage}</p></div>
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Período</p><div className="mt-2 flex gap-2"><input className="w-20 rounded border px-2 py-1" value={month} onChange={(e) => setMonth(Number(e.target.value))} /><input className="w-24 rounded border px-2 py-1" value={year} onChange={(e) => setYear(Number(e.target.value))} /></div></div>
      </section>

      <form onSubmit={createParty} className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Nova Festa</h2>
        <div className="grid gap-2 md:grid-cols-3">
          <input className="rounded border px-3 py-2" placeholder="Nome aniversariante" value={form.birthdayChildName} onChange={(e) => setForm((f) => ({ ...f, birthdayChildName: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Nome completo tutor" value={form.tutorName} onChange={(e) => setForm((f) => ({ ...f, tutorName: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="CPF" value={form.tutorCpf} onChange={(e) => setForm((f) => ({ ...f, tutorCpf: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="E-mail" value={form.tutorEmail} onChange={(e) => setForm((f) => ({ ...f, tutorEmail: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Telefone" value={form.tutorPhone} onChange={(e) => setForm((f) => ({ ...f, tutorPhone: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Endereço" value={form.tutorAddress} onChange={(e) => setForm((f) => ({ ...f, tutorAddress: e.target.value }))} required />
          <input type="date" className="rounded border px-3 py-2" value={form.date} onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} required />
          <select className="rounded border px-3 py-2" value={form.timeSlot} onChange={(e) => setForm((f) => ({ ...f, timeSlot: e.target.value }))}>{timeSlots.map((t) => <option key={t}>{t}</option>)}</select>
          <select className="rounded border px-3 py-2" value={form.packageId} onChange={(e) => setForm((f) => ({ ...f, packageId: e.target.value }))} required>
            <option value="">Pacote</option>
            {packages.map((p) => <option key={p.id} value={p.id}>{p.name} (até {p.maxGuests} convidados)</option>)}
          </select>
          <input type="number" step="0.01" className="rounded border px-3 py-2" placeholder="Valor total" value={form.amountTotal} onChange={(e) => setForm((f) => ({ ...f, amountTotal: Number(e.target.value) }))} required />
          <input type="number" step="0.01" className="rounded border px-3 py-2" placeholder="Valor pago" value={form.amountPaid} onChange={(e) => setForm((f) => ({ ...f, amountPaid: Number(e.target.value) }))} />
          <button className="rounded bg-fuchsia-600 px-3 py-2 text-white">Salvar e Receber</button>
        </div>
      </form>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Pacotes disponíveis (editáveis)</h2>
        {packages.length === 0 && <p className="text-sm text-slate-500">Cadastre pacotes no seed inicial ou pelas APIs.</p>}
        <div className="grid gap-2 md:grid-cols-3">
          {packages.map((p) => (
            <div key={p.id} className="rounded border p-2">
              <p className="font-medium">{p.name}</p>
              <p className="text-sm">Valor referência: R$ {Number(p.weekdayPrice).toFixed(2)}</p>
              <button className="mt-1 rounded bg-slate-200 px-2 py-1 text-xs">Editar pacote</button>
            </div>
          ))}
        </div>
      </section>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Lista de festas agendadas</h2>
        <div className="overflow-auto">
          <table className="w-full text-sm">
            <thead><tr className="border-b text-left"><th className="py-2">Aniversariante</th><th>Responsável</th><th>Data</th><th>Horário</th><th>Pacote</th><th>Valor</th><th>Status</th><th>Ações</th></tr></thead>
            <tbody>
              {parties.map((p) => (
                <tr key={p.id} className="border-b">
                  <td className="py-2">{p.birthdayChildName}</td><td>{p.tutorName}</td><td>{new Date(p.date).toLocaleDateString()}</td><td>{p.timeSlot}</td><td>{p.package.name}</td><td>R$ {Number(p.amountTotal).toFixed(2)}</td><td>{p.status}{p.cancelReason ? ` (${p.cancelReason})` : ""}</td>
                  <td className="space-x-1">
                    <button className="rounded bg-slate-200 px-2 py-1 text-xs">Ver</button>
                    <button className="rounded bg-sky-100 px-2 py-1 text-xs">Editar</button>
                    <button className="rounded bg-rose-100 px-2 py-1 text-xs text-rose-700" onClick={() => cancelParty(p.id)}>Cancelar</button>
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
