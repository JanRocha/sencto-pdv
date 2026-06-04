unit Controller.Caixa;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Caixa,
  Model.Entidade.MovimentacaoCaixa,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para gestão de Caixa (abertura, movimentações, fechamento).
  /// Implementa regras de negócio:
  /// - Apenas um caixa aberto por colaborador
  /// - Validação de valores (0-999999.99 para abertura, 0.01-999999.99 para movimentações)
  /// - Sangria não pode exceder saldo esperado
  /// - Fechamento com reconciliação (contagem física vs saldo esperado)
  /// - Justificativa obrigatória se diferença > tolerância (padrão R$5,00)
  /// - Bloqueio de vendas sem caixa aberto
  /// </summary>
  TControllerCaixa = class(TControllerBase<TCaixa>)
  private
    FDAOMovimentacao: IDAO<TMovimentacaoCaixa>;
    FMovimentacoes: TObjectList<TMovimentacaoCaixa>;
    FTolerancia: Currency;

    /// <summary>Carrega movimentações do caixa atual a partir do DAO.</summary>
    procedure CarregarMovimentacoes;
  public
    constructor Create; overload;
    constructor Create(const AId: Integer); overload;
    destructor Destroy; override;

    /// <summary>
    /// Tolerância para diferença no fechamento de caixa.
    /// Se abs(diferença) > tolerância, justificativa é obrigatória.
    /// Padrão: R$ 5,00.
    /// </summary>
    property Tolerancia: Currency read FTolerancia write FTolerancia;

    /// <summary>
    /// Lista de movimentações do caixa atual (somente leitura).
    /// </summary>
    property Movimentacoes: TObjectList<TMovimentacaoCaixa> read FMovimentacoes;

    /// <summary>
    /// DAO de movimentações (para acesso externo se necessário).
    /// </summary>
    property DAOMovimentacao: IDAO<TMovimentacaoCaixa> read FDAOMovimentacao;

    /// <summary>
    /// Valida a entidade Caixa antes de gravar diretamente.
    /// Para operações normais, usar AbrirCaixa/FecharCaixa.
    /// </summary>
    function Validar: Boolean; override;

    /// <summary>
    /// Abre um novo caixa para o colaborador informado.
    /// - Valida valor_inicial: 0 a 999999.99
    /// - Verifica que não existe outro caixa aberto para este colaborador
    /// - Cria TCaixa com Status='ABERTO', registra auditoria
    /// </summary>
    /// <param name="AValorInicial">Valor inicial do caixa (R$ 0,00 a R$ 999.999,99)</param>
    /// <param name="AColaboradorId">Id do colaborador que está abrindo o caixa</param>
    /// <returns>True se o caixa foi aberto com sucesso</returns>
    function AbrirCaixa(AValorInicial: Currency; AColaboradorId: Integer): Boolean;

    /// <summary>
    /// Registra uma sangria (retirada) no caixa aberto.
    /// - Valida valor: 0.01 a 999999.99
    /// - Valida motivo: 3 a 200 caracteres
    /// - Verifica que valor <= saldo esperado
    /// - Cria TMovimentacaoCaixa com Tipo='SANGRIA', registra auditoria
    /// </summary>
    /// <param name="AValor">Valor da sangria (R$ 0,01 a R$ 999.999,99)</param>
    /// <param name="AMotivo">Motivo da sangria (3 a 200 caracteres)</param>
    /// <returns>True se a sangria foi registrada com sucesso</returns>
    function RegistrarSangria(AValor: Currency; const AMotivo: string): Boolean;

    /// <summary>
    /// Registra um suprimento (adição) no caixa aberto.
    /// - Valida valor: 0.01 a 999999.99
    /// - Valida motivo: 3 a 200 caracteres
    /// - Cria TMovimentacaoCaixa com Tipo='SUPRIMENTO', registra auditoria
    /// </summary>
    /// <param name="AValor">Valor do suprimento (R$ 0,01 a R$ 999.999,99)</param>
    /// <param name="AMotivo">Motivo do suprimento (3 a 200 caracteres)</param>
    /// <returns>True se o suprimento foi registrado com sucesso</returns>
    function RegistrarSuprimento(AValor: Currency; const AMotivo: string): Boolean;

    /// <summary>
    /// Fecha o caixa atual com reconciliação financeira.
    /// - Calcula saldo esperado
    /// - Calcula diferença = contagem_fisica - saldo_esperado
    /// - Se abs(diferença) > tolerância, exige justificativa (mín. 10 chars)
    /// - Atualiza TCaixa com Status='FECHADO', registra auditoria
    /// </summary>
    /// <param name="AContagemFisica">Valor contado fisicamente no caixa</param>
    /// <param name="AJustificativa">Justificativa para diferença (obrigatória se > tolerância)</param>
    /// <returns>True se o caixa foi fechado com sucesso</returns>
    function FecharCaixa(AContagemFisica: Currency; const AJustificativa: string): Boolean;

    /// <summary>
    /// Calcula o saldo esperado do caixa:
    /// valor_inicial + Σ(suprimentos) - Σ(sangrias)
    /// Nota: vendas em dinheiro serão adicionadas quando Controller.Venda estiver disponível.
    /// Para o mock, mantém total corrente baseado nas movimentações internas.
    /// </summary>
    /// <returns>Saldo esperado calculado</returns>
    function CalcularSaldoEsperado: Currency;

    /// <summary>
    /// Retorna o caixa aberto do colaborador informado, ou nil se não houver.
    /// O chamador é responsável por liberar o objeto retornado.
    /// </summary>
    /// <param name="AColaboradorId">Id do colaborador</param>
    /// <returns>Instância de TCaixa com Status='ABERTO' ou nil</returns>
    function CaixaAberto(AColaboradorId: Integer): TCaixa;

    /// <summary>
    /// Verifica se existe caixa aberto para o colaborador informado.
    /// </summary>
    /// <param name="AColaboradorId">Id do colaborador</param>
    /// <returns>True se existe caixa com Status='ABERTO'</returns>
    function ExisteCaixaAberto(AColaboradorId: Integer): Boolean;
  end;

