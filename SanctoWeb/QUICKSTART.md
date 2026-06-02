# SANCTO PDV - Guia Rápido de Início

## ⚡ Início Rápido (5 minutos)

### 1. Instalar
```bash
cd sancto-pdv
npm install
```

### 2. Inicializar Banco (primeira vez)
```bash
npx prisma generate
npx prisma db push --force-reset
npm run db:seed
```

### 3. Executar
```bash
npm run dev
```

### 4. Acessar
- **URL**: http://localhost:3000
- **CPF**: `00000000000`
- **Senha**: `admin123`

---

## 📱 Telas Principais

1. **Dashboard** - KPIs em tempo real
2. **PDV** - Vendas de ingressos e produtos
3. **Visitantes** - Cadastro de tutores/crianças
4. **Caixa** - Controle de caixa
5. **Produtos** - Inventário
6. **Festas** - Agendamento de eventos
7. **Fiscal** - Emissão de notas fiscais
8. **Relatórios** - Análise de vendas
9. **Colaboradores** - Gestão de usuários

---

## 🔐 Segurança Inicial

⚠️ **ANTES DE IR PARA PRODUÇÃO:**
1. Altere `JWT_SECRET` no `.env`
2. Mude a senha do admin (00000000000)
3. Configure HTTPS

---

## 📞 Suporte

Ver `DEPLOYMENT.md` para documentação completa.
