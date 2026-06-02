# Requirements Document

## Introduction

Este documento especifica os requisitos para a reescrita completa do sistema SANCTO PDV, migrando da implementação atual em Next.js para Delphi 10.2 Tokyo com interface FireMonkey (FMX). O sistema é um Ponto de Venda (PDV) para parques temáticos infantis indoor localizados em shopping centers. A solução será composta por dois executáveis independentes: **SanctoPDV_Backoffice.exe** (administração) e **SanctoPDV_PDV.exe** (operação de vendas).

## Glossary

- **Sistema_PDV**: Aplicativo executável SanctoPDV_PDV.exe responsável pela operação de vendas, caixa, visitantes e festas
- **Sistema_Backoffice**: Aplicativo executável SanctoPDV_Backoffice.exe responsável pela administração de produtos, colaboradores, configurações fiscais e relatórios
- **FenixORM**: ORM genérico customizado baseado em FireDAC (modo local) e RESTRequest4Delphi (modo cloud), utilizado para persistência de dados
- **Colaborador**: Usuário do sistema com papel definido (ADMINISTRADOR, GERENTE ou OPERACIONAL)
- **Caixa**: Registro de controle financeiro diário que deve ser aberto antes de qualquer operação de venda
- **Visitante**: Criança registrada no parque com controle de tempo e consumo, vinculada a um Tutor
- **Tutor**: Responsável legal pela criança visitante
- **Ticket**: Produto do tipo ingresso que define o tempo de permanência da criança no parque
- **Sangria**: Retirada de valores do caixa durante operação
- **Suprimento**: Adição de valores ao caixa durante operação
- **NFC-e**: Nota Fiscal de Consumidor Eletrônica emitida via ACBr/SEFAZ
- **NF-e**: Nota Fiscal Eletrônica emitida via ACBr/SEFAZ
- **DANFE**: Documento Auxiliar da Nota Fiscal Eletrônica (impressão)
- **ACBr**: Biblioteca de componentes Delphi para comunicação fiscal com SEFAZ
- **SEFAZ**: Secretaria da Fazenda responsável pela autorização de documentos fiscais eletrônicos
- **Pacote_Festa**: Configuração de pacote para festas de aniversário com capacidade, preço e descrição
- **Limite_Consumo**: Valor monetário máximo que uma criança pode consumir durante a visita
- **FireDAC**: Framework de acesso a dados da Embarcadero utilizado pelo FenixORM no modo local
- **RESTRequest4Delphi**: Biblioteca de Vinícius Sanches para consumo de APIs REST
- **ERP_Omie**: Sistema ERP externo para sincronização de produtos, clientes e notas fiscais
- **WhatsApp_API**: API do WhatsApp Business utilizada para notificações aos tutores

---

## Requirements

### Requisito 1: Autenticação e Controle de Acesso

**User Story:** Como administrador do parque, eu quero que apenas colaboradores autorizados acessem o sistema com permissões baseadas em papéis, para que a segurança operacional seja garantida.

#### Critérios de Aceitação

1. WHEN um Colaborador informa CPF e senha válidos e a conta está ativa e não bloqueada, THE Sistema_PDV SHALL autenticar o Colaborador, registrar a data e hora do acesso e exibir a tela principal correspondente ao papel do Colaborador.
2. WHEN um Colaborador informa credenciais inválidas (CPF inexistente ou senha incorreta), THE Sistema_PDV SHALL incrementar o contador de tentativas falhas e exibir mensagem de erro genérica sem revelar qual campo está incorreto.
3. WHEN um Colaborador atinge 5 tentativas de login falhas consecutivas, THE Sistema_PDV SHALL bloquear a conta do Colaborador por 15 minutos, zerar o contador de tentativas e registrar o evento no log de auditoria.
4. WHILE a conta de um Colaborador estiver bloqueada, THE Sistema_PDV SHALL rejeitar tentativas de login desse Colaborador e exibir mensagem informando o tempo restante de bloqueio em minutos.
5. WHEN um Colaborador com papel OPERACIONAL realiza login, THE Sistema_PDV SHALL exibir apenas as funções de Vendas, Caixa e Visitantes.
6. WHEN um Colaborador com papel ADMINISTRADOR ou GERENTE realiza login, THE Sistema_PDV SHALL exibir todas as funções do sistema incluindo Dashboard, Vendas, Caixa, Visitantes, Festas, Produtos, Colaboradores, Fiscal e Relatórios.
7. WHEN um Colaborador com papel ADMINISTRADOR ou GERENTE realiza login no Sistema_Backoffice, THE Sistema_Backoffice SHALL conceder acesso completo a todas as funcionalidades administrativas.
8. WHEN um Colaborador com papel OPERACIONAL tenta acessar o Sistema_Backoffice, THE Sistema_Backoffice SHALL negar o acesso e exibir mensagem informando permissão insuficiente.
9. WHEN um Colaborador realiza logout, THE Sistema_PDV SHALL encerrar a sessão, registrar o horário de saída no log de auditoria e retornar à tela de login.
10. IF um Colaborador com conta inativa tenta realizar login, THEN THE Sistema_PDV SHALL rejeitar a autenticação e exibir mensagem de erro genérica sem revelar o motivo específico da rejeição.
11. IF a sessão de um Colaborador permanece inativa por mais de 30 minutos, THEN THE Sistema_PDV SHALL encerrar a sessão automaticamente e redirecionar o Colaborador para a tela de login.

