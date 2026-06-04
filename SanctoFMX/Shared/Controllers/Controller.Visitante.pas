unit Controller.Visitante;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.DateUtils,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Visita,
  Model.Entidade.Tutor,
  Model.Entidade.Visitante,
  Model.Entidade.Ticket,
  Model.Entidade.VisitaConsumo,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para gestão de visitantes (crianças) no parque.
  /// Gerencia registro de entrada, controle de tempo, consumo de produtos
  /// vinculados à visita, cálculo de tempo extra e finalização com cobrança total.
  /// </summary>
  TControllerVisitante = class(TControllerBase<TVisita>)
  private
    FDAOTutor: IDAO<TTutor>;
    FDAOVisitante: IDAO<TVisitante>;
    FDAOTicket: IDAO<TTicket>;
    FDAOConsumo: IDAO<TVisitaConsumo>;

    /// <summary>Horário de encerramento do parque para Day Pass (22:00).</summary>
    function GetFimExpediente: TDateTime;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    // --- Registro de Entrada ---

    /// <summary>
    /// Inicia uma nova visita registrando entrada da criança no parque.
    /// Calcula hora prevista de saída com base no ticket selecionado.
    /// Para tickets DAY_PASS, define saída como fim do expediente (22:00).
    /// </summary>
    /// <param name="ATutorId">Id do tutor responsável</param>
    /// <param name="AVisitanteId">Id da criança visitante</param>
    /// <param name="ATicketId">Id do ticket selecionado</param>
    /// <param name="ACaixaId">Id do caixa aberto</param>
    /// <returns>True se a visita foi registrada com sucesso</returns>
    function IniciarVisita(ATutorId, AVisitanteId, ATicketId, ACaixaId: Integer): Boolean;

    // --- Controle de Tempo ---

    /// <summary>
    /// Calcula o valor do tempo extra excedente.
    /// Para DAY_PASS retorna 0. Para tickets com duração fixa, calcula
    /// valor proporcional por minuto excedente (Valor_Ticket / Duracao_Minutos * minutos_extra).
    /// </summary>
    /// <returns>Valor monetário do tempo extra</returns>
    function CalcularTempoExtra: Currency;

    /// <summary>
    /// Retorna os minutos restantes até a hora prevista de saída.
    /// Retorna 0 se já expirou.
    /// </summary>
    function TempoRestanteMinutos: Integer;

    /// <summary>
    /// Verifica se a visita já expirou (hora atual > hora prevista de saída).
    /// </summary>
    function VisitaExpirada: Boolean;

    // --- Consumo ---

    /// <summary>
    /// Registra consumo de um produto vinculado à visita atual.
    /// Incrementa o valor total de consumo da visita.
    /// Verifica o limite de consumo da criança e bloqueia se atingido.
    /// </summary>
    /// <param name="AProdutoId">Id do produto consumido</param>
    /// <param name="AQuantidade">Quantidade consumida</param>
    /// <param name="APrecoUnitario">Preço unitário do produto</param>
    /// <returns>True se consumo registrado com sucesso</returns>
    function RegistrarConsumo(AProdutoId: Integer; AQuantidade: Integer;
      APrecoUnitario: Currency): Boolean;

    // --- Finalização ---

    /// <summary>
    /// Finaliza a visita calculando valor total (ticket + consumo + tempo extra),
    /// registrando forma de pagamento e alterando status para ENCERRADA.
    /// </summary>
    /// <param name="AFormaPagamento">Forma de pagamento (DINHEIRO, DEBITO, CREDITO, PIX)</param>
    /// <returns>True se finalizada com sucesso</returns>
    function FinalizarVisita(const AFormaPagamento: string): Boolean;

    // --- Consultas ---

    /// <summary>
    /// Busca um tutor pelo CPF. Retorna nil se não encontrado.
    /// </summary>
    /// <param name="ACPF">CPF do tutor (11 dígitos)</param>
    /// <returns>Instância de TTutor ou nil</returns>
    function BuscarTutorPorCPF(const ACPF: string): TTutor;

    /// <summary>
    /// Retorna todas as visitas com status ABERTA.
    /// </summary>
    /// <returns>Lista de visitas abertas (caller é responsável por liberar)</returns>
    function VisitasAbertas: TObjectList<TVisita>;

    // --- Validação (requerida por TControllerBase) ---

    /// <summary>
    /// Valida os dados mínimos da visita antes de gravar.
    /// </summary>
    function Validar: Boolean; override;

    // --- Properties ---

    /// <summary>DAO de Tutor para consultas de responsáveis.</summary>
    property DAOTutor: IDAO<TTutor> read FDAOTutor;

    /// <summary>DAO de Visitante para consultas de crianças.</summary>
    property DAOVisitante: IDAO<TVisitante> read FDAOVisitante;

    /// <summary>DAO de Ticket para consultas de ingressos.</summary>
    property DAOTicket: IDAO<TTicket> read FDAOTicket;

    /// <summary>DAO de Consumo para registro de itens consumidos.</summary>
    property DAOConsumo: IDAO<TVisitaConsumo> read FDAOConsumo;
  end;

implementation

