unit Controller.Festa;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Festa,
  Model.Entidade.PacoteFesta,
  Model.Entidade.FestaPagamento,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para gestão de festas de aniversário.
  /// Gerencia agendamento com validação de conflitos de slot,
  /// cálculo de preço baseado no dia da semana, pagamentos parciais,
  /// cancelamento com motivo obrigatório e consulta de disponibilidade.
  /// </summary>
  TControllerFesta = class(TControllerBase<TFesta>)
  private
    FDAOPacote: IDAO<TPacoteFesta>;
    FDAOPagamento: IDAO<TFestaPagamento>;
    FDAOFesta: IDAO<TFesta>;

    /// <summary>
    /// Verifica se a data informada é feriado.
    /// Por padrão retorna False (feriados devem ser cadastrados em configuração).
    /// Pode ser sobrescrito para integrar com tabela de feriados.
    /// </summary>
    function IsFeriado(AData: TDate): Boolean; virtual;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    // --- Agendamento ---

    /// <summary>
    /// Agenda uma festa validando dados obrigatórios, conflitos de slot,
    /// capacidade do pacote e calculando preço baseado no dia da semana.
    /// A entidade (Entidade) deve estar preenchida com:
    ///   Nome_Aniversariante, Tutor_Id, Data_Festa, Horario_Slot,
    ///   Pacote_Id e Num_Convidados.
    /// Retorna True se agendamento foi realizado com sucesso.
    /// </summary>
    function AgendarFesta: Boolean;

    /// <summary>
    /// Verifica se existe conflito de slot para a data e horário informados.
    /// Retorna True se há uma festa CONFIRMADA no mesmo date+slot.
    /// </summary>
    function VerificarConflitoSlot(AData: TDate; const ASlot: string): Boolean;

    /// <summary>
    /// Valida se o slot informado é válido para a data.
    /// Slots válidos dias úteis (Seg-Sáb): "14:00 às 16:30", "19:00 às 21:30"
    /// Slots válidos domingos/feriados: "15:30 às 18:00"
    /// Retorna True se o slot é válido para a data informada.
    /// </summary>
    function ValidarHorarioSlot(const ASlot: string; AData: TDate): Boolean;

    /// <summary>
    /// Calcula o preço da festa baseado no pacote e no dia da semana.
    /// Seg-Sex (DayOfWeek 2-6) = Preco_Semana
    /// Sáb-Dom (DayOfWeek 1,7) ou feriado = Preco_FDS
    /// </summary>
    function CalcularPrecoFesta(APacoteId: Integer; AData: TDate): Currency;

    // --- Pagamentos ---

    /// <summary>
    /// Registra um pagamento parcial para a festa atual.
    /// Valida valor > 0, cria TFestaPagamento, atualiza Valor_Pago e Saldo_Pendente.
    /// </summary>
    function RegistrarPagamento(AValor: Currency; const AFormaPagamento: string): Boolean;

    // --- Cancelamento ---

    /// <summary>
    /// Cancela a festa atual exigindo motivo com mínimo 10 caracteres.
    /// Altera Status para 'CANCELADA', registra motivo e data de cancelamento,
    /// e libera o slot no calendário.
    /// </summary>
    function CancelarFesta(const AMotivo: string): Boolean;

    // --- Consultas ---

    /// <summary>
    /// Retorna todas as festas do mês/ano informados.
    /// </summary>
    function FestasDoMes(AMes, AAno: Integer): TObjectList<TFesta>;

    /// <summary>
    /// Retorna os slots disponíveis (não ocupados por festas CONFIRMADAS) para a data.
    /// </summary>
    function SlotsDisponiveisData(AData: TDate): TArray<string>;

    // --- Validação (TControllerBase) ---

    /// <summary>
    /// Valida os dados básicos da entidade Festa.
    /// </summary>
    function Validar: Boolean; override;

    // --- Properties ---

    /// <summary>DAO de PacoteFesta para consultas de pacotes.</summary>
    property DAOPacote: IDAO<TPacoteFesta> read FDAOPacote;

    /// <summary>DAO de FestaPagamento para registro de pagamentos.</summary>
    property DAOPagamento: IDAO<TFestaPagamento> read FDAOPagamento;

    /// <summary>DAO de Festa para consultas de conflitos e listagens.</summary>
    property DAOFesta: IDAO<TFesta> read FDAOFesta;
  end;

