"use client";

import { FormEvent, useEffect, useState } from "react";

type Invoice = { id: string; number: number; type: string; customerName: string; totalValue: number; status: string; issuedAt: string };

type FiscalData = {
  config?: { environment: string; series: number; nextNfeNumber: number; nextNfceNumber: number };
  invoices: Invoice[];
};

export default function FiscalPage() {
  const [data, setData] = useState<FiscalData>({ invoices: [] });
  const [msg, setMsg] = useState("");
  const [issue, setIssue] = useState({ type: "NFCE", customerName: "Consumidor Final", customerDoc: "00000000000", totalValue: 0 });

  async function load() {
    const res = await fetch("/api/fiscal");
    const body = await res.json();
    setData(body.data ?? { invoices: [] });
  }

  useEffect(() => {
    load();
  }, []);

  async function issueInvoice(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/fiscal", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "ISSUE", ...issue }) });
    const body = await res.json();
    setMsg(body.ok ? "Nota emitida com sucesso" : body.message);
    if (body.ok) load();
  }

  async function cancelInvoice(invoiceId: string) {
    const reason = prompt("Justificativa do cancelamento:");
    if (!reason) return;
    const res = await fetch("/api/fiscal", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "CANCEL", invoiceId, justification: reason }) });
    const body = await res.json();
    setMsg(body.ok ? "Nota cancelada" : body.message);
    if (body.ok) load();
  }

  async function testSefaz() {
    const res = await fetch("/api/fiscal", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "TEST_SEFAZ" }) });
    const body = await res.json();
    setMsg(body.ok ? body.data.message : body.message);
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Fiscal</h1>
      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="font-semibold">Configuração atual</h2>
        <p className="text-sm text-slate-600">Ambiente: {data.config?.environment ?? "-"} • Série: {data.config?.series ?? "-"}</p>
        <p className="text-sm text-slate-600">Próxima NFe: {data.config?.nextNfeNumber ?? "-"} • Próxima NFCe: {data.config?.nextNfceNumber ?? "-"}</p>
        <button onClick={testSefaz} className="mt-2 rounded bg-indigo-600 px-3 py-2 text-sm text-white">Testar conexão com SEFAZ</button>
      </section>

      <form onSubmit={issueInvoice} className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Emitir NF-e / NFC-e</h2>
        <div className="grid gap-2 md:grid-cols-4">
          <select className="rounded border px-3 py-2" value={issue.type} onChange={(e) => setIssue((f) => ({ ...f, type: e.target.value }))}>
            <option value="NFCE">NFC-e</option>
            <option value="NFE">NF-e</option>
          </select>
          <input className="rounded border px-3 py-2" placeholder="Cliente" value={issue.customerName} onChange={(e) => setIssue((f) => ({ ...f, customerName: e.target.value }))} />
          <input className="rounded border px-3 py-2" placeholder="CPF/CNPJ" value={issue.customerDoc} onChange={(e) => setIssue((f) => ({ ...f, customerDoc: e.target.value }))} />
          <input type="number" step="0.01" className="rounded border px-3 py-2" placeholder="Valor" value={issue.totalValue} onChange={(e) => setIssue((f) => ({ ...f, totalValue: Number(e.target.value) }))} />
        </div>
        <button className="mt-2 rounded bg-emerald-600 px-4 py-2 text-white">Emitir</button>
      </form>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Notas emitidas</h2>
        <div className="overflow-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left"><th className="py-2">Número</th><th>Tipo</th><th>Cliente</th><th>Valor</th><th>Status</th><th>Ações</th></tr>
            </thead>
            <tbody>
              {data.invoices.map((n) => (
                <tr key={n.id} className="border-b">
                  <td className="py-2">{n.number}</td>
                  <td>{n.type}</td>
                  <td>{n.customerName}</td>
                  <td>R$ {Number(n.totalValue).toFixed(2)}</td>
                  <td>{n.status}</td>
                  <td><button className="rounded bg-rose-100 px-2 py-1 text-rose-700" onClick={() => cancelInvoice(n.id)}>Cancelar</button></td>
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