---

### Requisito 2: Gestão de Colaboradores

**User Story:** Como administrador, eu quero cadastrar, editar e desativar colaboradores com diferentes papéis, para que o controle de acesso ao sistema seja gerenciado de forma segura.

#### Critérios de Aceitação

1. WHEN um ADMINISTRADOR solicita cadastro de novo Colaborador, THE Sistema_Backoffice SHALL exigir nome completo (mínimo 3, máximo 120 caracteres), CPF (11 dígitos numéricos válidos), email (formato válido, máximo 255 caracteres), telefone (mínimo 10, máximo 11 dígitos), senha (mínimo 6 caracteres) e papel (ADMINISTRADOR, GERENTE ou OPERACIONAL).
2. WHEN um ADMINISTRADOR submete o formulário de cadastro com CPF já existente, THE Sistema_Backoffice SHALL rejeitar o cadastro e exibir mensagem informando que o CPF já está registrado.
3. WHEN um ADMINISTRADOR submete o formulário de cadastro com email já existente, THE Sistema_Backoffice SHALL rejeitar o cadastro e exibir mensagem informando que o email já está registrado.
4. WHEN um ADMINISTRADOR solicita desativação de um Colaborador diferente de si próprio, THE Sistema_Backoffice SHALL definir o status do Colaborador como inativo e impedir login futuro sem excluir o registro.
5. WHEN um ADMINISTRADOR edita os dados de um Colaborador, THE Sistema_Backoffice SHALL permitir alteração de nome completo, email, telefone, papel e senha, manter o CPF inalterável, salvar as alterações e registrar a modificação no log de auditoria.
6. THE Sistema_Backoffice SHALL armazenar senhas de Colaboradores utilizando hash criptográfico unidirecional.
7. WHEN um ADMINISTRADOR ou GERENTE solicita reativação de um Colaborador bloqueado por 5 tentativas de login falhas consecutivas, THE Sistema_Backoffice SHALL zerar o contador de tentativas, remover a data de bloqueio e desbloquear a conta imediatamente.
8. IF um ADMINISTRADOR tenta desativar a própria conta, THEN THE Sistema_Backoffice SHALL rejeitar a operação e exibir mensagem indicando que não é permitido desativar o próprio usuário.

---

### Requisito 3: Gestão de Produtos

**User Story:** Como gerente do parque, eu quero cadastrar e manter produtos com informações fiscais completas, para que o PDV opere com dados corretos e em conformidade fiscal.

#### Critérios de Aceitação

1. WHEN um ADMINISTRADOR ou GERENTE cadastra um novo Produto, THE Sistema_Backoffice SHALL exigir nome (máximo 120 caracteres), código de barras (formato EAN-8, EAN-13 ou código interno de até 20 caracteres), categoria, preço de venda (entre 0,01 e 999.999,99), unidade, tipo (PRODUTO, SERVIÇO ou INGRESSO), estoque inicial (0 a 99.999), estoque mínimo (0 a 99.999) e campos fiscais (NCM com 8 dígitos, CFOP com 4 dígitos, CST/CSOSN, alíquotas ICMS/PIS/COFINS entre 0,00% e 100,00%).
2. WHEN um ADMINISTRADOR ou GERENTE submete o formulário com código de barras já existente, THE Sistema_Backoffice SHALL rejeitar o cadastro e exibir mensagem informando duplicidade do código de barras.
3. WHEN um ADMINISTRADOR ou GERENTE solicita exclusão de um Produto que possui itens de venda ou itens de visita vinculados, THE Sistema_Backoffice SHALL negar a exclusão e oferecer a opção de desativação.
4. WHEN um ADMINISTRADOR ou GERENTE desativa um Produto, THE Sistema_Backoffice SHALL definir o status como inativo e ocultar o Produto da tela de vendas do Sistema_PDV.
5. WHEN o estoque de um Produto atinge o valor de estoque mínimo configurado após uma venda ou ajuste, THE Sistema_PDV SHALL exibir badge vermelho no card do Produto e emitir alerta sonoro na tela de vendas.
6. WHEN um ADMINISTRADOR ou GERENTE importa planilha Excel (.xlsx) de produtos com até 5.000 linhas, THE Sistema_Backoffice SHALL validar cada linha conforme as regras do critério 1, inserir produtos válidos, e gerar relatório de erros listando número da linha, campo inválido e motivo da rejeição para cada linha inválida.
7. IF a planilha importada contém mais de 5.000 linhas, THEN THE Sistema_Backoffice SHALL rejeitar a importação e exibir mensagem informando o limite máximo de linhas permitido.
8. WHEN um ADMINISTRADOR ou GERENTE solicita exportação de produtos, THE Sistema_Backoffice SHALL gerar arquivo Excel (.xlsx) contendo todos os produtos ativos com seus respectivos campos fiscais.
9. THE Sistema_Backoffice SHALL organizar Produtos em Categorias e o Sistema_PDV SHALL permitir filtro por Categoria na interface de vendas.
10. IF um ADMINISTRADOR ou GERENTE submete o formulário de cadastro com campos fiscais em formato inválido (NCM diferente de 8 dígitos numéricos ou CFOP diferente de 4 dígitos numéricos), THEN THE Sistema_Backoffice SHALL rejeitar o cadastro e indicar os campos com formato incorreto.

