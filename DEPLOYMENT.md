# SANCTO PDV - Guia de Deployment

## Descrição Geral
Sistema de Ponto de Venda (PDV) para parques de diversão infantis com gestão de ingressos, visitantes, festas, inventário de produtos e controle fiscal.

**Stack Tecnológico:**
- **Framework**: Next.js 16.1.6 (App Router, TypeScript)
- **Banco de Dados**: SQLite (arquivo `dev.db`)
- **ORM**: Prisma v5.22.0
- **Autenticação**: JWT + bcryptjs
- **Validação**: Zod
- **Styling**: Tailwind CSS v4

---

## 1. REQUISITOS DO SERVIDOR

### Ambiente Local (Desenvolvimento)
- **Node.js**: v18+ (recomendado v20 LTS)
- **NPM**: v9+
- **Windows**: Qualquer versão moderna
- **Espaço em disco**: 500MB (incluindo node_modules)
- **Memória RAM**: Mínimo 2GB (recomendado 4GB+)

### Ambiente Produção
- **Servidor**: Windows Server 2019+ ou Linux (Ubuntu 20.04+)
- **Node.js**: v20 LTS
- **Banco de dados**: SQLite (arquivo único) ou PostgreSQL (opcional, recomendado)
- **Certificado SSL/TLS**: Recomendado para HTTPS
- **Firewall**: Porta 3000 (padrão) ou proxy reverso (nginx/Apache)

---

## 2. INSTALAÇÃO

### Passo 1: Extrair Arquivos
```bash
# Descompacte o arquivo ZIP
unzip sancto-pdv-release.zip
cd sancto-pdv
```

### Passo 2: Instalar Dependências
```bash
npm install
```

### Passo 3: Configurar Variáveis de Ambiente

**Editar `.env`:**
```env
# Banco de Dados (SQLite padrão)
DATABASE_URL="file:./dev.db"

# JWT Secret - DEVE SER ALTERADO EM PRODUÇÃO
JWT_SECRET="seu-codigo-aleatorio-super-secreto-aqui"

# Ambiente
APP_ENV="development"  # ou "production"

# Configurações Opcionais
SEFAZ_AMBIENTE="homologacao"  # ou "producao"
FISCAL_PROVIDER="mock"
WHATSAPP_PROVIDER="mock"
ERP_PROVIDER="mock"
```

**Observação:** Com `FISCAL_PROVIDER="real"`, o sistema usa o stub de integração real e retorna indisponibilidade controlada para emissão/cancelamento até a homologação final do conector SEFAZ.

### Passo 4: Inicializar Banco de Dados (Primeira Vez Apenas)
```bash
npx prisma generate
npx prisma db push --force-reset
npm run db:seed
```

---

## 3. EXECUTAR APLICAÇÃO

### Desenvolvimento
```bash
npm run dev
# Acessa em: http://localhost:3000
```

### Produção (Build)
```bash
npm run build
npm run start
```

---

## 4. CREDENCIAIS DE LOGIN PADRÃO

**Usuário Admin (seed inicial):**
- **CPF**: `00000000000`
- **Senha**: `admin123`

⚠️ **IMPORTANTE**: Altere a senha do administrador imediatamente após primeiro login!

---

## 5. ESTRUTURA DE DIRETÓRIOS

