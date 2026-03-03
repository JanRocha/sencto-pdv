# SANCTO PDV - Diretrizes de Arquitetura

## Objetivo

Este documento formaliza as novas diretrizes arquiteturais do SANCTO PDV para evolução segura do produto, mantendo a operação atual estável.

---

## Princípios adotados

1. **Arquitetura orientada a domínio**
   - Separar responsabilidades por contexto de negócio.
2. **Integrações por contrato**
   - Dependências externas entram via interfaces (ports/adapters).
3. **Evolução incremental sem ruptura**
   - Entregas progressivas, com feature flags e fallback mock.
4. **Segurança e auditoria por padrão**
   - Ações críticas devem ser autorizadas, validadas e rastreáveis.

---

## Contextos de domínio

### Operação
- Vendas (PDV)
- Caixa
- Visitantes
- Festas

### Governança
- Fiscal
- Relatórios
- Colaboradores

### Plataforma
- Autenticação/Autorização
- Banco de dados e persistência
- Integrações externas

---

## Arquitetura alvo (incremental)

### Camadas

- **Interface**: páginas Next.js e endpoints API.
- **Aplicação**: orquestração de casos de uso.
- **Domínio**: regras de negócio e validações centrais.
- **Infraestrutura**: Prisma e provedores de integração.

### Estratégia de integração

Todas as integrações devem ser implementadas por contrato em `src/lib/integrations`:

- `FiscalProvider` (SEFAZ)
- `MessagingProvider` (WhatsApp Business)
- `ErpProvider` (Omie)

Implementações podem ser:

- `mock` (desenvolvimento/homologação)
- `real` (produção, após homologação técnica)

### Status atual dos providers

- `FiscalProvider`
   - `mock`: emissão/cancelamento simulados ativos
   - `real`: assinaturas prontas, aguardando conector SEFAZ homologado
- `MessagingProvider`
   - `mock`: alerta de permanência simulado ativo
   - `real`: assinatura pronta, aguardando credenciais e templates aprovados
- `ErpProvider`
   - `mock`: sincronização simulada ativa
   - `real`: planejado para fase de integração Omie

---

## Diretrizes de dados

### Estado atual
- SQLite com Prisma para desenvolvimento local.

### Diretriz para produção
- PostgreSQL como banco principal em produção.
- Migração deve ocorrer com janela planejada e validação de integridade.

### Requisitos
- Índices em consultas críticas (vendas, caixa, visitantes, fiscal).
- Estratégia de backup e restore testada.
- Trilhas de auditoria preservadas em migração.

---

## Segurança e conformidade

- JWT com segredo rotacionável.
- Cookies `httpOnly`, `sameSite`, `secure` em produção.
- RBAC obrigatório em endpoints sensíveis.
- Validação de payload com Zod em mutações.
- Registro de auditoria em ações críticas.

---

## Roadmap técnico

### Fase 1 (curto prazo)
- Consolidar contratos de integração (mock-first).
- Padronizar variáveis de ambiente por provedor.
- Corrigir inconsistências de documentação e nomenclatura.

### Fase 2 (médio prazo)
- Conector fiscal real com homologação SEFAZ.
- Notificações de permanência/consumo via WhatsApp.
- Conector Omie para sincronização financeira/fiscal.

### Fase 3 (escala)
- PostgreSQL em produção com observabilidade ativa.
- Filas para tarefas assíncronas (notificações e conciliações).
- Monitoramento de SLA e alertas operacionais.

---

## Padrões obrigatórios para novas features

- Não acoplar regra de negócio diretamente ao provider externo.
- Criar interface antes de implementar integração real.
- Expor testes de conectividade por endpoint administrativo.
- Evitar quebra de contrato de API sem versionamento.