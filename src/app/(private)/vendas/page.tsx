"use client";

import { useEffect, useMemo, useState } from "react";

type Product = {
  id: string;
  name: string;
  salePrice: number;
  promoPrice?: number | null;
  stock: number;
  active: boolean;
  category: { name: string };
};

type CartItem = {
  productId: string;
  name: string;
  quantity: number;
  unitPrice: number;
};

export default function VendasPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("Todas");
  const [cart, setCart] = useState<CartItem[]>([]);
  const [paymentMethod, setPaymentMethod] = useState("DINHEIRO");
  const [installments, setInstallments] = useState(1);
  const [discount, setDiscount] = useState(0);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("/api/products")
      .then((r) => r.json())
      .then((r) => setProducts((r.data ?? []).filter((p: Product) => p.active && p.stock > 0)));
  }, []);

  const categories = useMemo(() => ["Todas", ...new Set(products.map((p) => p.category.name))], [products]);

  const visibleProducts = useMemo(
    () => products.filter((p) => selectedCategory === "Todas" || p.category.name === selectedCategory),
    [products, selectedCategory],
  );

  function addProduct(product: Product) {
    setCart((prev) => {
      const existing = prev.find((i) => i.productId === product.id);
      if (existing) {
        return prev.map((item) => (item.productId === product.id ? { ...item, quantity: item.quantity + 1 } : item));
      }
      return [...prev, { productId: product.id, name: product.name, quantity: 1, unitPrice: Number(product.promoPrice ?? product.salePrice) }];
    });
  }

  const subtotal = cart.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  const total = subtotal - discount;

  async function finalizeSale() {
    const payload = {
      items: cart.map((item) => ({ productId: item.productId, quantity: item.quantity, unitPrice: item.unitPrice })),
      paymentMethod,
      installments: paymentMethod === "CREDITO" ? installments : undefined,
      discount,
    };

    const res = await fetch("/api/sales", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    setMsg(body.ok ? "Venda finalizada com sucesso" : body.message);
    if (body.ok) setCart([]);
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Vendas PDV</h1>
      <div className="grid gap-4 xl:grid-cols-[220px_1fr_350px]">
        <aside className="rounded-xl bg-white p-3 shadow-sm">
          <h2 className="mb-2 font-semibold">Categorias</h2>
          <div className="space-y-2">
            {categories.map((cat) => (
              <button key={cat} className={`w-full rounded px-3 py-2 text-left ${selectedCategory === cat ? "bg-sky-600 text-white" : "bg-slate-100"}`} onClick={() => setSelectedCategory(cat)}>
                {cat}
              </button>
            ))}
          </div>
        </aside>

        <section className="rounded-xl bg-white p-3 shadow-sm">
          <h2 className="mb-2 font-semibold">Produtos</h2>
          <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {visibleProducts.map((p) => (
              <button key={p.id} onClick={() => addProduct(p)} className="rounded-lg border p-3 text-left hover:bg-sky-50">
                <p className="font-medium">{p.name}</p>
                <p className="text-sm text-slate-500">{p.category.name}</p>
                <p className="mt-2 text-sky-700">R$ {Number(p.promoPrice ?? p.salePrice).toFixed(2)}</p>
              </button>
            ))}
          </div>
        </section>

        <section className="rounded-xl bg-white p-3 shadow-sm">
          <h2 className="mb-2 font-semibold">Lista de Compras</h2>
          <div className="space-y-2">
            {cart.map((item) => (
              <div key={item.productId} className="rounded border p-2">
                <p className="font-medium">{item.name}</p>
                <div className="mt-1 flex items-center gap-2">
                  <button className="rounded bg-slate-200 px-2" onClick={() => setCart((c) => c.map((i) => (i.productId === item.productId ? { ...i, quantity: Math.max(1, i.quantity - 1) } : i)))}>-</button>
                  <span>{item.quantity}</span>
                  <button className="rounded bg-slate-200 px-2" onClick={() => setCart((c) => c.map((i) => (i.productId === item.productId ? { ...i, quantity: i.quantity + 1 } : i)))}>+</button>
                  <button className="ml-auto rounded bg-rose-100 px-2 text-rose-700" onClick={() => setCart((c) => c.filter((i) => i.productId !== item.productId))}>🗑️</button>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-3 space-y-2 border-t pt-3">
            <p>Subtotal: <strong>R$ {subtotal.toFixed(2)}</strong></p>
            <input type="number" step="0.01" className="w-full rounded border px-3 py-2" value={discount} onChange={(e) => setDiscount(Number(e.target.value))} placeholder="Desconto" />
            <select className="w-full rounded border px-3 py-2" value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)}>
              <option value="DINHEIRO">Dinheiro</option>
              <option value="CREDITO">Cartão crédito</option>
              <option value="DEBITO">Cartão débito</option>
              <option value="PIX">PIX</option>
              <option value="COMANDA">Comanda</option>
            </select>
            {paymentMethod === "CREDITO" && (
              <input type="number" min={1} max={12} className="w-full rounded border px-3 py-2" value={installments} onChange={(e) => setInstallments(Number(e.target.value))} placeholder="Parcelas" />
            )}
            <p>Total: <strong>R$ {total.toFixed(2)}</strong></p>
            <button className="w-full rounded bg-emerald-600 py-2 font-semibold text-white" onClick={finalizeSale} disabled={cart.length === 0}>Finalizar Venda</button>
          </div>
        </section>
      </div>
      {msg && <p className="rounded bg-slate-200 p-2 text-sm">{msg}</p>}
    </div>
  );
}
