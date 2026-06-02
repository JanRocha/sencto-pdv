# Implementation Plan: Sancto PDV Delphi

## Overview

Implementação do sistema Sancto PDV em Delphi 10.2 Tokyo com FMX, seguindo a estratégia MOCK-first: toda a infraestrutura de dados em memória (TObjectList) é construída primeiro para validar layouts e navegação, seguida pela integração real com FenixORM/Firebird e serviços externos (ACBr, WhatsApp, Omie).

## Tasks

- [ ] 1. Estrutura do projeto e infraestrutura Mock
  - [ ] 1.1 Criar estrutura de diretórios do projeto (Shared/Models, Shared/Controllers, Shared/Services, Shared/Mock, Shared/ORM) e arquivos .dpr dos dois executáveis (SanctoPDV_PDV.dpr e SanctoPDV_Backoffice.dpr)
    - Configurar search path compartilhado entre os dois projetos
    - Criar project group (.groupproj) unificando ambos
    - _Requisitos: 12.4, 12.6_

  - [ ] 1.2 Implementar todas as classes Model (entidades) em Shared/Models
    - Model.Entidade.Colaborador.pas, Model.Entidade.Produto.pas, Model.Entidade.Categoria.pas
    - Model.Entidade.Caixa.pas, Model.Entidade.MovimentacaoCaixa.pas
    - Model.Entidade.Venda.pas, Model.Entidade.VendaItem.pas
    - Model.Entidade.Visitante.pas, Model.Entidade.Visita.pas, Model.Entidade.VisitaConsumo.pas
    - Model.Entidade.Tutor.pas, Model.Entidade.Ticket.pas
    - Model.Entidade.Festa.pas, Model.Entidade.PacoteFesta.pas, Model.Entidade.FestaPagamento.pas
    - Model.Entidade.NotaFiscal.pas, Model.Entidade.Configuracao.pas, Model.Entidade.LogAuditoria.pas
    - Model.Entidade.NotificacaoWhatsApp.pas
    - _Requisitos: 12.4_


  - [ ] 1.3 Implementar interface IDAO<T> e classe TMockDAO<T> em Shared/Mock/Mock.DAO.pas
    - Interface com Insert, Update, Delete, Save, Find, FindAll, Count, Where, LastId
    - Suporte a BeginTransaction/Commit/Rollback com snapshot para rollback
    - Dados em TObjectList<T> com auto-incremento de Id via RTTI
    - _Requisitos: 12.6_

  - [ ] 1.4 Implementar TControllerBase<T> em Shared/Controllers/Controller.Base.pas
    - Flag FUsarMock para alternar entre MockDAO e DAO real
    - Método CriarDAO virtual para override nos controllers filhos
    - Método RegistrarAuditoria para logging de ações críticas
    - _Requisitos: 12.4_

  - [ ] 1.5 Implementar hierarquia de exceções customizadas em Shared/Utils/Utils.Exceptions.pas
    - ESanctoPDVException, EValidacaoException, EAutenticacaoException
    - EPermissaoException, ECaixaException, EEstoqueException, EFiscalException, EConexaoException
    - _Requisitos: 12.4_

  - [ ]* 1.6 Criar unit TestGen.SanctoPDV.pas com geradores de dados aleatórios para testes PBT
    - GerarString, GerarCPFValido, GerarEmail, GerarTelefone, GerarCurrency, GerarInteger
    - GerarColaboradorValido, GerarProdutoValido, GerarTicket, GerarVendaComItens
    - _Requisitos: 12.6_

