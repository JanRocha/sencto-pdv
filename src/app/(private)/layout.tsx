import { redirect } from "next/navigation";
import { getSessionUser } from "@/lib/auth";
import { LogoutButton } from "@/components/logout-button";
import { Sidebar } from "@/components/sidebar";

export default async function PrivateLayout({ children }: { children: React.ReactNode }) {
  const user = await getSessionUser();

  if (!user) {
    redirect("/");
  }

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900">
      <div className="lg:flex">
        <Sidebar />
        <main className="flex-1 p-4 lg:p-6">
          <header className="mb-4 flex items-center justify-between rounded-xl bg-white p-4 shadow-sm">
            <div>
              <p className="text-sm text-slate-500">Usuário logado</p>
              <p className="font-semibold">{user.name} • {user.role}</p>
            </div>
            <LogoutButton />
          </header>
          {children}
        </main>
      </div>
    </div>
  );
}