implementation

{ TControllerCaixa }

constructor TControllerCaixa.Create;
begin
  inherited Create;
  FDAOMovimentacao := TMockDAO<TMovimentacaoCaixa>.Create;
  FMovimentacoes := TObjectList<TMovimentacaoCaixa>.Create(True);
  FTolerancia := 5.00;
end;

constructor TControllerCaixa.Create(const AId: Integer);
begin
  inherited Create(AId);
  FDAOMovimentacao := TMockDAO<TMovimentacaoCaixa>.Create;
  FMovimentacoes := TObjectList<TMovimentacaoCaixa>.Create(True);
  FTolerancia := 5.00;
  CarregarMovimentacoes;
end;

destructor TControllerCaixa.Destroy;
begin
  FMovimentacoes.Free;
  // FDAOMovimentacao é interface, liberado automaticamente por reference counting
  inherited Destroy;
end;

procedure TControllerCaixa.CarregarMovimentacoes;
var
  LLista: TObjectList<TMovimentacaoCaixa>;
  I: Integer;
begin
  FMovimentacoes.Clear;
  if Entidade.Id > 0 then
  begin
    LLista := FDAOMovimentacao.Where('Caixa_Id', TValue.From<Integer>(Entidade.Id)).FindAll;
    try
      for I := 0 to LLista.Count - 1 do
        FMovimentacoes.Add(LLista.Extract(LLista[0]));
    finally
      LLista.Free;
    end;
  end;
end;

function TControllerCaixa.Validar: Boolean;
begin
  Result := False;

  // Validar valor inicial
  if (Entidade.Valor_Inicial < 0) or (Entidade.Valor_Inicial > 999999.99) then
    raise EValidacaoException.Create('Valor_Inicial',
      'Valor inicial deve estar entre R$ 0,00 e R$ 999.999,99.');

  // Validar que tem colaborador associado
  if Entidade.Colaborador_Id <= 0 then
    raise EValidacaoException.Create('Colaborador_Id',
      'Colaborador é obrigatório para abertura de caixa.');

  Result := True;
end;

function TControllerCaixa.AbrirCaixa(AValorInicial: Currency; AColaboradorId: Integer): Boolean;
begin
  Result := False;

  // Validar valor inicial: 0 a 999999.99
  if (AValorInicial < 0) or (AValorInicial > 999999.99) then
    raise EValidacaoException.Create('Valor_Inicial',
      'Valor inicial deve estar entre R$ 0,00 e R$ 999.999,99.');

  // Validar colaborador
  if AColaboradorId <= 0 then
    raise EValidacaoException.Create('Colaborador_Id',
      'Colaborador é obrigatório para abertura de caixa.');

  // Verificar se já existe caixa aberto para este colaborador
  if ExisteCaixaAberto(AColaboradorId) then
    raise ECaixaException.Create(
      'Já existe um caixa aberto para este colaborador. Feche o caixa atual antes de abrir um novo.');

  // Configurar entidade
  Entidade.Colaborador_Id := AColaboradorId;
  Entidade.Valor_Inicial := AValorInicial;
  Entidade.Saldo_Esperado := AValorInicial;
  Entidade.Status := 'ABERTO';
  Entidade.Data_Abertura := Now;
  Entidade.Data_Fechamento := 0;
  Entidade.Contagem_Fisica := 0;
  Entidade.Diferenca := 0;
  Entidade.Justificativa_Diferenca := '';

  // Persistir via DAO
  Result := DAO.Save(Entidade);

  // Limpar movimentações para novo caixa
  FMovimentacoes.Clear;

  // Registrar auditoria
  if Result then
    RegistrarAuditoria('INSERT', 'CAIXA', Entidade.Id,
      Format('Caixa aberto com valor inicial R$ %.2f pelo colaborador %d',
        [AValorInicial, AColaboradorId]));