- [ ] 2. Autenticação e Login
  - [ ] 2.1 Implementar Service.Autenticacao.pas com lógica de login, bloqueio e sessão
    - Login com verificação de CPF, senha (hash), status ativo, bloqueio por 5 tentativas
    - Timeout de sessão de 30 minutos de inatividade
    - Métodos GerarHash e VerificarHash para senhas
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.10, 1.11_

  - [ ] 2.2 Implementar Controller.Colaborador.pas com validações de cadastro
    - Validar nome (3-120 chars), CPF (11 dígitos válidos), email, telefone (10-11 dígitos), senha (min 6)
    - Verificar unicidade de CPF e email
    - Métodos para ativar/desativar/desbloquear colaborador
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 2.8_

  - [ ] 2.3 Criar Form de Login compartilhado (Frm.Login.pas) com FMX
    - Campo CPF com máscara, campo senha com toggle visibilidade
    - Mensagens genéricas de erro (sem revelar campo incorreto)
    - Indicação de tempo restante de bloqueio
    - Feedback visual touch-friendly (48x48px mínimo)
    - _Requisitos: 1.1, 1.2, 1.4, 13.1, 13.2_

  - [ ]* 2.4 Escrever testes PBT para autenticação (Properties 1-4)
    - **Property 1: Autenticação aceita credenciais válidas de conta ativa**
    - **Property 2: Credenciais inválidas incrementam contador de tentativas**
    - **Property 3: Conta bloqueada rejeita qualquer tentativa**
    - **Property 4: Conta inativa rejeita autenticação**
    - **Valida: Requisitos 1.1, 1.2, 1.4, 1.10**

  - [ ]* 2.5 Escrever testes PBT para validação de cadastro de colaborador (Properties 5-9)
    - **Property 5: Validação de cadastro aceita dados válidos e rejeita inválidos**
    - **Property 6: Unicidade de CPF no cadastro**
    - **Property 7: Unicidade de email no cadastro**
    - **Property 8: Round-trip de hash de senha**
    - **Property 9: Edição de colaborador persiste alterações (round-trip)**
    - **Valida: Requisitos 2.1, 2.2, 2.3, 2.5, 2.6**

- [ ] 3. Checkpoint — Validar infraestrutura base
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

- [ ] 4. Tela Principal PDV com layout de 3 painéis (Mock)
  - [ ] 4.1 Implementar Controller.Produto.pas com validações e filtro por categoria
    - Validar nome (≤120 chars), código de barras (EAN-8/EAN-13/interno ≤20), preço (0.01-999999.99)
    - Validar campos fiscais: NCM (8 dígitos), CFOP (4 dígitos), alíquotas (0-100%)
    - Verificar unicidade de código de barras
    - Filtro por categoria, controle de estoque mínimo
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 3.9, 3.10_

  - [ ] 4.2 Implementar Controller.Venda.pas com lógica de carrinho e finalização
    - Adicionar produto ao carrinho (incrementar se já existe)
    - Verificar estoque antes de adicionar
    - Calcular subtotal, aplicar desconto, calcular total
    - Finalizar venda com decremento atômico de estoque (transação)
    - Vincular venda ao caixa aberto do colaborador
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.9, 5.10, 5.11, 5.12_

  - [ ] 4.3 Criar Frm.Main.PDV.pas — tela principal com navegação lateral
    - Menu lateral com ícones: Vendas, Caixa, Visitantes, Festas
    - Visibilidade de itens baseada no papel do colaborador logado
    - Header com logo, nome do colaborador, ID do caixa, botão logout
    - Footer com status fiscal, hora e alertas
    - _Requisitos: 1.5, 1.6, 13.1, 13.2, 13.3_

  - [ ] 4.4 Criar Frm.Vendas.pas — tela de vendas com 3 painéis (categorias, produtos, carrinho)
    - Painel esquerdo: lista de categorias com botão "Todos"
    - Painel central: grid de cards de produtos (nome, preço, badge estoque baixo)
    - Painel direito: carrinho com itens, subtotal, desconto, total, botões Cancelar/Pagar
    - Dialog de pagamento: forma de pagamento, parcelas (crédito), CPF opcional
    - Cards touch-friendly com 48x48px mínimo e feedback visual <100ms
    - _Requisitos: 5.1, 5.2, 5.3, 5.6, 5.7, 5.8, 5.9, 5.12, 13.1, 13.2, 13.6_

  - [ ]* 4.5 Escrever testes PBT para produtos e vendas (Properties 10-14, 21-26)
    - **Property 10: Validação de produto aceita dados válidos e rejeita inválidos**
    - **Property 11: Unicidade de código de barras**
    - **Property 12: Produto com vínculos não pode ser excluído**
    - **Property 13: Alerta de estoque mínimo**
    - **Property 14: Filtro por categoria retorna apenas produtos da categoria**
    - **Property 21: Adição ao carrinho com quantidade correta**
    - **Property 22: Decremento atômico de estoque na venda**
    - **Property 23: Venda vinculada ao caixa do colaborador**
    - **Property 24: Cálculo de desconto na venda**
    - **Property 25: Cancelamento limpa carrinho sem afetar estoque**
    - **Property 26: Estoque insuficiente bloqueia adição**
    - **Valida: Requisitos 3.1, 3.2, 3.3, 3.5, 3.9, 5.1-5.6, 5.9, 5.10**

