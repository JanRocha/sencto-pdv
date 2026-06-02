"use client";

import { useEffect, useState } from "react";

type ReportData = {
  totalSales: number;
  salesCount: number;
  byPayment: Record<string, number>;
  topProducts: { name: string; quantity: number; value: number }[];
};

export default function RelatoriosPage() {
  const [data, setData] = useState<ReportData | null>(null);

  useEffect(() => {
    fetch("/api/reports")
      .then((res) => res.json())
      .then((res) => setData(res.data));
  }, []);

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Relatórios e Indicadores</h1>
      <section className="grid gap-3 md:grid-cols-3">
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Total vendido</p><p className="text-2xl font-bold">R$ {Number(data?.totalSales ?? 0).toFixed(2)}</p></div>
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Quantidade de vendas</p><p className="text-2xl font-bold">{data?.salesCount ?? 0}</p></div>
        <div className="rounded-xl bg-white p-4 shadow-sm"><p className="text-sm">Pagamentos</p><p className="text-xs text-slate-600">{Object.entries(data?.byPayment ?? {}).map(([k, v]) => `${k}: R$ ${Number(v).toFixed(2)}`).join(" | ") || "Sem dados"}</p></div>
      </section>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-2 font-semibold">Top produtos vendidos</h2>
        <table className="w-full text-sm">
          <thead><tr className="border-b text-left"><th className="py-2">Produto</th><th>Qtd</th><th>Valor</th></tr></thead>
          <tbody>
            {(data?.topProducts ?? []).map((p) => (
              <tr key={p.name} className="border-b"><td className="py-2">{p.name}</td><td>{p.quantity}</td><td>R$ {Number(p.value).toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}