end;

function TControllerCaixa.RegistrarSangria(AValor: Currency; const AMotivo: string): Boolean;
var
  LMovimentacao: TMovimentacaoCaixa;
  LSaldoEsperado: Currency;
  LMotivoTrim: string;
  LClone: TMovimentacaoCaixa;
begin
  Result := False;

  // Verificar se caixa está aberto
  if Entidade.Status <> 'ABERTO' then
    raise ECaixaException.Create('Não é possível registrar sangria. O caixa não está aberto.');

  // Validar valor: 0.01 a 999999.99
  if (AValor < 0.01) or (AValor > 999999.99) then
    raise EValidacaoException.Create('Valor',
      'Valor da sangria deve estar entre R$ 0,01 e R$ 999.999,99.');

  // Validar motivo: 3 a 200 caracteres
  LMotivoTrim := Trim(AMotivo);
  if (Length(LMotivoTrim) < 3) or (Length(LMotivoTrim) > 200) then
    raise EValidacaoException.Create('Motivo',
      'Motivo deve ter entre 3 e 200 caracteres.');

  // Verificar se valor <= saldo esperado
  LSaldoEsperado := CalcularSaldoEsperado;
  if AValor > LSaldoEsperado then
    raise ECaixaException.Create(
      Format('Sangria rejeitada. Valor R$ %.2f excede o saldo disponível de R$ %.2f.',
        [AValor, LSaldoEsperado]));

  // Criar movimentação
  LMovimentacao := TMovimentacaoCaixa.Create;
  try
    LMovimentacao.Caixa_Id := Entidade.Id;
    LMovimentacao.Tipo := 'SANGRIA';
    LMovimentacao.Valor := AValor;
    LMovimentacao.Motivo := LMotivoTrim;
    LMovimentacao.Data_Hora := Now;

    // Persistir movimentação
    Result := FDAOMovimentacao.Save(LMovimentacao);

    if Result then
    begin
      // Adicionar à lista interna (clone para manter independência)
      LClone := TMovimentacaoCaixa.Create;
      LClone.Id := LMovimentacao.Id;
      LClone.Caixa_Id := LMovimentacao.Caixa_Id;
      LClone.Tipo := LMovimentacao.Tipo;
      LClone.Valor := LMovimentacao.Valor;
      LClone.Motivo := LMovimentacao.Motivo;
      LClone.Data_Hora := LMovimentacao.Data_Hora;
      FMovimentacoes.Add(LClone);

      // Atualizar saldo esperado na entidade
      Entidade.Saldo_Esperado := CalcularSaldoEsperado;
      DAO.Update(Entidade);

      // Registrar auditoria
      RegistrarAuditoria('INSERT', 'MOVIMENTACAO_CAIXA', LMovimentacao.Id,
        Format('Sangria de R$ %.2f no caixa %d. Motivo: %s',
          [AValor, Entidade.Id, LMotivoTrim]));
    end;
  finally
    LMovimentacao.Free;
  end;
end;

function TControllerCaixa.RegistrarSuprimento(AValor: Currency; const AMotivo: string): Boolean;
var
  LMovimentacao: TMovimentacaoCaixa;
  LMotivoTrim: string;
  LClone: TMovimentacaoCaixa;
begin
  Result := False;

  // Verificar se caixa está aberto
  if Entidade.Status <> 'ABERTO' then
    raise ECaixaException.Create('Não é possível registrar suprimento. O caixa não está aberto.');

  // Validar valor: 0.01 a 999999.99
  if (AValor < 0.01) or (AValor > 999999.99) then
    raise EValidacaoException.Create('Valor',
      'Valor do suprimento deve estar entre R$ 0,01 e R$ 999.999,99.');

  // Validar motivo: 3 a 200 caracteres
  LMotivoTrim := Trim(AMotivo);
  if (Length(LMotivoTrim) < 3) or (Length(LMotivoTrim) > 200) then
    raise EValidacaoException.Create('Motivo',
      'Motivo deve ter entre 3 e 200 caracteres.');

  // Criar movimentação
  LMovimentacao := TMovimentacaoCaixa.Create;
  try
    LMovimentacao.Caixa_Id := Entidade.Id;
    LMovimentacao.Tipo := 'SUPRIMENTO';
    LMovimentacao.Valor := AValor;
    LMovimentacao.Motivo := LMotivoTrim;
    LMovimentacao.Data_Hora := Now;

    // Persistir movimentação
    Result := FDAOMovimentacao.Save(LMovimentacao);

    if Result then
    begin
      // Adicionar à lista interna (clone para manter independência)
      LClone := TMovimentacaoCaixa.Create;
      LClone.Id := LMovimentacao.Id;
      LClone.Caixa_Id := LMovimentacao.Caixa_Id;
      LClone.Tipo := LMovimentacao.Tipo;
      LClone.Valor := LMovimentacao.Valor;
      LClone.Motivo := LMovimentacao.Motivo;
      LClone.Data_Hora := LMovimentacao.Data_Hora;
      FMovimentacoes.Add(LClone);

      // Atualizar saldo esperado na entidade
      Entidade.Saldo_Esperado := CalcularSaldoEsperado;
      DAO.Update(Entidade);

      // Registrar auditoria
      RegistrarAuditoria('INSERT', 'MOVIMENTACAO_CAIXA', LMovimentacao.Id,
        Format('Suprimento de R$ %.2f no caixa %d. Motivo: %s',
          [AValor, Entidade.Id, LMotivoTrim]));
    end;
  finally
    LMovimentacao.Free;
  end;