- [ ] 5. Controle de Caixa com Mock
  - [ ] 5.1 Implementar Controller.Caixa.pas com lógica de abertura, fechamento e movimentações
    - Abertura com valor inicial (0-999999.99), um caixa aberto por colaborador
    - Sangria (validar valor ≤ saldo) e suprimento com motivo (3-200 chars)
    - Fechamento: cálculo saldo esperado, contagem física, diferença, justificativa se > tolerância
    - Bloquear vendas sem caixa aberto
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10_

  - [ ] 5.2 Criar Frm.Caixa.pas — tela de caixa com abertura, movimentações e fechamento
    - Dialog abertura: valor inicial
    - Lista de movimentações (tipo, valor, motivo, hora)
    - Dialog sangria/suprimento: valor e motivo
    - Dialog fechamento: resumo, contagem física, diferença (vermelho se > tolerância), justificativa
    - _Requisitos: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 13.1, 13.4, 13.5_

  - [ ]* 5.3 Escrever testes PBT para caixa (Properties 17-20)
    - **Property 17: Saldo de caixa após movimentações**
    - **Property 18: Sem caixa aberto bloqueia vendas**
    - **Property 19: Máximo um caixa aberto por colaborador**
    - **Property 20: Sangria maior que saldo é rejeitada**
    - **Valida: Requisitos 4.1, 4.2, 4.3, 4.4, 4.5, 4.8, 4.9, 5.11**

- [ ] 6. Gestão de Visitantes com Mock
  - [ ] 6.1 Implementar Controller.Visitante.pas com lógica de visitas e controle de tempo
    - Registro de entrada: tutor, criança, ticket, cálculo hora prevista saída
    - Controle de tempo extra: cálculo por minuto excedente
    - Consumo: vincular produto à visita, incrementar total, verificar limite
    - Finalização: calcular total (ticket + consumo + tempo extra)
    - Recuperação automática de tutor por CPF
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.6, 6.7, 6.8, 6.9, 6.10, 6.11, 6.12_

  - [ ] 6.2 Criar Frm.Visitantes.pas — tela de visitantes com timer e consumo
    - Lista de visitas abertas com contador regressivo (atualizado a cada 1s)
    - Alerta visual e sonoro quando tempo restante ≤ minutos configurados
    - Dialog entrada: dados tutor, criança, seleção ticket
    - Dialog consumo: seleção produto, quantidade
    - Dialog finalização: resumo valores, forma de pagamento
    - Badge de limite de consumo atingido
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.8, 6.10, 13.1, 13.2_

  - [ ]* 6.3 Escrever testes PBT para visitantes (Properties 27-33)
    - **Property 27: Cálculo de horário de saída do visitante**
    - **Property 28: Alerta ativado antes do vencimento**
    - **Property 29: Cálculo de tempo extra**
    - **Property 30: Consumo incrementa total da visita**
    - **Property 31: Limite de consumo bloqueia quando atingido**
    - **Property 32: Cálculo total da visita**
    - **Property 33: Day Pass não cobra tempo extra**
    - **Valida: Requisitos 6.2, 6.4, 6.6, 6.7, 6.8, 6.9, 6.10, 6.12**

