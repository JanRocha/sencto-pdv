import Link from "next/link";

const LINKS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/vendas", label: "Vendas PDV" },
  { href: "/visitantes", label: "Visitantes" },
  { href: "/produtos", label: "Produtos" },
  { href: "/caixa", label: "Caixa" },
  { href: "/fiscal", label: "Fiscal" },
  { href: "/festas", label: "Festas" },
  { href: "/relatorios", label: "Relatórios" },
  { href: "/colaboradores", label: "Colaboradores" },
];

export function Sidebar() {
  return (
    <aside className="w-full border-b border-slate-200 bg-sky-50 p-3 lg:min-h-screen lg:w-64 lg:border-b-0 lg:border-r">
      <h2 className="mb-3 text-lg font-bold text-sky-800">SANCTO PDV</h2>
      <nav className="grid grid-cols-2 gap-2 lg:grid-cols-1">
        {LINKS.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="rounded-lg bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm hover:bg-sky-100"
          >
            {item.label}
          </Link>
        ))}
      </nav>
    </aside>
  );
}
