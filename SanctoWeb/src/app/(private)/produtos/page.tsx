"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";

type Product = {
  id: string;
  name: string;
  barcode: string;
  salePrice: number;
  stock: number;
  minStock: number;
  active: boolean;
  category: { name: string };
};

const defaultPayload = {
  name: "",
  description: "",
  barcode: "",
  internalCode: "",
  categoryName: "Geral",
  salePrice: 0,
  promoPrice: null,
  costPrice: null,
  stock: 0,
  minStock: 0,
  unit: "UN",
  type: "Produto",
  ncm: "00000000",
  cfop: "5102",
  cstOrCsosn: "102",
  icmsRate: 18,
  pisRate: 1.65,
  cofinsRate: 7.6,
  fiscalOrigin: "0",
  active: true,
  imageUrl: "",
  internalNotes: "",
  sellByCommand: false,
  supplier: "",
};

export default function ProdutosPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [search, setSearch] = useState("");
  const [message, setMessage] = useState("");
  const [form, setForm] = useState(defaultPayload);

  const filtered = useMemo(
    () =>
      products.filter((p) =>
        [p.name, p.barcode, p.category.name].join(" ").toLowerCase().includes(search.toLowerCase()),
      ),
    [products, search],
  );

  async function loadProducts() {
    const res = await fetch("/api/products");
    const body = await res.json();
    setProducts(body.data ?? []);
  }

  useEffect(() => {
    loadProducts();
  }, []);

  async function createProduct(e: FormEvent) {
    e.preventDefault();
    const res = await fetch("/api/products", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    const body = await res.json();
    setMessage(body.ok ? "Produto salvo com sucesso" : body.message);
    if (body.ok) {
      setForm(defaultPayload);
      loadProducts();
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Produtos</h1>
      <section className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="mb-3 text-lg font-semibold">Cadastro de Produto</h2>
        <form onSubmit={createProduct} className="grid gap-2 md:grid-cols-3">
          <input className="rounded border px-3 py-2" placeholder="Nome" value={form.name} onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Código de barras" value={form.barcode} onChange={(e) => setForm((f) => ({ ...f, barcode: e.target.value }))} required />
          <input className="rounded border px-3 py-2" placeholder="Categoria" value={form.categoryName} onChange={(e) => setForm((f) => ({ ...f, categoryName: e.target.value }))} required />
          <input className="rounded border px-3 py-2" type="number" step="0.01" placeholder="Preço venda" value={form.salePrice} onChange={(e) => setForm((f) => ({ ...f, salePrice: Number(e.target.value) }))} required />
          <input className="rounded border px-3 py-2" type="number" placeholder="Estoque atual" value={form.stock} onChange={(e) => setForm((f) => ({ ...f, stock: Number(e.target.value) }))} required />
          <input className="rounded border px-3 py-2" type="number" placeholder="Estoque mínimo" value={form.minStock} onChange={(e) => setForm((f) => ({ ...f, minStock: Number(e.target.value) }))} required />
          <button className="rounded bg-sky-600 px-4 py-2 font-semibold text-white md:col-span-3">Salvar Produto</button>
        </form>
        {message && <p className="mt-2 text-sm text-slate-600">{message}</p>}
      </section>

      <section className="rounded-xl bg-white p-4 shadow-sm">
        <div className="mb-3 flex items-center justify-between gap-2">
          <h2 className="text-lg font-semibold">Lista de Produtos</h2>
          <input className="rounded border px-3 py-2" placeholder="Buscar" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <div className="overflow-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left">
                <th className="py-2">Produto</th><th>Categoria</th><th>Preço</th><th>Estoque</th><th>Status</th><th>Alerta</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => (
                <tr key={p.id} className="border-b">
                  <td className="py-2">{p.name}</td>
                  <td>{p.category.name}</td>
                  <td>R$ {Number(p.salePrice).toFixed(2)}</td>
                  <td>{p.stock}</td>
                  <td>{p.active ? "Ativo" : "Inativo"}</td>
                  <td>{p.stock <= p.minStock ? "⚠️ Baixo" : "OK"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