- [ ] 7. Gestão de Festas com Mock
  - [ ] 7.1 Implementar Controller.Festa.pas com lógica de agendamento, conflitos e pagamentos
    - Agendamento: validar dados, verificar conflito de slot, validar capacidade pacote
    - Preço baseado no dia da semana (semana vs FDS/feriado)
    - Pagamentos parciais: calcular saldo pendente
    - Cancelamento: exigir motivo (min 10 chars), liberar slot
    - Validar horário contra slots configurados
    - _Requisitos: 7.1, 7.2, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9_

  - [ ] 7.2 Criar Frm.Festas.pas — tela de festas com calendário e agendamento
    - Calendário mensal visual (slots ocupados, parciais, livres)
    - Dialog agendamento: dados aniversariante, tutor, data, slot, pacote
    - Lista de festas com status, pagamentos e saldo pendente
    - Dialog pagamento parcial: valor e forma
    - Dialog cancelamento: motivo obrigatório
    - _Requisitos: 7.1, 7.2, 7.3, 7.5, 7.6, 13.1_

  - [ ]* 7.3 Escrever testes PBT para festas (Properties 34-38)
    - **Property 34: Conflito de horário em festas**
    - **Property 35: Preço de festa determinado pelo dia da semana**
    - **Property 36: Saldo pendente de festa após pagamentos**
    - **Property 37: Capacidade máxima de convidados**
    - **Property 38: Horário fora de slots válidos é rejeitado**
    - **Valida: Requisitos 7.2, 7.4, 7.5, 7.7, 7.9**

- [ ] 8. Checkpoint — Validar todas as telas Mock do PDV
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

- [ ] 9. Backoffice — CRUD Produtos com Mock
  - [ ] 9.1 Criar Frm.Main.Backoffice.pas — tela principal do Backoffice com navegação
    - Menu lateral: Dashboard, Produtos, Colaboradores, Fiscal, Relatórios, Configurações
    - Controle de acesso: rejeitar papel OPERACIONAL no login
    - _Requisitos: 1.7, 1.8, 13.3_

  - [ ] 9.2 Criar Frm.Produtos.pas — tela CRUD de produtos no Backoffice
    - Grid com lista de produtos (nome, código, categoria, preço, estoque, status)
    - Dialog cadastro/edição: todos os campos obrigatórios + campos fiscais
    - Botões ativar/desativar (não excluir se tem vínculos)
    - Importação Excel (.xlsx) com validação por linha e relatório de erros
    - Exportação Excel (.xlsx) de produtos ativos
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.6, 3.7, 3.8, 3.10_

  - [ ]* 9.3 Escrever testes PBT para importação/exportação (Properties 15-16)
    - **Property 15: Importação de planilha valida cada linha corretamente**
    - **Property 16: Exportação contém todos os produtos ativos (round-trip)**
    - **Valida: Requisitos 3.6, 3.8**

- [ ] 10. Backoffice — CRUD Colaboradores com Mock
  - [ ] 10.1 Criar Frm.Colaboradores.pas — tela CRUD de colaboradores no Backoffice
    - Grid com lista de colaboradores (nome, CPF, papel, status)
    - Dialog cadastro: nome, CPF (imutável na edição), email, telefone, senha, papel
    - Botões desativar/reativar, impedir desativação da própria conta
    - Desbloquear conta (zerar tentativas, remover data bloqueio)
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [ ]* 10.2 Escrever testes unitários para CRUD de colaboradores
    - Testar validações de campos com dados específicos
    - Testar rejeição de auto-desativação
    - Testar desbloqueio de conta
    - _Requisitos: 2.4, 2.7, 2.8_