---

### Requisito 4: Controle de Caixa

**User Story:** Como operador do PDV, eu quero abrir e fechar o caixa com controle de valores, para que haja rastreabilidade financeira de todas as operações do dia.

#### Critérios de Aceitação

1. WHEN um Colaborador solicita abertura de Caixa, THE Sistema_PDV SHALL registrar o Colaborador responsável, o valor inicial informado (entre R$ 0,00 e R$ 999.999,99) e o horário de abertura.
2. WHILE não existir um Caixa aberto para o Colaborador logado, THE Sistema_PDV SHALL bloquear todas as operações de venda e exibir mensagem exigindo abertura de caixa.
3. WHEN um Colaborador registra uma Sangria, THE Sistema_PDV SHALL exigir valor (entre R$ 0,01 e R$ 999.999,99) e motivo (mínimo 3 caracteres, máximo 200 caracteres), registrar a movimentação e decrementar o saldo esperado do Caixa.
4. WHEN um Colaborador registra um Suprimento, THE Sistema_PDV SHALL exigir valor (entre R$ 0,01 e R$ 999.999,99) e motivo (mínimo 3 caracteres, máximo 200 caracteres), registrar a movimentação e incrementar o saldo esperado do Caixa.
5. WHEN um Colaborador solicita fechamento de Caixa, THE Sistema_PDV SHALL calcular o saldo esperado (valor inicial + vendas em DINHEIRO + suprimentos - sangrias), solicitar a contagem física do valor em espécie e registrar a diferença entre contagem e saldo esperado.
6. WHEN a diferença absoluta entre saldo esperado e contagem física exceder o valor de tolerância configurado no Sistema_Backoffice (padrão R$ 5,00), THE Sistema_PDV SHALL destacar a diferença em cor vermelha e exigir justificativa do Colaborador (mínimo 10 caracteres).
7. WHEN o fechamento de Caixa é confirmado, THE Sistema_PDV SHALL registrar horário de fechamento, gerar resumo contendo valor inicial, total de vendas por forma de pagamento, total de sangrias, total de suprimentos, saldo esperado, contagem física e diferença, e impedir novas vendas nesse Caixa.
8. THE Sistema_PDV SHALL permitir apenas um Caixa aberto por Colaborador simultaneamente.
9. IF um Colaborador tenta registrar uma Sangria com valor superior ao saldo esperado do Caixa, THEN THE Sistema_PDV SHALL rejeitar a operação e exibir mensagem informando o saldo disponível.
10. IF os dados informados na abertura de Caixa ou em movimentação são inválidos (valor fora do intervalo permitido ou motivo abaixo do mínimo de caracteres), THEN THE Sistema_PDV SHALL rejeitar a operação e exibir mensagem indicando o campo inválido.

---

### Requisito 5: Vendas PDV

**User Story:** Como operador do PDV, eu quero registrar vendas de forma rápida e intuitiva via tela sensível ao toque, para que o atendimento ao cliente seja ágil.

#### Critérios de Aceitação

