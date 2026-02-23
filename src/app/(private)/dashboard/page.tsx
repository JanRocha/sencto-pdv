"use client";

import { useEffect, useState } from "react";

type DashboardData = {
  totalVendasHoje: number;
  visitasAbertas: number;
  estoqueBaixo: number;
  notasHoje: number;
};

export default function DashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then((res) => res.json())
      .then((res) => setData(res.data));
  }, []);

  const cards = [
    { title: "Vendas hoje", value: `R$ ${data?.totalVendasHoje?.toFixed(2) ?? "0,00"}` },
    { title: "Visitas abertas", value: data?.visitasAbertas ?? 0 },
    { title: "Estoque baixo", value: data?.estoqueBaixo ?? 0 },
    { title: "Notas fiscais hoje", value: data?.notasHoje ?? 0 },
  ];

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Dashboard</h1>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => (
          <div key={card.title} className="rounded-xl bg-white p-4 shadow-sm">
            <p className="text-sm text-slate-500">{card.title}</p>
            <p className="mt-2 text-2xl font-bold text-sky-700">{card.value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