- [ ] 11. Backoffice — Pacotes de Festa com Mock
  - [ ] 11.1 Criar tela de gestão de Pacotes de Festa no Backoffice
    - CRUD de PacoteFesta: nome (≤80 chars), max convidados (1-200), preço semana, preço FDS, descrição (≤500 chars)
    - Ativar/desativar pacotes
    - _Requisitos: 7.8_

- [ ] 12. Checkpoint — Validar todas as telas Mock completas (PDV + Backoffice)
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

- [ ] 13. Integração FenixORM com Firebird (substituir Mock por persistência real)
  - [ ] 13.1 Criar script DDL Firebird com todas as tabelas, generators, índices e constraints
    - Tabelas: COLABORADOR, CATEGORIA, PRODUTO, CAIXA, MOVIMENTACAO_CAIXA, VENDA, VENDA_ITEM
    - TUTOR, VISITANTE, TICKET, VISITA, VISITA_CONSUMO, PACOTE_FESTA, FESTA, FESTA_PAGAMENTO
    - NOTA_FISCAL, NOTIFICACAO_WHATSAPP, LOG_AUDITORIA, CONFIGURACAO
    - Generators (sequences) para auto-incremento de cada tabela
    - Foreign keys e índices para campos de busca frequente
    - _Requisitos: 12.1_

  - [ ] 13.2 Implementar TFenixDAO<T> (DAO real com FenixORM) que implementa IDAO<T>
    - Utilizar FenixORM existente (pasta ORM/) com FireDAC + Firebird
    - Queries parametrizadas em todas as operações (sem concatenação SQL)
    - Transações explícitas (BeginTransaction/Commit/Rollback)
    - _Requisitos: 12.1, 12.2, 12.3_

  - [ ] 13.3 Alterar TControllerBase para usar TFenixDAO quando FUsarMock = False
    - Configurar conexão FireDAC (IP, porta, caminho do banco, credenciais)
    - Manter flag para alternar entre Mock e Real via configuração
    - _Requisitos: 12.1, 12.5_

  - [ ]* 13.4 Escrever testes PBT para FenixORM (Properties 40-41)
    - **Property 40: Queries parametrizadas (sem concatenação SQL)**
    - **Property 41: Transações atômicas para operações multi-entidade**
    - **Valida: Requisitos 12.2, 12.3**

  - [ ]* 13.5 Escrever testes de integração com Firebird de teste
    - CRUD completo de cada entidade
    - Transação com rollback em falha simulada
    - Conexão/reconexão em falha de rede
    - _Requisitos: 12.1, 12.2, 12.3, 12.5_

- [ ] 14. Checkpoint — Validar persistência real com Firebird
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

- [ ] 15. Integração Fiscal com ACBr
  - [ ] 15.1 Implementar Service.Fiscal.pas com emissão NFC-e/NF-e via ACBr
    - Configurar componente TACBrNFe com certificado digital
    - Preencher XML da nota com dados do produto (NCM, CFOP, CST, alíquotas)
    - Transmitir à SEFAZ com timeout de 30 segundos
    - Contingência offline: armazenar e retransmitir a cada 5 min por 24h
    - Cancelamento de NFC-e dentro de 30 minutos com justificativa
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5, 8.9, 8.10_

  - [ ] 15.2 Criar Frm.Fiscal.pas no Backoffice — configuração fiscal
    - Configuração certificado digital (A1/A3), validação de validade
    - Alerta de expiração (30 dias antes)
    - Configuração ambiente SEFAZ (homologação/produção), série, numeração inicial
    - _Requisitos: 8.6, 8.7, 8.8_

  - [ ] 15.3 Integrar emissão fiscal no fluxo de finalização de venda (Frm.Vendas)
    - Após venda finalizada: gerar NFC-e se emissão habilitada
    - Exibir DANFE para impressão (80mm térmica)
    - Indicação visual de contingência no footer do PDV
    - _Requisitos: 8.1, 8.2, 8.3_

  - [ ]* 15.4 Escrever teste PBT para campos fiscais no XML (Property 39)
    - **Property 39: Campos fiscais no XML da nota**
    - **Valida: Requisitos 8.9**