{ TControllerVisitante }

constructor TControllerVisitante.Create;
begin
  inherited Create;
  FDAOTutor := TMockDAO<TTutor>.Create;
  FDAOVisitante := TMockDAO<TVisitante>.Create;
  FDAOTicket := TMockDAO<TTicket>.Create;
  FDAOConsumo := TMockDAO<TVisitaConsumo>.Create;
end;

destructor TControllerVisitante.Destroy;
begin
  // Interfaces são liberadas por reference counting
  inherited Destroy;
end;

function TControllerVisitante.GetFimExpediente: TDateTime;
begin
  // Horário de encerramento do parque: 22:00 do dia atual
  Result := DateOf(Now) + EncodeTime(22, 0, 0, 0);
end;

function TControllerVisitante.IniciarVisita(ATutorId, AVisitanteId, ATicketId,
  ACaixaId: Integer): Boolean;
var
  LTicket: TTicket;
begin
  Result := False;

  // Validar parâmetros obrigatórios
  if ATutorId <= 0 then
    raise EValidacaoException.Create('Tutor', 'Tutor é obrigatório.');

  if AVisitanteId <= 0 then
    raise EValidacaoException.Create('Visitante', 'Visitante (criança) é obrigatório.');

  if ATicketId <= 0 then
    raise EValidacaoException.Create('Ticket', 'Ticket é obrigatório.');

  if ACaixaId <= 0 then
    raise EValidacaoException.Create('Caixa', 'Caixa é obrigatório.');

  // Buscar ticket para calcular duração e preço
  LTicket := FDAOTicket.Find(ATicketId);
  try
    if not Assigned(LTicket) then
      raise EValidacaoException.Create('Ticket', 'Ticket não encontrado.');

    // Configurar entidade TVisita
    Entidade.Tutor_Id := ATutorId;
    Entidade.Visitante_Id := AVisitanteId;
    Entidade.Ticket_Id := ATicketId;
    Entidade.Caixa_Id := ACaixaId;
    Entidade.Hora_Entrada := Now;
    Entidade.Valor_Ticket := LTicket.Preco;
    Entidade.Valor_Consumo := 0;
    Entidade.Valor_Tempo_Extra := 0;
    Entidade.Valor_Total := 0;
    Entidade.Status := 'ABERTA';
    Entidade.Status_Pagamento := 'PENDENTE';

    // Calcular hora prevista de saída
    if SameText(LTicket.Tipo, 'DAY_PASS') then
      Entidade.Hora_Prevista_Saida := GetFimExpediente
    else
      Entidade.Hora_Prevista_Saida := Now + (LTicket.Duracao_Minutos / (24 * 60));

    // Gravar visita via DAO herdado
    Result := inherited Gravar;

    if Result then
    begin
      RegistrarAuditoria('INSERT', 'VISITA', Entidade.Id,
        Format('Visita iniciada. Visitante: %d, Tutor: %d, Ticket: %s',
          [AVisitanteId, ATutorId, LTicket.Nome]));
    end;
  finally
    LTicket.Free;
  end;
end;

function TControllerVisitante.CalcularTempoExtra: Currency;
var
  LTicket: TTicket;
  LMinutosExtra: Integer;
  LValorPorMinuto: Currency;
begin
  Result := 0;

  // Buscar ticket vinculado à visita
  LTicket := FDAOTicket.Find(Entidade.Ticket_Id);
  try
    if not Assigned(LTicket) then
      Exit;

    // DAY_PASS não cobra tempo extra
    if SameText(LTicket.Tipo, 'DAY_PASS') then
      Exit;

    // Verificar se expirou
    if Now <= Entidade.Hora_Prevista_Saida then
      Exit;

    // Calcular minutos excedentes
    LMinutosExtra := MinutesBetween(Now, Entidade.Hora_Prevista_Saida);

    // Valor por minuto = Valor_Ticket / Duracao_Minutos
    if LTicket.Duracao_Minutos > 0 then
    begin
      LValorPorMinuto := Entidade.Valor_Ticket / LTicket.Duracao_Minutos;
      Result := LMinutosExtra * LValorPorMinuto;
    end;
  finally
    LTicket.Free;
  end;
end;

function TControllerVisitante.TempoRestanteMinutos: Integer;
begin
  if Now >= Entidade.Hora_Prevista_Saida then
    Result := 0
  else
    Result := MinutesBetween(Entidade.Hora_Prevista_Saida, Now);
end;

function TControllerVisitante.VisitaExpirada: Boolean;
begin
  Result := Now > Entidade.Hora_Prevista_Saida;
end;

function TControllerVisitante.RegistrarConsumo(AProdutoId: Integer;
  AQuantidade: Integer; APrecoUnitario: Currency): Boolean;
var
  LConsumo: TVisitaConsumo;
  LSubtotalConsumo: Currency;
  LVisitante: TVisitante;
  LNovoTotalConsumo: Currency;
