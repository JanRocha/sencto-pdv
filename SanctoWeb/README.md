# SANCTO PDV

Sistema de Ponto de Venda (PDV) para parques temáticos infantis em shopping centers.

## Visão Geral

O SANCTO PDV centraliza operação, atendimento e gestão administrativa em uma única aplicação web:

- Vendas rápidas no PDV (touchscreen)
- Cadastro de tutores e crianças
- Controle de tempo de permanência e consumo
- Agendamento de festas
- Gestão fiscal com integração preparada para SEFAZ
- Controle de caixa
- Relatórios operacionais e gerenciais

## Módulos atuais

- Dashboard
- Vendas (PDV)
- Visitantes
- Festas
- Produtos
- Caixa
- Fiscal
- Relatórios
- Colaboradores

## Arquitetura (estado atual)

- **Frontend + Backend**: Next.js App Router (rotas de UI e API)
- **Linguagem**: TypeScript (strict)
- **Banco atual**: SQLite com Prisma (desenvolvimento)
- **Autenticação**: JWT + cookies httpOnly
- **Autorização**: RBAC (Administrador, Gerente, Operacional)
- **Validação**: Zod
- **Auditoria**: logs de mutação

## Diretrizes arquiteturais novas (adotadas)

1. **Arquitetura por domínios**
	- Operação: Vendas, Caixa, Visitantes, Festas
	- Governança: Fiscal, Relatórios, Colaboradores
2. **Integrações desacopladas por contratos**
	- Provedores para SEFAZ, WhatsApp Business e ERP (Omie)
	- Implementações reais podem ser trocadas sem alterar regras de negócio
3. **Pronto para evolução de banco**
	- SQLite em dev, trilha clara para PostgreSQL em produção
4. **Segurança e rastreabilidade por padrão**
	- Sessão segura, RBAC e trilhas de auditoria

Consulte `ARCHITECTURE.md` para os detalhes da arquitetura alvo e roadmap técnico.

## Como executar

### Pré-requisitos

- Node.js 20+
- npm 9+

### Instalação

```bash
npm install
```

### Banco e seed

```bash
npx prisma generate
npx prisma db push
npm run db:seed
```

### Subir aplicação

```bash
npm run dev
```

Aplicação disponível em `http://localhost:3000`.

## Variáveis de ambiente (mínimo)

```env
DATABASE_URL="file:./dev.db"
JWT_SECRET="troque-este-segredo"
APP_ENV="development"

# Arquitetura de integrações (novas diretrizes)
FISCAL_PROVIDER="mock"
WHATSAPP_PROVIDER="mock"
ERP_PROVIDER="mock"
```

### Modos de integração

- `mock`: recomendado para desenvolvimento e homologação funcional
- `real`: ativa o stub real (assinaturas prontas) e bloqueia emissão/cancelamento fiscal até homologação do conector

### Endpoint administrativo de teste (WhatsApp)

- Rota: `POST /api/integrations/whatsapp/test`
- Perfis: `ADMINISTRADOR`, `GERENTE`
- Payload:

```json
{
	"tutorPhone": "11999999999",
	"childName": "Ana",
	"minutesRemaining": 15
}
```

## Documentação do projeto

- `INDEX.md` - índice geral
- `QUICKSTART.md` - início rápido
- `DEPLOYMENT.md` - guia de implantação
- `CHECKLIST.md` - status técnico do projeto
- `ARCHITECTURE.md` - diretrizes arquiteturais e roadmap

## Próximas fases

- Migrar produção para PostgreSQL
- Conectar provedor fiscal real (SEFAZ)
- Conectar WhatsApp Business API para notificações
- Conectar ERP Omie para sincronização financeira/fiscal
