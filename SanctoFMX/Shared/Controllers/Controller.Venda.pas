unit Controller.Venda;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Venda,
  Model.Entidade.VendaItem,
  Model.Entidade.Produto,
  Model.Entidade.Caixa,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para operações de venda no PDV.
  /// Gerencia o carrinho de compras em memória (TObjectList de TVendaItem),
  /// validações de estoque, cálculos de subtotal/desconto/total e finalização
  /// atômica com decremento de estoque em transação.
  /// </summary>
  TControllerVenda = class(TControllerBase<TVenda>)
  private
    FCarrinho: TObjectList<TVendaItem>;
    FDesconto: Currency;
    FDAOVendaItem: IDAO<TVendaItem>;
    FDAOProduto: IDAO<TProduto>;
    FDAOCaixa: IDAO<TCaixa>;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    // --- Cart management ---

    /// <summary>
    /// Adiciona um produto ao carrinho. Se o produto já estiver no carrinho,
    /// incrementa a quantidade. Valida estoque disponível antes de adicionar.
    /// Utiliza preço promocional se > 0, caso contrário preço de venda.
    /// </summary>
    /// <param name="AProduto">Produto a ser adicionado</param>
    /// <param name="AQuantidade">Quantidade a adicionar (padrão 1)</param>
    procedure AdicionarProduto(AProduto: TProduto; AQuantidade: Integer = 1);

    /// <summary>
    /// Remove um item do carrinho pelo índice.
    /// </summary>
    /// <param name="AIndex">Índice do item no carrinho (0-based)</param>
    procedure RemoverItem(AIndex: Integer);

    /// <summary>
    /// Altera a quantidade de um item do carrinho.
    /// Valida estoque disponível para a nova quantidade.
    /// </summary>
    /// <param name="AIndex">Índice do item no carrinho (0-based)</param>
    /// <param name="ANovaQuantidade">Nova quantidade desejada</param>
    procedure AlterarQuantidade(AIndex: Integer; ANovaQuantidade: Integer);

    /// <summary>
    /// Limpa todos os itens do carrinho e zera o desconto.
    /// </summary>
    procedure LimparCarrinho;

    /// <summary>
    /// Retorna o número de itens distintos no carrinho.
    /// </summary>
    function ItemCount: Integer;

    // --- Calculations ---

    /// <summary>
    /// Calcula o subtotal da venda: soma de (quantidade * preço unitário) de todos os itens.
    /// </summary>
    function CalcularSubtotal: Currency;

    /// <summary>
    /// Aplica um desconto à venda. Valida que o valor está entre 0 e o subtotal.
    /// </summary>
    /// <param name="AValor">Valor do desconto a aplicar</param>
    procedure AplicarDesconto(AValor: Currency);

    /// <summary>
    /// Calcula o total da venda: subtotal - desconto.
    /// </summary>
    function CalcularTotal: Currency;

    // --- Finalization ---

    /// <summary>
    /// Finaliza a venda com transação atômica:
    /// 1. Valida carrinho não vazio
    /// 2. Valida caixa aberto para o colaborador
    /// 3. Cria registro TVenda + TVendaItems
    /// 4. Decrementa estoque de cada produto
    /// 5. Registra auditoria
    /// 6. Limpa carrinho em caso de sucesso
    /// Em caso de falha, faz rollback completo.
    /// </summary>
    /// <param name="AFormaPagamento">Forma de pagamento (DINHEIRO, CREDITO, DEBITO, PIX, COMANDA)</param>
    /// <param name="AParcelas">Número de parcelas (1-12, relevante para CREDITO)</param>
    /// <param name="ACPFCliente">CPF do cliente (opcional, pode ser vazio)</param>
    /// <param name="ACaixaId">Id do caixa aberto</param>
    /// <param name="AColaboradorId">Id do colaborador realizando a venda</param>
    function FinalizarVenda(const AFormaPagamento: string; AParcelas: Integer;
      const ACPFCliente: string; ACaixaId, AColaboradorId: Integer): Boolean;

    /// <summary>
    /// Cancela a venda em andamento: limpa o carrinho sem afetar estoque ou registros.
    /// </summary>
    procedure CancelarVenda;

    // --- Validation (required by TControllerBase) ---

    /// <summary>
    /// Valida os dados da venda antes da finalização.
    /// </summary>
    function Validar: Boolean; override;

    // --- Properties ---

    /// <summary>Lista de itens do carrinho (somente leitura).</summary>
    property Carrinho: TObjectList<TVendaItem> read FCarrinho;

    /// <summary>Valor do desconto aplicado à venda.</summary>
    property Desconto: Currency read FDesconto;

    /// <summary>Subtotal calculado da venda (soma dos itens).</summary>
    property Subtotal: Currency read CalcularSubtotal;

    /// <summary>Total calculado da venda (subtotal - desconto).</summary>
    property Total: Currency read CalcularTotal;

    /// <summary>DAO de VendaItem para persistência dos itens.</summary>
    property DAOVendaItem: IDAO<TVendaItem> read FDAOVendaItem;

    /// <summary>DAO de Produto para consultas e atualização de estoque.</summary>
    property DAOProduto: IDAO<TProduto> read FDAOProduto;

    /// <summary>DAO de Caixa para validação de caixa aberto.</summary>
    property DAOCaixa: IDAO<TCaixa> read FDAOCaixa;
  end;