```
sancto-pdv/
├── src/
│   ├── app/
│   │   ├── (private)/          # Rotas protegidas (require autenticação)
│   │   │   ├── dashboard/
│   │   │   ├── produtos/
│   │   │   ├── caixa/
│   │   │   ├── vendas/
│   │   │   ├── visitantes/
│   │   │   ├── fiscal/
│   │   │   ├── festas/
│   │   │   ├── relatorios/
│   │   │   └── colaboradores/
│   │   └── api/                # Endpoints REST
│   │       ├── auth/           # Autenticação (login/logout/me)
│   │       ├── products/       # CRUD de Produtos
│   │       ├── collaborators/  # CRUD de Colaboradores
│   │       ├── cash/           # Controle de Caixa
│   │       ├── sales/          # Vendas e Checkout
│   │       ├── visitors/       # Visitantes e Ingressos
│   │       ├── parties/        # Festas e Eventos
│   │       ├── fiscal/         # NF-e/NFC-e
│   │       ├── dashboard/      # Dashboard KPIs
│   │       └── reports/        # Relatórios
│   ├── lib/                    # Utilitários
│   │   ├── prisma.ts           # Cliente Prisma
│   │   ├── auth.ts             # JWT e Sessão
│   │   ├── guard.ts            # Controle de Acesso
│   │   ├── validation.ts       # Schemas Zod
│   │   ├── audit.ts            # Logs de Auditoria
│   │   ├── http.ts             # Respostas HTTP
│   │   └── roles.ts            # Roles e Permissões
│   ├── components/             # Componentes React
│   └── types/                  # Declarações TypeScript
├── prisma/
│   ├── schema.prisma           # Schema do banco
│   └── seed.mjs                # Script de seed inicial
├── .next/                      # Build output (gitignore)
├── node_modules/               # Dependências (gitignore)
├── .env                        # Variáveis de ambiente
├── next.config.ts              # Config Next.js
├── package.json                # Dependências do projeto
└── README.md                   # Este arquivo
```

---

## 6. FUNCIONALIDADES PRINCIPAIS

### 📊 Dashboard
- Vendas do dia (em tempo real)
- Visitantes com ingresso ativo
- Produtos com estoque baixo
- Notas fiscais emitidas

### 💰 PDV (Ponto de Venda)
- Interface intuitiva com categorias e produtos
- Carrinho de compras com desconto
- Múltiplos métodos de pagamento (dinheiro, crédito, débito, PIX, comanda)
- Parcelamento em crédito (até 12x)
- Integração com caixa

### 👥 Visitantes
- Cadastro de tutores e crianças
- Inicialização de visitas com seleção de ingresso
- Cálculo automático de horário de saída
- Histórico de visitantes

### 📦 Produtos
- CRUD completo de produtos
- Controle de estoque com alerta de baixa quantidade
- Categorias auto-criadas
- Campos fiscais (NCM, CFOP, CST, alíquotas)

### 💳 Caixa
- Abertura/fechamento de caixa
- Registro de movimentações (sangria/suprimento)
- Cálculo de diferença (esperado vs. contado)
- Histórico de operações

### 🎉 Festas e Eventos
- Agendamento com calendário mensal
- Detecção automática de conflitos
- Pacotes personalizáveis
- Estatísticas de festa por mês

### 📄 Fiscal
- Emissão de NF-e/NFC-e
- Configuração de ambiente SEFAZ (homologação/produção)
- Cancelamento com justificativa
- Integração com certificado digital (pronto para conectar)

### 📈 Relatórios
- Vendas por período
- Breakdown por método de pagamento
- Top 10 produtos mais vendidos
- Exportação de dados

### 👨‍💼 Colaboradores
- CRUD de usuários
- Atribuição de roles (Admin/Gerente/Operacional)
- Histórico de acesso
- Controle de permissões

---

## 7. CONTROLE DE ACESSO

**Três Níveis de Permissão:**

| Funcionalidade | Admin | Gerente | Operacional |
|---|---|---|---|
| Dashboard | ✅ | ✅ | ❌ |
| PDV/Vendas | ✅ | ✅ | ✅ |
| Visitantes | ✅ | ✅ | ✅ |
| Caixa | ✅ | ✅ | ❌ |
| Produtos | ✅ | ✅ | ❌ |
| Festas | ✅ | ✅ | ❌ |
| Fiscal | ✅ | ✅ | ❌ |
| Relatórios | ✅ | ✅ | ❌ |
| Colaboradores | ✅ | ❌ | ❌ |

---

## 8. SEGURANÇA

### ✅ Implementações de Segurança
- Hashing de senhas com bcryptjs (algoritmo bcrypt)
- JWT com expiração de 12 horas
- httpOnly cookies para prevenção de XSS
- CSRF protection (SameSite cookies)
- Throttling de tentativas de login (5 tentativas → 15 min de bloqueio)
- Logs de auditoria para todas as mutações
- Validação de entrada com Zod em todas as APIs
- Separação de camadas: frontend protegido por layout, API protegida por guards