begin
  Result := False;

  // Validações
  if AProdutoId <= 0 then
    raise EValidacaoException.Create('Produto', 'Produto é obrigatório.');

  if AQuantidade <= 0 then
    raise EValidacaoException.Create('Quantidade', 'Quantidade deve ser maior que zero.');

  if APrecoUnitario <= 0 then
    raise EValidacaoException.Create('Preco', 'Preço unitário deve ser maior que zero.');

  // Calcular subtotal do consumo
  LSubtotalConsumo := AQuantidade * APrecoUnitario;
  LNovoTotalConsumo := Entidade.Valor_Consumo + LSubtotalConsumo;

  // Verificar limite de consumo da criança
  LVisitante := FDAOVisitante.Find(Entidade.Visitante_Id);
  try
    if Assigned(LVisitante) and (LVisitante.Limite_Consumo > 0) then
    begin
      if LNovoTotalConsumo >= LVisitante.Limite_Consumo then
        raise EValidacaoException.Create('Consumo',
          Format('Limite de consumo atingido (R$ %.2f). Consumo bloqueado.',
            [LVisitante.Limite_Consumo]));
    end;
  finally
    LVisitante.Free;
  end;

  // Criar registro de consumo
  LConsumo := TVisitaConsumo.Create;
  try
    LConsumo.Visita_Id := Entidade.Id;
    LConsumo.Produto_Id := AProdutoId;
    LConsumo.Quantidade := AQuantidade;
    LConsumo.Preco_Unitario := APrecoUnitario;
    LConsumo.Subtotal := LSubtotalConsumo;
    LConsumo.Data_Hora := Now;

    Result := FDAOConsumo.Save(LConsumo);

    if Result then
    begin
      // Incrementar valor consumo na visita
      Entidade.Valor_Consumo := LNovoTotalConsumo;
      // Atualizar a visita no DAO
      DAO.Update(Entidade);
    end;
  finally
    LConsumo.Free;
  end;
end;

function TControllerVisitante.FinalizarVisita(const AFormaPagamento: string): Boolean;
begin
  Result := False;

  // Validar forma de pagamento
  if Trim(AFormaPagamento) = '' then
    raise EValidacaoException.Create('Forma_Pagamento', 'Forma de pagamento é obrigatória.');

  // Validar status da visita
  if not SameText(Entidade.Status, 'ABERTA') then
    raise EValidacaoException.Create('Status', 'Somente visitas com status ABERTA podem ser finalizadas.');

  // Calcular tempo extra
  Entidade.Valor_Tempo_Extra := CalcularTempoExtra;

  // Calcular valor total: ticket + consumo + tempo extra
  Entidade.Valor_Total := Entidade.Valor_Ticket + Entidade.Valor_Consumo + Entidade.Valor_Tempo_Extra;

  // Atualizar status e dados de saída
  Entidade.Status := 'ENCERRADA';
  Entidade.Status_Pagamento := 'PAGO';
  Entidade.Forma_Pagamento := AFormaPagamento;
  Entidade.Hora_Saida_Real := Now;

  // Persistir via DAO
  Result := DAO.Update(Entidade);

  if Result then
  begin
    RegistrarAuditoria('UPDATE', 'VISITA', Entidade.Id,
      Format('Visita finalizada. Total: R$ %.2f (Ticket: R$ %.2f + Consumo: R$ %.2f + Extra: R$ %.2f). Pagamento: %s',
        [Entidade.Valor_Total, Entidade.Valor_Ticket, Entidade.Valor_Consumo,
         Entidade.Valor_Tempo_Extra, AFormaPagamento]));
  end;
end;

function TControllerVisitante.BuscarTutorPorCPF(const ACPF: string): TTutor;
var
  LTutores: TObjectList<TTutor>;
begin
  Result := nil;

  if Trim(ACPF) = '' then
    Exit;

  // Buscar tutor usando filtro Where por CPF
  LTutores := FDAOTutor.Where('CPF', ACPF).FindAll;
  try
    if LTutores.Count > 0 then
    begin
      // Retorna clone do primeiro encontrado (caller é responsável por liberar)
      Result := TTutor.Create;
      Result.Id := LTutores[0].Id;
      Result.Nome := LTutores[0].Nome;
      Result.CPF := LTutores[0].CPF;
      Result.Telefone := LTutores[0].Telefone;
      Result.Email := LTutores[0].Email;
      Result.Endereco := LTutores[0].Endereco;
    end;
  finally
    LTutores.Free;
  end;
end;

function TControllerVisitante.VisitasAbertas: TObjectList<TVisita>;
begin
  // Retorna todas as visitas com status ABERTA
  Result := DAO.Where('Status', 'ABERTA').FindAll;
end;

function TControllerVisitante.Validar: Boolean;
begin
  Result := False;

  if Entidade.Tutor_Id <= 0 then
    raise EValidacaoException.Create('Tutor', 'Tutor é obrigatório.');

  if Entidade.Visitante_Id <= 0 then
    raise EValidacaoException.Create('Visitante', 'Visitante (criança) é obrigatório.');

  if Entidade.Ticket_Id <= 0 then
    raise EValidacaoException.Create('Ticket', 'Ticket é obrigatório.');

  if Entidade.Caixa_Id <= 0 then
    raise EValidacaoException.Create('Caixa', 'Caixa é obrigatório.');

  Result := True;
end;

end.