implementation

{ TControllerFesta }

constructor TControllerFesta.Create;
begin
  inherited Create;
  FDAOPacote := TMockDAO<TPacoteFesta>.Create;
  FDAOPagamento := TMockDAO<TFestaPagamento>.Create;
  FDAOFesta := TMockDAO<TFesta>.Create;
end;

destructor TControllerFesta.Destroy;
begin
  // Interfaces são liberadas por reference counting
  inherited Destroy;
end;

function TControllerFesta.IsFeriado(AData: TDate): Boolean;
begin
  // TODO: Integrar com tabela de feriados cadastrados em CONFIGURACAO
  // Por enquanto retorna False (apenas domingos são tratados como FDS)
  Result := False;
end;

function TControllerFesta.Validar: Boolean;
begin
  Result := False;

  if Trim(Entidade.Nome_Aniversariante) = '' then
    raise EValidacaoException.Create('Nome_Aniversariante',
      'Nome do aniversariante é obrigatório.');

  if Length(Entidade.Nome_Aniversariante) > 100 then
    raise EValidacaoException.Create('Nome_Aniversariante',
      'Nome do aniversariante deve ter no máximo 100 caracteres.');

  if Entidade.Tutor_Id <= 0 then
    raise EValidacaoException.Create('Tutor_Id',
      'Tutor responsável é obrigatório.');

  if Entidade.Data_Festa = 0 then
    raise EValidacaoException.Create('Data_Festa',
      'Data da festa é obrigatória.');

  if Trim(Entidade.Horario_Slot) = '' then
    raise EValidacaoException.Create('Horario_Slot',
      'Horário (slot) da festa é obrigatório.');

  if Entidade.Pacote_Id <= 0 then
    raise EValidacaoException.Create('Pacote_Id',
      'Pacote de festa é obrigatório.');

  Result := True;
end;

function TControllerFesta.AgendarFesta: Boolean;
var
  LPacote: TPacoteFesta;
  LPreco: Currency;
begin
  Result := False;

  // 1. Validar dados obrigatórios
  Validar;

  // 2. Validar horário contra slots configurados
  if not ValidarHorarioSlot(Entidade.Horario_Slot, Entidade.Data_Festa) then
    raise EValidacaoException.Create('Horario_Slot',
      'Horário informado não é válido para a data selecionada. ' +
      'Consulte os slots disponíveis.');

  // 3. Verificar conflito de slot (mesmo date + slot com festa CONFIRMADA)
  if VerificarConflitoSlot(Entidade.Data_Festa, Entidade.Horario_Slot) then
    raise EValidacaoException.Create('Horario_Slot',
      'Já existe uma festa confirmada neste horário. ' +
      'Selecione outro slot ou data disponível.');

  // 4. Buscar pacote e validar capacidade
  LPacote := FDAOPacote.Find(Entidade.Pacote_Id);
  if not Assigned(LPacote) then
    raise EValidacaoException.Create('Pacote_Id',
      'Pacote de festa não encontrado.');
  try
    if Entidade.Num_Convidados > LPacote.Max_Convidados then
      raise EValidacaoException.Create('Num_Convidados',
        Format('Número de convidados (%d) excede a capacidade máxima do pacote (%d).',
          [Entidade.Num_Convidados, LPacote.Max_Convidados]));
  finally
    LPacote.Free;
  end;

  // 5. Calcular preço baseado no dia da semana
  LPreco := CalcularPrecoFesta(Entidade.Pacote_Id, Entidade.Data_Festa);
  Entidade.Valor_Total := LPreco;
  Entidade.Valor_Pago := 0;
  Entidade.Saldo_Pendente := LPreco;

  // 6. Definir status como CONFIRMADA
  Entidade.Status := 'CONFIRMADA';

  // 7. Persistir a festa
  if not FDAOFesta.Save(Entidade) then
    Exit;

  // Atualizar Id na entidade após insert
  if Entidade.Id = 0 then
    Entidade.Id := FDAOFesta.LastId;

  // 8. Registrar auditoria
  RegistrarAuditoria('INSERT', 'FESTA', Entidade.Id,
    Format('Festa agendada. Aniversariante: %s, Data: %s, Slot: %s, Pacote: %d, Valor: R$ %.2f',
      [Entidade.Nome_Aniversariante,
       DateToStr(Entidade.Data_Festa),
       Entidade.Horario_Slot,
       Entidade.Pacote_Id,
       Entidade.Valor_Total]));

  Result := True;