implementation

{ TControllerVenda }

constructor TControllerVenda.Create;
begin
  inherited Create;
  FCarrinho := TObjectList<TVendaItem>.Create(True);
  FDesconto := 0;
  FDAOVendaItem := TMockDAO<TVendaItem>.Create;
  FDAOProduto := TMockDAO<TProduto>.Create;
  FDAOCaixa := TMockDAO<TCaixa>.Create;
end;

destructor TControllerVenda.Destroy;
begin
  FCarrinho.Free;
  // Interfaces são liberadas por reference counting
  inherited Destroy;
end;

procedure TControllerVenda.AdicionarProduto(AProduto: TProduto; AQuantidade: Integer = 1);
var
  I: Integer;
  LItemExistente: TVendaItem;
  LNovaQtd: Integer;
  LPrecoUnitario: Currency;
  LNovoItem: TVendaItem;
begin
  if not Assigned(AProduto) then
    raise EValidacaoException.Create('Produto', 'Produto não informado.');

  if AQuantidade <= 0 then
    raise EValidacaoException.Create('Quantidade', 'Quantidade deve ser maior que zero.');

  // Determinar preço unitário: promocional se > 0, caso contrário preço de venda
  if AProduto.Preco_Promocional > 0 then
    LPrecoUnitario := AProduto.Preco_Promocional
  else
    LPrecoUnitario := AProduto.Preco_Venda;

  // Verificar se o produto já está no carrinho
  LItemExistente := nil;
  for I := 0 to FCarrinho.Count - 1 do
  begin
    if FCarrinho[I].Produto_Id = AProduto.Id then
    begin
      LItemExistente := FCarrinho[I];
      Break;
    end;
  end;

  // Calcular quantidade total desejada
  if Assigned(LItemExistente) then
    LNovaQtd := LItemExistente.Quantidade + AQuantidade
  else
    LNovaQtd := AQuantidade;

  // Verificar estoque disponível
  if AProduto.Estoque_Atual < LNovaQtd then
    raise EEstoqueException.Create(
      Format('Estoque insuficiente para "%s". Disponível: %d, Solicitado: %d.',
        [AProduto.Nome, AProduto.Estoque_Atual, LNovaQtd]),
      AProduto.Nome,
      AProduto.Estoque_Atual);

  // Adicionar ou incrementar
  if Assigned(LItemExistente) then
  begin
    LItemExistente.Quantidade := LNovaQtd;
    LItemExistente.Subtotal := LNovaQtd * LItemExistente.Preco_Unitario;
  end
  else
  begin
    LNovoItem := TVendaItem.Create;
    LNovoItem.Produto_Id := AProduto.Id;
    LNovoItem.Quantidade := AQuantidade;
    LNovoItem.Preco_Unitario := LPrecoUnitario;
    LNovoItem.Subtotal := AQuantidade * LPrecoUnitario;
    FCarrinho.Add(LNovoItem);
  end;
end;

procedure TControllerVenda.RemoverItem(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCarrinho.Count) then
    raise EValidacaoException.Create('Índice', 'Índice do item inválido.');

  FCarrinho.Delete(AIndex);
end;

procedure TControllerVenda.AlterarQuantidade(AIndex: Integer; ANovaQuantidade: Integer);
var
  LItem: TVendaItem;
  LProduto: TProduto;
begin
  if (AIndex < 0) or (AIndex >= FCarrinho.Count) then
    raise EValidacaoException.Create('Índice', 'Índice do item inválido.');

  if ANovaQuantidade <= 0 then
    raise EValidacaoException.Create('Quantidade', 'Quantidade deve ser maior que zero.');

  LItem := FCarrinho[AIndex];

  // Verificar estoque para a nova quantidade
  LProduto := FDAOProduto.Find(LItem.Produto_Id);
  try
    if Assigned(LProduto) then
    begin
      if LProduto.Estoque_Atual < ANovaQuantidade then
        raise EEstoqueException.Create(
          Format('Estoque insuficiente para "%s". Disponível: %d, Solicitado: %d.',
            [LProduto.Nome, LProduto.Estoque_Atual, ANovaQuantidade]),
          LProduto.Nome,
          LProduto.Estoque_Atual);
    end;
  finally
    LProduto.Free;
  end;

  LItem.Quantidade := ANovaQuantidade;
  LItem.Subtotal := ANovaQuantidade * LItem.Preco_Unitario;
end;