- [ ] 16. Integração WhatsApp Business API
  - [ ] 16.1 Implementar Service.WhatsApp.pas com envio de alertas via RESTRequest4Delphi
    - Enviar mensagem template pré-aprovado ao tutor
    - Registrar resultado (ENVIADA, FALHA, NÃO_CONFIGURADA)
    - Não bloquear operação de visitantes em caso de falha
    - _Requisitos: 10.1, 10.2, 10.3, 10.6_

  - [ ] 16.2 Integrar alerta WhatsApp no Controller.Visitante quando tempo atinge limite
    - Disparar envio quando tempo restante ≤ minutos configurados
    - Exibir ícone de status (enviada/falha) na linha do visitante
    - _Requisitos: 6.5, 10.1, 10.3_

  - [ ] 16.3 Criar tela de configuração WhatsApp no Backoffice (Frm.Configuracoes)
    - Campos: token de acesso, phone number ID, template ID
    - Configuração de minutos antes do vencimento para disparo (1-60, padrão 10)
    - Validação de campos obrigatórios não vazios
    - _Requisitos: 10.4, 10.5_

- [ ] 17. Integração ERP Omie
  - [ ] 17.1 Implementar Service.Omie.pas com sincronização via RESTRequest4Delphi
    - Sincronizar produtos novos/alterados com resumo (enviado, sucesso, falha)
    - Sincronizar tutores (clientes) com resultado individual
    - Enviar nota fiscal autorizada ao Omie em até 60s após autorização SEFAZ
    - Tratamento de falha: registrar erro, marcar pendente, permitir retentativa
    - _Requisitos: 11.1, 11.2, 11.3, 11.4_

  - [ ] 17.2 Criar tela de configuração Omie no Backoffice e integrar envio pós-emissão
    - Campos: app_key, app_secret, endpoint URL
    - Validação de campos obrigatórios não vazios
    - Suprimir envio automático se credenciais não configuradas
    - _Requisitos: 11.5, 11.6_

- [ ] 18. Checkpoint — Validar integrações externas
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

- [ ] 19. Relatórios e Dashboard
  - [ ] 19.1 Implementar Controller.Relatorio.pas com filtros e cálculos de indicadores
    - Relatório de vendas: período, colaborador, forma pagamento, categoria
    - Relatório de caixa: aberturas, fechamentos, sangrias, suprimentos, diferenças
    - Relatório de visitantes: total visitas, tempo médio, receita consumo
    - Relatório de produtos: ranking top 50, estoque baixo, inativos
    - Exportação PDF e Excel (até 10.000 registros em ≤30s)
    - _Requisitos: 9.1, 9.2, 9.3, 9.5, 9.6_

  - [ ] 19.2 Criar Frm.Dashboard.pas — dashboard com indicadores do dia
    - Total vendas em reais, número visitantes ABERTA, caixas abertos, alertas pendentes
    - Atualizado a cada acesso
    - _Requisitos: 9.4_

  - [ ] 19.3 Criar Frm.Relatorios.pas — tela de relatórios com filtros e exportação
    - Abas: Vendas, Caixa, Visitantes, Produtos
    - Filtros por período (max 365 dias), colaborador, forma pagamento, categoria
    - Botões exportar PDF e Excel
    - _Requisitos: 9.1, 9.2, 9.3, 9.5, 9.6_