end;

function TControllerFesta.VerificarConflitoSlot(AData: TDate; const ASlot: string): Boolean;
var
  LFestas: TObjectList<TFesta>;
  I: Integer;
begin
  Result := False;

  // Buscar festas com status CONFIRMADA
  LFestas := FDAOFesta.Where('Status', 'CONFIRMADA').FindAll;
  try
    for I := 0 to LFestas.Count - 1 do
    begin
      if (LFestas[I].Data_Festa = AData) and
         SameText(LFestas[I].Horario_Slot, ASlot) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    LFestas.Free;
  end;
end;

function TControllerFesta.ValidarHorarioSlot(const ASlot: string; AData: TDate): Boolean;
var
  LDiaSemana: Word;
  LSlotsDiaUtil: TArray<string>;
  LSlotsDomFeriado: TArray<string>;
  LSlotsValidos: TArray<string>;
  I: Integer;
begin
  Result := False;

  // Slots válidos para dias úteis (Segunda a Sábado)
  LSlotsDiaUtil := TArray<string>.Create(
    '14:00 às 16:30',
    '19:00 às 21:30'
  );

  // Slots válidos para Domingo e Feriados
  LSlotsDomFeriado := TArray<string>.Create(
    '15:30 às 18:00'
  );

  // DayOfWeek: 1=Domingo, 2=Segunda, ..., 7=Sábado
  LDiaSemana := DayOfWeek(AData);

  if (LDiaSemana = 1) or IsFeriado(AData) then
    LSlotsValidos := LSlotsDomFeriado
  else
    LSlotsValidos := LSlotsDiaUtil;

  for I := Low(LSlotsValidos) to High(LSlotsValidos) do
  begin
    if SameText(LSlotsValidos[I], ASlot) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TControllerFesta.CalcularPrecoFesta(APacoteId: Integer; AData: TDate): Currency;
var
  LPacote: TPacoteFesta;
  LDiaSemana: Word;
begin
  Result := 0;

  LPacote := FDAOPacote.Find(APacoteId);
  if not Assigned(LPacote) then
    raise EValidacaoException.Create('Pacote_Id', 'Pacote de festa não encontrado.');
  try
    // DayOfWeek: 1=Domingo, 2=Segunda, 3=Terça, ..., 6=Sexta, 7=Sábado
    LDiaSemana := DayOfWeek(AData);

    if (LDiaSemana >= 2) and (LDiaSemana <= 6) and (not IsFeriado(AData)) then
      // Segunda a Sexta (dias úteis sem feriado) = Preco_Semana
      Result := LPacote.Preco_Semana
    else
      // Sábado (7), Domingo (1) ou Feriado = Preco_FDS
      Result := LPacote.Preco_FDS;
  finally
    LPacote.Free;
  end;
end;

function TControllerFesta.RegistrarPagamento(AValor: Currency; const AFormaPagamento: string): Boolean;
var
  LPagamento: TFestaPagamento;
begin
  Result := False;

  // Validar valor positivo
  if AValor <= 0 then
    raise EValidacaoException.Create('Valor',
      'Valor do pagamento deve ser maior que zero.');

  // Validar forma de pagamento
  if Trim(AFormaPagamento) = '' then
    raise EValidacaoException.Create('Forma_Pagamento',
      'Forma de pagamento é obrigatória.');

  // Validar que festa está confirmada
  if not SameText(Entidade.Status, 'CONFIRMADA') then
    raise EValidacaoException.Create('Status',
      'Só é possível registrar pagamento para festas com status CONFIRMADA.');

  // Criar registro de pagamento
  LPagamento := TFestaPagamento.Create;
  try
    LPagamento.Festa_Id := Entidade.Id;
    LPagamento.Valor := AValor;
    LPagamento.Forma_Pagamento := AFormaPagamento;
    LPagamento.Data_Hora := Now;

    if not FDAOPagamento.Save(LPagamento) then
      Exit;
  finally
    LPagamento.Free;
  end;

  // Atualizar valores na entidade
  Entidade.Valor_Pago := Entidade.Valor_Pago + AValor;
  Entidade.Saldo_Pendente := Entidade.Valor_Total - Entidade.Valor_Pago;

  // Persistir atualização da festa
  FDAOFesta.Save(Entidade);

  Result := True;