procedure TControllerVenda.LimparCarrinho;
begin
  FCarrinho.Clear;
  FDesconto := 0;
end;

function TControllerVenda.ItemCount: Integer;
begin
  Result := FCarrinho.Count;
end;

function TControllerVenda.CalcularSubtotal: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FCarrinho.Count - 1 do
    Result := Result + (FCarrinho[I].Quantidade * FCarrinho[I].Preco_Unitario);
end;

procedure TControllerVenda.AplicarDesconto(AValor: Currency);
var
  LSubtotal: Currency;
begin
  LSubtotal := CalcularSubtotal;

  if AValor < 0 then
    raise EValidacaoException.Create('Desconto', 'Desconto não pode ser negativo.');

  if AValor > LSubtotal then
    raise EValidacaoException.Create('Desconto',
      Format('Desconto (R$ %.2f) não pode ser maior que o subtotal (R$ %.2f).',
        [AValor, LSubtotal]));

  FDesconto := AValor;
end;

function TControllerVenda.CalcularTotal: Currency;
begin
  Result := CalcularSubtotal - FDesconto;
end;

function TControllerVenda.Validar: Boolean;
begin
  Result := False;

  if FCarrinho.Count = 0 then
    raise EValidacaoException.Create('Carrinho', 'Carrinho está vazio. Adicione produtos antes de finalizar.');

  Result := True;
end;

function TControllerVenda.FinalizarVenda(const AFormaPagamento: string; AParcelas: Integer;
  const ACPFCliente: string; ACaixaId, AColaboradorId: Integer): Boolean;
var
  LCaixa: TCaixa;
  I: Integer;
  LProduto: TProduto;
  LVendaItem: TVendaItem;
begin
  Result := False;

  // 1. Validar carrinho não vazio
  Validar;

  // 2. Validar forma de pagamento
  if Trim(AFormaPagamento) = '' then
    raise EValidacaoException.Create('Forma_Pagamento', 'Forma de pagamento é obrigatória.');

  // 3. Validar parcelas para crédito
  if SameText(AFormaPagamento, 'CREDITO') then
  begin
    if (AParcelas < 1) or (AParcelas > 12) then
      raise EValidacaoException.Create('Parcelas', 'Número de parcelas deve ser entre 1 e 12.');
  end;

  // 4. Validar caixa aberto
  LCaixa := FDAOCaixa.Find(ACaixaId);
  try
    if not Assigned(LCaixa) then
      raise ECaixaException.Create('Caixa não encontrado. É necessário abrir o caixa antes de realizar vendas.');

    if not SameText(LCaixa.Status, 'ABERTO') then
      raise ECaixaException.Create('Caixa não está aberto. É necessário abrir o caixa antes de realizar vendas.');
  finally
    LCaixa.Free;
  end;

  // 5. Transação atômica: criar venda + itens + decrementar estoque
  FDAOProduto.BeginTransaction;
  try
    // Configurar entidade TVenda
    Entidade.Caixa_Id := ACaixaId;
    Entidade.Colaborador_Id := AColaboradorId;
    Entidade.Subtotal := CalcularSubtotal;
    Entidade.Desconto := FDesconto;
    Entidade.Total := CalcularTotal;
    Entidade.Forma_Pagamento := AFormaPagamento;
    Entidade.Parcelas := AParcelas;
    Entidade.CPF_Cliente := ACPFCliente;
    Entidade.Status := 'FINALIZADA';
    Entidade.Data_Hora := Now;

    // Gravar a venda (usa DAO herdado do TControllerBase)
    if not inherited Gravar then
    begin
      FDAOProduto.Rollback;
      Exit;
    end;

    // Gravar itens e decrementar estoque
    for I := 0 to FCarrinho.Count - 1 do
    begin
      LVendaItem := FCarrinho[I];

      // Vincular item à venda
      LVendaItem.Venda_Id := Entidade.Id;
      FDAOVendaItem.Save(LVendaItem);

      // Decrementar estoque do produto
      LProduto := FDAOProduto.Find(LVendaItem.Produto_Id);
      try
        if Assigned(LProduto) then
        begin
          LProduto.Estoque_Atual := LProduto.Estoque_Atual - LVendaItem.Quantidade;
          FDAOProduto.Update(LProduto);
        end;
      finally
        LProduto.Free;
      end;
    end;

    FDAOProduto.Commit;

    // 6. Registrar auditoria
    RegistrarAuditoria('INSERT', 'VENDA', Entidade.Id,
      Format('Venda finalizada. Total: R$ %.2f, Forma: %s, Itens: %d',
        [Entidade.Total, AFormaPagamento, FCarrinho.Count]));

    // 7. Limpar carrinho após sucesso
    LimparCarrinho;

    Result := True;
  except
    FDAOProduto.Rollback;
    raise;
  end;
end;

procedure TControllerVenda.CancelarVenda;
begin
  LimparCarrinho;
end;

end.