### 🔐 Checklist de Segurança para Produção
- [ ] Alterar `JWT_SECRET` no `.env`
- [ ] Usar HTTPS/SSL (certificado válido)
- [ ] Ativar `APP_ENV="production"`
- [ ] Implementar certificado digital para SEFAZ
- [ ] Configurar backup automático do banco de dados
- [ ] Revisar e testar todos os endpoints com dados reais
- [ ] Configurar monitoramento e alertas (erro 500, tentativas de acesso)
- [ ] Implementar rate limiting em APIs críticas
- [ ] Usar proxy reverso (nginx) com proteção DDoS
- [ ] Auditar logs regularmente

---

## 9. BANCO DE DADOS

### SQLite (Padrão)
```env
DATABASE_URL="file:./dev.db"
```
- Arquivo único, fácil de fazer backup
- Ideal para instâncias únicas
- Limite ~100K operações/segundo

### Migração para PostgreSQL (Produção)
```env
DATABASE_URL="postgresql://usuario:senha@localhost:5432/sancto_pdv"
```
1. Instale PostgreSQL
2. Altere `DATABASE_URL` no `.env`
3. Execute: `npx prisma db push`

### Backup
```bash
# SQLite
cp prisma/dev.db backups/dev-$(date +%Y%m%d-%H%M%S).db

# PostgreSQL
pg_dump -U usuario -h localhost -d sancto_pdv > backup-$(date +%Y%m%d-%H%M%S).sql
```

---

## 10. TROUBLESHOOTING

### Porta 3000 já em uso
```bash
# Windows: Encontre e mate o processo
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux: 
lsof -i :3000
kill -9 <PID>
```

### Erro de banco de dados
```bash
# Reset completo (desenvolvedores apenas)
npx prisma db push --force-reset
npm run db:seed
```

### Senha esquecida
```bash
# Acesse o banco direto com Prisma Studio
npx prisma studio
# Localize o usuário e atualize a senha
```

### Performance lenta
- Verifique memória disponível (`free` ou Task Manager)
- Aumente `NODE_OPTIONS`: `NODE_OPTIONS=--max-old-space-size=4096`
- Considere migrar para PostgreSQL se muitos dados

---

## 11. SCRIPTS DISPONÍVEIS

```bash
npm run dev                 # Iniciar servidor desenvolvimento
npm run build              # Compilar para produção
npm run start              # Executar build produção
npm run db:push            # Sincronizar schema com banco
npm run db:seed            # Popular dados iniciais
npx prisma studio         # Interface gráfica do banco
npx prisma generate       # Gerar Prisma Client
npm run lint              # Verificar erros TypeScript
```

---

## 12. SUPORTE E MANUTENÇÃO

### Logs
```bash
# Logs de erro: verificar output do terminal
# Logs de auditoria: tabela 'AuditLog' no banco
```

### Updates de Dependências
```bash
npm update                 # Verificar updates
npm audit                  # Verificar vulnerabilidades
npm audit fix              # Corrigir automaticamente
```

### Contato Suporte
- Email: suporte@sanctopdv.com
- Documentação: https://docs.senchtopdv.com
- Issues: Issues no repositório do projeto

---

## 13. ROADMAP DE INTEGRAÇÃO

Funcionalidades prontas para integração:

- ✅ **WhatsApp Business API**: Rotas preparadas para notificações (compras, festas)
- ✅ **ERP Omie**: Stub de integrações para sincronização de clientes/produtos
- ✅ **SEFAZ NFe/NFCe**: Endpoints prontos para certificado digital e produção
- ✅ **Impressora Térmica**: Estrutura de rotas para cupons/recibos
- ✅ **Storage S3/CDN**: imageUrl pronto para cloud storage

---

## 14. LICENÇA LEGAL

Consulte arquivo `LICENSE.txt` para detalhes de licenciamento.

Sistema desenvolvido especificamente para SANCTO PDV - Parques de Diversão Infantis.

---

**Versão**: 1.0.0  
**Data**: 2025  
**Status**: Produção-Ready