end;

function TControllerFesta.CancelarFesta(const AMotivo: string): Boolean;
begin
  Result := False;

  // Validar motivo (mínimo 10 caracteres)
  if Length(Trim(AMotivo)) < 10 then
    raise EValidacaoException.Create('Motivo_Cancelamento',
      'Motivo de cancelamento deve ter no mínimo 10 caracteres.');

  // Validar que festa está confirmada
  if not SameText(Entidade.Status, 'CONFIRMADA') then
    raise EValidacaoException.Create('Status',
      'Só é possível cancelar festas com status CONFIRMADA.');

  // Atualizar status e dados de cancelamento
  Entidade.Status := 'CANCELADA';
  Entidade.Motivo_Cancelamento := Trim(AMotivo);
  Entidade.Data_Cancelamento := Now;

  // Persistir cancelamento
  if not FDAOFesta.Save(Entidade) then
    Exit;

  // Registrar auditoria
  RegistrarAuditoria('CANCELAMENTO', 'FESTA', Entidade.Id,
    Format('Festa cancelada. Aniversariante: %s, Data: %s, Motivo: %s',
      [Entidade.Nome_Aniversariante,
       DateToStr(Entidade.Data_Festa),
       AMotivo]));

  Result := True;
end;

function TControllerFesta.FestasDoMes(AMes, AAno: Integer): TObjectList<TFesta>;
var
  LTodasFestas: TObjectList<TFesta>;
  I: Integer;
  LFesta: TFesta;
  LAno, LMes, LDia: Word;
  LClone: TFesta;
begin
  Result := TObjectList<TFesta>.Create(True);

  LTodasFestas := FDAOFesta.FindAll;
  try
    for I := 0 to LTodasFestas.Count - 1 do
    begin
      LFesta := LTodasFestas[I];
      DecodeDate(LFesta.Data_Festa, LAno, LMes, LDia);
      if (LMes = AMes) and (LAno = AAno) then
      begin
        // Criar clone para adicionar à lista resultado
        LClone := TFesta.Create;
        LClone.Id := LFesta.Id;
        LClone.Nome_Aniversariante := LFesta.Nome_Aniversariante;
        LClone.Tutor_Id := LFesta.Tutor_Id;
        LClone.Pacote_Id := LFesta.Pacote_Id;
        LClone.Data_Festa := LFesta.Data_Festa;
        LClone.Horario_Slot := LFesta.Horario_Slot;
        LClone.Num_Convidados := LFesta.Num_Convidados;
        LClone.Valor_Total := LFesta.Valor_Total;
        LClone.Valor_Pago := LFesta.Valor_Pago;
        LClone.Saldo_Pendente := LFesta.Saldo_Pendente;
        LClone.Status := LFesta.Status;
        LClone.Motivo_Cancelamento := LFesta.Motivo_Cancelamento;
        LClone.Data_Cancelamento := LFesta.Data_Cancelamento;
        Result.Add(LClone);
      end;
    end;
  finally
    LTodasFestas.Free;
  end;
end;

function TControllerFesta.SlotsDisponiveisData(AData: TDate): TArray<string>;
var
  LDiaSemana: Word;
  LTodosSlots: TArray<string>;
  LSlotsDisponiveis: TList<string>;
  I: Integer;
begin
  // Determinar todos os slots válidos para a data
  LDiaSemana := DayOfWeek(AData);

  if (LDiaSemana = 1) or IsFeriado(AData) then
    LTodosSlots := TArray<string>.Create('15:30 às 18:00')
  else
    LTodosSlots := TArray<string>.Create('14:00 às 16:30', '19:00 às 21:30');

  // Filtrar slots que não estão ocupados
  LSlotsDisponiveis := TList<string>.Create;
  try
    for I := Low(LTodosSlots) to High(LTodosSlots) do
    begin
      if not VerificarConflitoSlot(AData, LTodosSlots[I]) then
        LSlotsDisponiveis.Add(LTodosSlots[I]);
    end;

    Result := LSlotsDisponiveis.ToArray;
  finally
    LSlotsDisponiveis.Free;
  end;
end;

end.