1. WHEN um Colaborador seleciona um Produto ativo na tela de vendas, THE Sistema_PDV SHALL adicionar o Produto ao carrinho com quantidade 1 e preço de venda vigente (promoPrice se disponível, caso contrário salePrice).
2. WHEN um Colaborador adiciona um Produto já presente no carrinho, THE Sistema_PDV SHALL incrementar a quantidade do item existente em 1 unidade.
3. WHEN um Colaborador confirma a venda, THE Sistema_PDV SHALL exigir seleção de forma de pagamento (DINHEIRO, CREDITO, DEBITO, PIX, COMANDA) e campo CPF opcional do cliente.
4. WHEN uma venda é finalizada com sucesso, THE Sistema_PDV SHALL decrementar o estoque de cada Produto vendido conforme a quantidade do item dentro de uma transação atômica que garanta consistência entre registro da venda e atualização de estoque.
5. WHEN uma venda é finalizada, THE Sistema_PDV SHALL registrar a venda vinculada ao Caixa com status "ABERTO" do Colaborador logado, incluindo subtotal, desconto, total, forma de pagamento, parcelas (se aplicável) e CPF do cliente (se informado).
6. WHEN um Colaborador aplica desconto a uma venda, THE Sistema_PDV SHALL recalcular o total como subtotal menos o valor do desconto, aceitar desconto entre R$ 0,00 e o valor do subtotal, e registrar o valor do desconto na venda.
7. WHEN o pagamento é por CREDITO, THE Sistema_PDV SHALL solicitar o número de parcelas entre 1 e 12.
8. THE Sistema_PDV SHALL exibir layout de três painéis: categorias à esquerda para filtro rápido, produtos no centro com nome, categoria e preço visíveis, e carrinho à direita com subtotal e total, em formato otimizado para toque.
9. WHEN um Colaborador cancela uma venda em andamento, THE Sistema_PDV SHALL limpar o carrinho sem afetar estoque ou registros financeiros.
10. IF o estoque de um Produto é insuficiente para a quantidade solicitada, THEN THE Sistema_PDV SHALL bloquear a adição ao carrinho e exibir mensagem informando o nome do produto e o estoque disponível.
11. IF o Colaborador tenta finalizar uma venda sem Caixa aberto (status "ABERTO"), THEN THE Sistema_PDV SHALL bloquear a operação e exibir mensagem indicando que é necessário abrir o caixa antes de realizar vendas.
12. IF o carrinho está vazio quando o Colaborador tenta finalizar a venda, THEN THE Sistema_PDV SHALL manter o botão de finalização desabilitado e impedir o envio da requisição.

---

### Requisito 6: Gestão de Visitantes

**User Story:** Como operador do PDV, eu quero registrar a entrada de crianças com controle de tempo e consumo, para que o parque mantenha controle de permanência e cobrança.

#### Critérios de Aceitação

1. WHEN um Colaborador registra entrada de Visitante, THE Sistema_PDV SHALL exigir dados do Tutor (nome completo com até 120 caracteres, CPF válido com 11 dígitos, telefone com DDD), dados da Criança (nome completo com até 120 caracteres, data de nascimento) e seleção de Ticket.
2. WHEN o Ticket é selecionado, THE Sistema_PDV SHALL calcular o horário previsto de saída com base na duração do Ticket e registrar a Visita com status ABERTA e pagamento com status PENDENTE.
3. WHILE uma Visita estiver com status ABERTA, THE Sistema_PDV SHALL exibir contador regressivo do tempo restante na tela de visitantes, atualizado a cada 1 segundo.
4. WHEN o tempo restante de uma Visita atingir o limite configurável de minutos antes do vencimento (padrão: 10 minutos), THE Sistema_PDV SHALL emitir alerta visual e sonoro na tela de visitantes.
5. WHEN o tempo restante de uma Visita atingir o limite configurável de minutos antes do vencimento, THE Sistema_PDV SHALL enviar notificação via WhatsApp_API ao telefone do Tutor informando que o tempo está expirando.
6. WHEN o tempo de uma Visita com Ticket de duração fixa (30min, 60min, 120min) expira e a criança permanece no parque, THE Sistema_PDV SHALL iniciar cobrança automática de tempo extra calculada por minuto excedente (valor do Ticket dividido pela duração em minutos do Ticket).
7. WHEN um Colaborador registra consumo de Produto para um Visitante, THE Sistema_PDV SHALL vincular o item à Visita com quantidade e preço unitário, e incrementar o total consumido da Visita.
8. IF o total consumido por um Visitante atinge o Limite_Consumo configurado para a Criança, THEN THE Sistema_PDV SHALL bloquear novos consumos e emitir alerta visual e sonoro.
9. IF o Limite_Consumo não está configurado para a Criança (valor nulo), THEN THE Sistema_PDV SHALL permitir consumos sem restrição de valor.
10. WHEN um Colaborador finaliza a Visita, THE Sistema_PDV SHALL calcular o valor total (ticket + consumo + tempo extra), exigir seleção de forma de pagamento (DINHEIRO, CARTÃO DÉBITO, CARTÃO CRÉDITO ou PIX) e alterar o status da Visita para ENCERRADA.
11. WHEN um Tutor com CPF já cadastrado é informado em nova entrada, THE Sistema_PDV SHALL recuperar automaticamente os dados do Tutor e das Crianças vinculadas.
12. IF o Ticket selecionado é do tipo Day Pass, THEN THE Sistema_PDV SHALL definir o horário previsto de saída como o horário de encerramento do parque no dia e não aplicar cobrança de tempo extra.