end;

function TControllerCaixa.FecharCaixa(AContagemFisica: Currency;
  const AJustificativa: string): Boolean;
var
  LSaldoEsperado: Currency;
  LDiferenca: Currency;
  LJustificativaTrim: string;
begin
  Result := False;

  // Verificar se caixa está aberto
  if Entidade.Status <> 'ABERTO' then
    raise ECaixaException.Create('Não é possível fechar o caixa. O caixa não está aberto.');

  // Calcular saldo esperado e diferença
  LSaldoEsperado := CalcularSaldoEsperado;
  LDiferenca := AContagemFisica - LSaldoEsperado;

  // Se diferença excede tolerância, exigir justificativa
  LJustificativaTrim := Trim(AJustificativa);
  if Abs(LDiferenca) > FTolerancia then
  begin
    if Length(LJustificativaTrim) < 10 then
      raise EValidacaoException.Create('Justificativa',
        Format('Diferença de R$ %.2f excede a tolerância de R$ %.2f. ' +
          'Justificativa com mínimo de 10 caracteres é obrigatória.',
          [Abs(LDiferenca), FTolerancia]));
  end;

  // Atualizar entidade com dados de fechamento
  Entidade.Saldo_Esperado := LSaldoEsperado;
  Entidade.Contagem_Fisica := AContagemFisica;
  Entidade.Diferenca := LDiferenca;
  Entidade.Justificativa_Diferenca := LJustificativaTrim;
  Entidade.Status := 'FECHADO';
  Entidade.Data_Fechamento := Now;

  // Persistir
  Result := DAO.Update(Entidade);

  // Registrar auditoria
  if Result then
    RegistrarAuditoria('UPDATE', 'CAIXA', Entidade.Id,
      Format('Caixa fechado. Saldo esperado: R$ %.2f | Contagem: R$ %.2f | Diferença: R$ %.2f',
        [LSaldoEsperado, AContagemFisica, LDiferenca]));
end;

function TControllerCaixa.CalcularSaldoEsperado: Currency;
var
  I: Integer;
begin
  // saldo = valor_inicial + Σ(suprimentos) - Σ(sangrias)
  // Nota: vendas em dinheiro serão adicionadas quando Controller.Venda estiver integrado
  Result := Entidade.Valor_Inicial;

  for I := 0 to FMovimentacoes.Count - 1 do
  begin
    if FMovimentacoes[I].Tipo = 'SUPRIMENTO' then
      Result := Result + FMovimentacoes[I].Valor
    else if FMovimentacoes[I].Tipo = 'SANGRIA' then
      Result := Result - FMovimentacoes[I].Valor;
  end;
end;

function TControllerCaixa.CaixaAberto(AColaboradorId: Integer): TCaixa;
var
  LCaixas: TObjectList<TCaixa>;
  I: Integer;
begin
  Result := nil;

  // Buscar todos os caixas do colaborador com status ABERTO
  LCaixas := DAO.Where('Status', TValue.From<string>('ABERTO')).FindAll;
  try
    for I := 0 to LCaixas.Count - 1 do
    begin
      if LCaixas[I].Colaborador_Id = AColaboradorId then
      begin
        // Extrair o item da lista para que não seja destruído com ela
        Result := LCaixas.Extract(LCaixas[I]);
        Exit;
      end;
    end;
  finally
    LCaixas.Free;
  end;
end;

function TControllerCaixa.ExisteCaixaAberto(AColaboradorId: Integer): Boolean;
var
  LCaixa: TCaixa;
begin
  LCaixa := CaixaAberto(AColaboradorId);
  Result := Assigned(LCaixa);
  if Result then
    LCaixa.Free;
end;

end.
