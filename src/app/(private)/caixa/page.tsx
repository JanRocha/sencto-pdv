"use client";

import { FormEvent, useEffect, useState } from "react";

type CashState = {
  id: string;
  initialAmount: number;
  status: string;
  openedAt: string;
  movements: { id: string; type: string; amount: number; reason: string; createdAt: string }[];
} | null;

export default function CaixaPage() {
  const [cash, setCash] = useState<CashState>(null);
  const [initialAmount, setInitialAmount] = useState(200);
  const [countedAmount, setCountedAmount] = useState(0);
  const [moveType, setMoveType] = useState("SANGRIA");
  const [moveAmount, setMoveAmount] = useState(0);
  const [reason, setReason] = useState("");
  const [msg, setMsg] = useState("");

  async function loadCash() {
    const res = await fetch("/api/cash");
    const body = await res.json();
    setCash(body.data ?? null);
  }

  useEffect(() => {
    loadCash();
  }, []);

  async function openCash(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/cash", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action: "OPEN", initialAmount }) });
    const body = await res.json();
    setMsg(body.ok ? "Caixa aberto com sucesso" : body.message);
    loadCash();
  }

  async function registerMovement(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/cash", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "MOVE", type: moveType, amount: moveAmount, reason }),
    });
    const body = await res.json();
    setMsg(body.ok ? "Movimentação registrada" : body.message);
    if (body.ok) {
      setMoveAmount(0);
      setReason("");
      loadCash();
    }
  }

  async function closeCash() {
    const res = await fetch("/api/cash", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "CLOSE", countedAmount }),
    });
    const body = await res.json();
    setMsg(body.ok ? `Caixa fechado. Diferença: R$ ${Number(body.data.difference).toFixed(2)}` : body.message);
    loadCash();
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Controle de Caixa</h1>
      <div className="rounded-xl bg-white p-4 shadow-sm">
        <p className="text-sm text-slate-500">Status atual</p>
        <p className="text-lg font-semibold">{cash ? `Aberto desde ${new Date(cash.openedAt).toLocaleString()}` : "Fechado"}</p>
      </div>

      {!cash && (
        <form onSubmit={openCash} className="rounded-xl bg-white p-4 shadow-sm">
          <h2 className="mb-2 font-semibold">Abertura de Caixa</h2>
          <input type="number" step="0.01" className="rounded border px-3 py-2" value={initialAmount} onChange={(e) => setInitialAmount(Number(e.target.value))} />
          <button className="ml-2 rounded bg-sky-600 px-3 py-2 text-white">Abrir Caixa</button>
        </form>
      )}

      {cash && (
        <>
          <form onSubmit={registerMovement} className="rounded-xl bg-white p-4 shadow-sm">
            <h2 className="mb-2 font-semibold">Movimentações</h2>
            <div className="grid gap-2 md:grid-cols-4">
              <select className="rounded border px-3 py-2" value={moveType} onChange={(e) => setMoveType(e.target.value)}>
                <option value="SANGRIA">Sangria</option>
                <option value="SUPRIMENTO">Suprimento</option>
              </select>
              <input type="number" step="0.01" className="rounded border px-3 py-2" value={moveAmount} onChange={(e) => setMoveAmount(Number(e.target.value))} placeholder="Valor" />
              <input className="rounded border px-3 py-2" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Motivo" />
              <button className="rounded bg-emerald-600 px-3 py-2 text-white">Registrar</button>
            </div>
          </form>

          <div className="rounded-xl bg-white p-4 shadow-sm">
            <h2 className="mb-2 font-semibold">Fechamento</h2>
            <input type="number" step="0.01" className="rounded border px-3 py-2" value={countedAmount} onChange={(e) => setCountedAmount(Number(e.target.value))} placeholder="Valor contado" />
            <button className="ml-2 rounded bg-rose-600 px-3 py-2 text-white" onClick={closeCash}>Fechar Caixa</button>
          </div>
        </>
      )}

      {msg && <p className="rounded bg-slate-200 p-2 text-sm">{msg}</p>}
    </div>
  );
}