- [ ] 20. Auditoria e Rastreabilidade
  - [ ] 20.1 Implementar Controller.Auditoria.pas e integrar log em todas as ações críticas
    - Registrar: colaborador_id, tipo_ação, entidade, entidade_id, valores anteriores/novos, timestamp
    - Integrar em: vendas, caixa (abrir/fechar/sangria/suprimento), cadastros, fiscal, festas, configurações
    - Impedir UPDATE/DELETE no log de auditoria
    - Registrar tentativas de acesso negado
    - _Requisitos: 14.1, 14.2, 14.3, 14.4_

  - [ ] 20.2 Criar tela de consulta de log de auditoria no Backoffice
    - Filtros: colaborador, tipo ação, entidade, período
    - Ordenação por data/hora decrescente, paginação 50 registros
    - Somente leitura (sem edição/exclusão)
    - _Requisitos: 14.2, 14.4_

  - [ ]* 20.3 Escrever testes PBT para auditoria (Properties 42-43)
    - **Property 42: Registro de auditoria para ações críticas**
    - **Property 43: Imutabilidade do log de auditoria**
    - **Valida: Requisitos 14.1, 14.3, 14.4**

- [ ] 21. Tela de Configurações do Sistema
  - [ ] 21.1 Criar Frm.Configuracoes.pas — tela unificada de configurações no Backoffice
    - Aba Banco de Dados: tipo (Firebird/SQLite), caminho, credenciais
    - Aba FenixORM: modo (local/cloud/híbrido), URL base, credenciais cloud
    - Aba Fiscal: ambiente SEFAZ, série, certificado digital, CNPJ
    - Aba Visitantes: minutos alerta visual (1-60, padrão 5), minutos alerta WhatsApp (1-60, padrão 10)
    - Aba Caixa: tolerância diferença fechamento (R$0-100, padrão R$5)
    - Aba WhatsApp: token, phone number ID, template ID
    - Aba Omie: app_key, app_secret, endpoint URL
    - Validação de valores e aplicação imediata (sem reiniciar)
    - Registrar alterações no log de auditoria
    - _Requisitos: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_

- [ ] 22. Checkpoint Final — Validar sistema completo
  - Garantir que todos os testes passam, perguntar ao usuário se há dúvidas.

## Notes

- Tarefas marcadas com `*` são opcionais e podem ser ignoradas para um MVP mais rápido
- Cada tarefa referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes PBT validam propriedades universais de corretude com 100+ iterações
- Testes unitários validam exemplos específicos e edge cases
- A fase MOCK (tarefas 1-12) valida layout e navegação ANTES da integração com banco real
- A integração FenixORM (tarefa 13) substitui o MockDAO por persistência real Firebird
- Integrações externas (ACBr, WhatsApp, Omie) são as últimas por terem dependências externas

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.5"] },
    { "id": 2, "tasks": ["1.3", "1.4", "1.6"] },
    { "id": 3, "tasks": ["2.1", "2.2"] },
    { "id": 4, "tasks": ["2.3", "2.4", "2.5"] },
    { "id": 5, "tasks": ["4.1", "4.2", "5.1", "4.3"] },
    { "id": 6, "tasks": ["4.4", "5.2", "6.1", "7.1"] },
    { "id": 7, "tasks": ["4.5", "5.3", "6.2", "7.2"] },
    { "id": 8, "tasks": ["6.3", "7.3", "9.1"] },
    { "id": 9, "tasks": ["9.2", "10.1", "11.1"] },
    { "id": 10, "tasks": ["9.3", "10.2"] },
    { "id": 11, "tasks": ["13.1"] },
    { "id": 12, "tasks": ["13.2", "13.3"] },
    { "id": 13, "tasks": ["13.4", "13.5"] },
    { "id": 14, "tasks": ["15.1", "16.1", "17.1"] },
    { "id": 15, "tasks": ["15.2", "15.3", "16.2", "16.3", "17.2"] },
    { "id": 16, "tasks": ["15.4"] },
    { "id": 17, "tasks": ["19.1", "20.1"] },
    { "id": 18, "tasks": ["19.2", "19.3", "20.2", "21.1"] },
    { "id": 19, "tasks": ["20.3"] }
  ]
}
```