---

### Requisito 7: Gestão de Festas

**User Story:** Como gerente do parque, eu quero agendar festas de aniversário com controle de conflitos e pacotes, para que o calendário de eventos seja organizado e sem sobreposições.

#### Critérios de Aceitação

1. WHEN um Colaborador solicita agendamento de Festa, THE Sistema_PDV SHALL exigir nome da criança aniversariante (máximo 100 caracteres), dados do Tutor responsável (nome, CPF, telefone, email, endereço), data, horário (selecionável dentre os slots válidos configurados) e seleção de Pacote_Festa.
2. WHEN uma data e horário são selecionados para agendamento, THE Sistema_PDV SHALL verificar conflitos com festas já confirmadas no mesmo slot de horário e rejeitar o agendamento em caso de sobreposição, exibindo mensagem indicando o conflito e os horários disponíveis para a data selecionada.
3. THE Sistema_PDV SHALL exibir calendário visual mensal com festas confirmadas, diferenciando visualmente datas com todos os slots ocupados, datas com slots parcialmente disponíveis e datas totalmente livres.
4. WHEN uma Festa é confirmada, THE Sistema_PDV SHALL registrar o valor total baseado no Pacote_Festa selecionado aplicando preço de dia de semana (segunda a sexta) ou preço de fim de semana/feriado (sábado, domingo e feriados cadastrados), e definir o status da Festa como CONFIRMADA.
5. WHEN um Colaborador registra pagamento parcial de Festa, THE Sistema_PDV SHALL registrar o valor pago (mínimo R$ 0,01), atualizar o saldo pendente (valor total menos soma dos pagamentos realizados) e exibir o saldo pendente na tela.
6. WHEN um ADMINISTRADOR ou GERENTE cancela uma Festa com status CONFIRMADA, THE Sistema_PDV SHALL exigir motivo de cancelamento (mínimo 10 caracteres), registrar o cancelamento com data/hora e motivo, alterar o status da Festa para CANCELADA e liberar o slot de horário no calendário.
7. WHEN um Colaborador tenta agendar Festa em horário fora dos slots válidos configurados, THE Sistema_PDV SHALL rejeitar o agendamento e exibir a lista de slots disponíveis para a data selecionada.
8. WHEN um ADMINISTRADOR cadastra ou edita um Pacote_Festa no Sistema_Backoffice, THE Sistema_Backoffice SHALL exigir nome (máximo 80 caracteres), número máximo de convidados (1 a 200), preço dia de semana (R$ 0,01 a R$ 99.999,99), preço fim de semana (R$ 0,01 a R$ 99.999,99) e descrição (máximo 500 caracteres).
9. IF um Colaborador tenta confirmar uma Festa e o número de convidados informado excede o número máximo de convidados do Pacote_Festa selecionado, THEN THE Sistema_PDV SHALL rejeitar a confirmação e exibir mensagem indicando a capacidade máxima do pacote.

---

### Requisito 8: Emissão Fiscal

**User Story:** Como operador do PDV, eu quero emitir notas fiscais eletrônicas (NFC-e/NF-e) integradas com a SEFAZ, para que o estabelecimento opere em conformidade com a legislação fiscal.

#### Critérios de Aceitação

1. WHEN uma venda é finalizada e emissão fiscal está habilitada, THE Sistema_PDV SHALL gerar NFC-e via componentes ACBr, assinar digitalmente o XML com o certificado digital configurado e transmitir à SEFAZ, aguardando resposta por no máximo 30 segundos.
2. WHEN a SEFAZ autoriza a NFC-e, THE Sistema_PDV SHALL armazenar o XML autorizado localmente, gerar o DANFE em formato compatível com impressora térmica de 80mm e disponibilizar para impressão automática ou manual.
3. IF a comunicação com a SEFAZ falha durante emissão (timeout ou erro de rede), THEN THE Sistema_PDV SHALL armazenar a nota em contingência offline com status CONTINGÊNCIA, exibir indicação visual ao Colaborador e tentar retransmissão automática a cada 5 minutos quando a conexão for restabelecida, por no máximo 24 horas.
4. WHEN um ADMINISTRADOR ou GERENTE solicita cancelamento de NFC-e emitida há menos de 30 minutos, THE Sistema_PDV SHALL transmitir evento de cancelamento à SEFAZ com justificativa obrigatória de no mínimo 15 caracteres e no máximo 255 caracteres.
5. IF um ADMINISTRADOR ou GERENTE solicita cancelamento de NFC-e emitida há 30 minutos ou mais, THEN THE Sistema_PDV SHALL negar o cancelamento e exibir mensagem informando que o prazo legal de 30 minutos expirou.
6. WHEN um ADMINISTRADOR configura certificado digital no Sistema_Backoffice, THE Sistema_Backoffice SHALL validar o tipo do certificado (A1 ou A3), verificar que a data de validade não está expirada, confirmar leitura da chave privada e armazenar as informações de forma segura.
7. WHEN o certificado digital está a 30 dias ou menos da expiração, THE Sistema_Backoffice SHALL exibir alerta visual ao ADMINISTRADOR a cada login informando a data de vencimento do certificado.
8. THE Sistema_Backoffice SHALL permitir configuração do ambiente SEFAZ (homologação ou produção), série (1 a 999) e número inicial de numeração de notas (1 a 999.999.999).
9. WHEN uma NF-e ou NFC-e é emitida, THE Sistema_PDV SHALL preencher automaticamente os campos fiscais do Produto (NCM, CFOP, CST/CSOSN, alíquotas ICMS/PIS/COFINS) no XML da nota a partir dos dados cadastrados no Produto.
10. IF o certificado digital está expirado no momento da emissão fiscal, THEN THE Sistema_PDV SHALL bloquear a emissão e exibir mensagem informando que o certificado digital precisa ser renovado.

---

### Requisito 9: Relatórios e Indicadores

**User Story:** Como gerente do parque, eu quero visualizar relatórios de vendas, caixa e visitantes, para que eu possa tomar decisões baseadas em dados operacionais.

#### Critérios de Aceitação

1. WHEN um ADMINISTRADOR ou GERENTE solicita relatório de vendas, THE Sistema_Backoffice SHALL gerar relatório com filtros por período (data início e data fim, máximo 365 dias), Colaborador, forma de pagamento e Categoria de produto, exibindo total de vendas, quantidade de transações e valor médio por transação.
2. WHEN um ADMINISTRADOR ou GERENTE solicita relatório de caixa, THE Sistema_Backoffice SHALL exibir resumo de aberturas, fechamentos, sangrias, suprimentos e diferenças (valor esperado vs. contagem física) filtráveis por período e por Colaborador.
3. WHEN um ADMINISTRADOR ou GERENTE solicita relatório de visitantes, THE Sistema_Backoffice SHALL exibir quantidade total de visitas, tempo médio de permanência (em minutos), receita total de consumo e receita média por visitante, filtráveis por período.
4. WHEN um ADMINISTRADOR ou GERENTE acessa o dashboard, THE Sistema_Backoffice SHALL exibir indicadores do dia corrente atualizados a cada acesso: total de vendas em reais, número de visitantes com status ABERTA, quantidade de caixas abertos e quantidade de alertas pendentes (estoque baixo, certificado expirando).
5. WHEN um ADMINISTRADOR ou GERENTE solicita relatório de produtos, THE Sistema_Backoffice SHALL exibir ranking dos 50 produtos mais vendidos por quantidade no período, lista de produtos com estoque atual igual ou abaixo do estoque mínimo e lista de produtos com status inativo.
6. WHEN um ADMINISTRADOR ou GERENTE solicita exportação de relatório, THE Sistema_Backoffice SHALL gerar arquivo no formato selecionado (PDF ou Excel/XLSX) contendo os mesmos dados e filtros aplicados na visualização em tela, em até 30 segundos para relatórios de até 10.000 registros.

---

### Requisito 10: Integração com WhatsApp Business API

**User Story:** Como gerente do parque, eu quero que tutores recebam alertas automáticos via WhatsApp quando o tempo do ticket estiver expirando, para que o atendimento seja proativo.

#### Critérios de Aceitação

1. WHEN o tempo restante de uma Visita atinge o limite configurável de minutos antes do vencimento, THE Sistema_PDV SHALL enviar uma única mensagem via WhatsApp_API ao número do Tutor utilizando template pré-aprovado, incluindo nome da criança e tempo restante.
2. WHEN a WhatsApp_API retorna sucesso no envio, THE Sistema_PDV SHALL registrar a notificação com status ENVIADA, horário de envio e identificador da mensagem retornado pela API.
3. IF a WhatsApp_API retorna erro no envio, THEN THE Sistema_PDV SHALL registrar a notificação com status FALHA e código de erro, exibir indicação visual (ícone de falha) na linha do Visitante na tela de visitantes e não tentar reenvio automático.
4. THE Sistema_Backoffice SHALL permitir configuração do número de minutos antes do vencimento para disparo de alerta (valor entre 1 e 60 minutos, padrão: 10 minutos).
5. THE Sistema_Backoffice SHALL permitir configuração das credenciais da WhatsApp_API (token de acesso, phone number ID e template ID) com validação de campos obrigatórios não vazios.
6. IF as credenciais da WhatsApp_API não estiverem configuradas ou estiverem incompletas, THEN THE Sistema_PDV SHALL suprimir o envio de notificações WhatsApp sem bloquear a operação de visitantes e registrar o evento com status NÃO_CONFIGURADA.

---

### Requisito 11: Integração com ERP Omie

**User Story:** Como administrador, eu quero sincronizar produtos, clientes e notas fiscais com o ERP Omie, para que a gestão financeira e contábil esteja integrada.

#### Critérios de Aceitação

1. WHEN um ADMINISTRADOR solicita sincronização de produtos com ERP_Omie, THE Sistema_Backoffice SHALL enviar produtos novos ou alterados desde a última sincronização via RESTRequest4Delphi, registrar para cada produto o resultado (sucesso ou falha com mensagem de erro) e exibir resumo ao final com total enviado, total com sucesso e total com falha.
2. WHEN um ADMINISTRADOR solicita sincronização de clientes com ERP_Omie, THE Sistema_Backoffice SHALL enviar dados de Tutores cadastrados ou alterados desde a última sincronização e registrar o resultado individual (sucesso ou falha) para cada Tutor.
3. WHEN uma nota fiscal é autorizada pela SEFAZ, THE Sistema_PDV SHALL enviar os dados da nota (número, série, XML, valor total, data de emissão) ao ERP_Omie para conciliação fiscal em até 60 segundos após a autorização.
4. IF a comunicação com ERP_Omie falha durante sincronização (timeout de 30 segundos ou erro de rede), THEN THE Sistema_Backoffice SHALL registrar o erro com data/hora e mensagem, manter os dados locais íntegros sem alteração, marcar os itens pendentes para retentativa e permitir retentativa manual pelo ADMINISTRADOR.
5. THE Sistema_Backoffice SHALL permitir configuração das credenciais do ERP_Omie (app_key, app_secret, endpoint URL) com validação de campos obrigatórios não vazios.
6. IF as credenciais do ERP_Omie não estiverem configuradas, THEN THE Sistema_PDV SHALL suprimir o envio automático de notas fiscais ao ERP_Omie sem bloquear a emissão fiscal.

---

### Requisito 12: Persistência de Dados com FenixORM

**User Story:** Como desenvolvedor, eu quero que toda a persistência de dados utilize o FenixORM no modo local (FireDAC + Firebird), para que o sistema opere de forma confiável em rede local sem dependência de serviços externos.

#### Critérios de Aceitação

1. THE Sistema_PDV SHALL utilizar FenixORM no modo local (FireDAC + Firebird) para todas as operações de persistência, conectando-se ao banco de dados local ou via rede local (IP/porta do servidor Firebird).
2. THE Sistema_PDV SHALL utilizar queries parametrizadas via FenixORM para todas as operações de banco de dados, sem concatenação de valores em strings SQL, prevenindo injeção de SQL.
3. WHEN uma operação de persistência envolve múltiplas entidades relacionadas (ex.: venda com itens, festa com pagamentos), THE Sistema_PDV SHALL utilizar transações explícitas do FenixORM (BeginTransaction/Commit/Rollback) garantindo que todas as entidades sejam persistidas ou nenhuma em caso de falha.
4. THE Sistema_PDV SHALL seguir o padrão arquitetural Model → Controller → DAO (FenixORM) → View (FMX Forms) em todas as implementações, sem acesso direto ao banco de dados a partir das Views.
5. WHEN a conexão com o banco Firebird falha durante uma operação, THE Sistema_PDV SHALL exibir mensagem informando o erro de conexão e permitir que o Colaborador retente a operação.
6. A primeira entrega do sistema SHALL ser um MOCK funcional com dados fictícios em memória (TObjectList) simulando o comportamento do FenixORM, para validação de layout, navegação e fluxos de tela antes da integração com banco de dados real.

---

### Requisito 13: Interface FMX Otimizada para Toque

**User Story:** Como operador do PDV, eu quero uma interface otimizada para tela sensível ao toque com elementos grandes e feedback visual claro, para que a operação seja eficiente em tablets e totens.

#### Critérios de Aceitação

1. THE Sistema_PDV SHALL renderizar botões e elementos interativos com área mínima de toque de 48x48 pixels e espaçamento mínimo de 8 pixels entre elementos interativos adjacentes.
2. THE Sistema_PDV SHALL exibir feedback visual (mudança de cor ou animação de escala) em até 100 milissegundos após qualquer interação de toque.
3. THE Sistema_PDV SHALL adaptar o layout responsivamente para resoluções de 1024x768 até 1920x1080, mantendo todos os elementos interativos acessíveis sem necessidade de rolagem horizontal.
4. WHEN uma operação é concluída com sucesso, THE Sistema_PDV SHALL exibir indicação visual de sucesso (cor verde e ícone de confirmação) por 2 segundos, desaparecendo automaticamente sem exigir interação do usuário.
5. WHEN uma operação resulta em erro, THE Sistema_PDV SHALL exibir mensagem de erro em destaque (cor vermelha) com descrição do problema e ação sugerida para resolução, permanecendo visível até o Colaborador interagir (fechar ou corrigir).
6. THE Sistema_PDV SHALL utilizar tipografia com tamanho mínimo de 14pt para textos informativos e 18pt para rótulos de botões, garantindo legibilidade a uma distância de 50cm da tela.
7. WHEN o estoque de um Produto está abaixo do estoque mínimo configurado, THE Sistema_PDV SHALL exibir indicador visual (badge vermelho com quantidade atual) no card do Produto na tela de vendas.

---

### Requisito 14: Auditoria e Rastreabilidade

**User Story:** Como administrador, eu quero que todas as ações críticas sejam registradas em log de auditoria, para que haja rastreabilidade completa das operações do sistema.

#### Critérios de Aceitação

1. WHEN um Colaborador realiza ação crítica (venda, abertura/fechamento de caixa, sangria, suprimento, cancelamento fiscal, alteração de cadastro, agendamento/cancelamento de festa, alteração de configuração), THE Sistema_PDV SHALL registrar no log de auditoria: identificador do Colaborador, tipo de ação, entidade afetada, identificador da entidade, detalhes da operação (valores anteriores e novos quando aplicável) e data/hora com precisão de segundos.
2. WHEN um ADMINISTRADOR ou GERENTE consulta o log de auditoria, THE Sistema_Backoffice SHALL exibir registros com filtros por Colaborador, tipo de ação, entidade e período (data início e data fim), ordenados por data/hora decrescente, com paginação de 50 registros por página.
3. WHEN um Colaborador recebe negação de acesso a um recurso, THE Sistema_PDV SHALL registrar no log de auditoria: identificador do Colaborador, recurso solicitado, papel atual do Colaborador e data/hora da tentativa.
4. THE Sistema_Backoffice SHALL impedir exclusão ou alteração de registros do log de auditoria por qualquer papel de Colaborador, incluindo ADMINISTRADOR.

---

### Requisito 15: Configurações do Sistema

**User Story:** Como administrador, eu quero gerenciar configurações globais do sistema em um único local, para que parametrizações operacionais sejam ajustadas sem alteração de código.

#### Critérios de Aceitação

1. THE Sistema_Backoffice SHALL permitir configuração do banco de dados: tipo (Firebird ou SQLite), caminho do arquivo (máximo 260 caracteres) e credenciais quando o tipo for Firebird.
2. THE Sistema_Backoffice SHALL permitir configuração do modo de operação do FenixORM (local, cloud ou híbrido) com URL base do servidor (máximo 255 caracteres) e credenciais de autenticação para modo cloud.
3. THE Sistema_Backoffice SHALL permitir configuração dos parâmetros fiscais: ambiente SEFAZ (homologação ou produção), série (1 a 999), certificado digital (arquivo A1 ou dispositivo A3) e CNPJ emitente (14 dígitos com validação de dígito verificador).
4. THE Sistema_Backoffice SHALL permitir configuração dos parâmetros de alerta de visitantes: minutos antes do vencimento para alerta visual no PDV (1 a 60, padrão: 5) e minutos antes do vencimento para notificação WhatsApp (1 a 60, padrão: 10).
5. THE Sistema_Backoffice SHALL permitir configuração do valor de tolerância para diferença de caixa no fechamento (R$ 0,00 a R$ 100,00, padrão: R$ 5,00).
6. WHEN um ADMINISTRADOR altera qualquer configuração do sistema, THE Sistema_Backoffice SHALL validar os novos valores conforme regras de cada parâmetro, registrar a alteração no log de auditoria (valor anterior e novo valor) e aplicar a configuração imediatamente sem necessidade de reiniciar o aplicativo.
