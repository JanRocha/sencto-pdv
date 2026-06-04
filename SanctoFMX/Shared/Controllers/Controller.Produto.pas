unit Controller.Produto;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Produto,
  Model.Entidade.VendaItem,
  Model.Entidade.VisitaConsumo,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para gestão de Produtos.
  /// Implementa validações de cadastro (nome, código de barras, preço, campos fiscais),
  /// unicidade de código de barras, filtro por categoria, controle de estoque mínimo,
  /// verificação de vínculos antes de exclusão, ativação/desativação.
  /// </summary>
  TControllerProduto = class(TControllerBase<TProduto>)
  private
    /// <summary>Remove caracteres não numéricos de uma string.</summary>
    function ApenasDigitos(const AValor: string): string;
    /// <summary>Verifica se a string contém apenas dígitos numéricos.</summary>
    function SomenteDigitos(const AValor: string): Boolean;
  public
    /// <summary>
    /// Valida todos os campos da entidade Produto:
    /// - Nome: 1 a 120 caracteres, não vazio
    /// - Codigo_Barras: não vazio, máximo 20 caracteres
    /// - Preco_Venda: entre 0.01 e 999999.99
    /// - NCM: exatamente 8 dígitos numéricos
    /// - CFOP: exatamente 4 dígitos numéricos
    /// - Aliquota_ICMS: entre 0.00 e 100.00
    /// - Aliquota_PIS: entre 0.00 e 100.00
    /// - Aliquota_COFINS: entre 0.00 e 100.00
    /// - Estoque_Atual: entre 0 e 99999
    /// - Estoque_Minimo: entre 0 e 99999
    /// Lança EValidacaoException em caso de falha.
    /// </summary>
    function Validar: Boolean; override;

    /// <summary>
    /// Verifica se o Codigo_Barras da entidade atual já existe no DAO,
    /// excluindo o registro com o Id atual (para edição).
    /// Retorna True se o código de barras é único.
    /// </summary>
    function ValidarUnicidadeCodigoBarras: Boolean;

    /// <summary>
    /// Grava o produto: valida campos, verifica unicidade de código de barras,
    /// persiste via DAO e registra auditoria.
    /// Retorna True se a operação foi bem-sucedida.
    /// </summary>
    function Gravar: Boolean; override;

    /// <summary>
    /// Filtra produtos por categoria. Retorna lista de produtos
    /// cuja Categoria_Id corresponde ao parâmetro informado.
    /// </summary>
    function FiltrarPorCategoria(ACategoriaId: Integer): TObjectList<TProduto>;

    /// <summary>
    /// Retorna lista de produtos ativos (Situacao = 1).
    /// </summary>
    function ProdutosAtivos: TObjectList<TProduto>;

    /// <summary>
    /// Retorna lista de produtos com estoque atual menor ou igual ao estoque mínimo.
    /// </summary>
    function ProdutosEstoqueBaixo: TObjectList<TProduto>;

    /// <summary>
    /// Verifica se o produto pode ser excluído.
    /// Retorna False se existem itens de venda ou consumos de visita vinculados.
    /// </summary>
    function PodeExcluir: Boolean;

    /// <summary>
    /// Desativa o produto: define Situacao=0 e atualiza no DAO.
    /// </summary>
    procedure Desativar;

    /// <summary>
    /// Reativa o produto: define Situacao=1 e atualiza no DAO.
    /// </summary>
    procedure Reativar;
  end;

implementation

{ TControllerProduto }

function TControllerProduto.ApenasDigitos(const AValor: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AValor) do
  begin
    if CharInSet(AValor[I], ['0'..'9']) then
      Result := Result + AValor[I];
  end;
end;

function TControllerProduto.SomenteDigitos(const AValor: string): Boolean;
var
  I: Integer;
begin
  Result := True;
  if AValor = '' then
  begin
    Result := False;
    Exit;
  end;
  for I := 1 to Length(AValor) do
  begin
    if not CharInSet(AValor[I], ['0'..'9']) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function TControllerProduto.Validar: Boolean;
var
  LNome, LCodigoBarras, LNCM, LCFOP: string;
begin
  Result := False;

  // Validar Nome: 1 a 120 caracteres, não vazio
  LNome := Trim(Entidade.Nome);
  if LNome = '' then
    raise EValidacaoException.Create('Nome', 'Nome é obrigatório.');
  if Length(LNome) > 120 then
    raise EValidacaoException.Create('Nome', 'Nome deve ter no máximo 120 caracteres.');

  // Validar Codigo_Barras: não vazio, máximo 20 caracteres
  LCodigoBarras := Trim(Entidade.Codigo_Barras);
  if LCodigoBarras = '' then
    raise EValidacaoException.Create('Codigo_Barras', 'Código de barras é obrigatório.');
  if Length(LCodigoBarras) > 20 then
    raise EValidacaoException.Create('Codigo_Barras', 'Código de barras deve ter no máximo 20 caracteres.');

  // Validar Preco_Venda: entre 0.01 e 999999.99
  if (Entidade.Preco_Venda < 0.01) or (Entidade.Preco_Venda > 999999.99) then
    raise EValidacaoException.Create('Preco_Venda', 'Preço de venda deve estar entre 0,01 e 999.999,99.');

  // Validar NCM: exatamente 8 dígitos numéricos
  LNCM := Trim(Entidade.NCM);
  if (Length(LNCM) <> 8) or (not SomenteDigitos(LNCM)) then
    raise EValidacaoException.Create('NCM', 'NCM deve conter exatamente 8 dígitos numéricos.');

  // Validar CFOP: exatamente 4 dígitos numéricos
  LCFOP := Trim(Entidade.CFOP);
  if (Length(LCFOP) <> 4) or (not SomenteDigitos(LCFOP)) then
    raise EValidacaoException.Create('CFOP', 'CFOP deve conter exatamente 4 dígitos numéricos.');

  // Validar Aliquota_ICMS: entre 0.00 e 100.00
  if (Entidade.Aliquota_ICMS < 0.00) or (Entidade.Aliquota_ICMS > 100.00) then
    raise EValidacaoException.Create('Aliquota_ICMS', 'Alíquota ICMS deve estar entre 0,00 e 100,00.');

  // Validar Aliquota_PIS: entre 0.00 e 100.00
  if (Entidade.Aliquota_PIS < 0.00) or (Entidade.Aliquota_PIS > 100.00) then
    raise EValidacaoException.Create('Aliquota_PIS', 'Alíquota PIS deve estar entre 0,00 e 100,00.');

  // Validar Aliquota_COFINS: entre 0.00 e 100.00
  if (Entidade.Aliquota_COFINS < 0.00) or (Entidade.Aliquota_COFINS > 100.00) then
    raise EValidacaoException.Create('Aliquota_COFINS', 'Alíquota COFINS deve estar entre 0,00 e 100,00.');

  // Validar Estoque_Atual: entre 0 e 99999
  if (Entidade.Estoque_Atual < 0) or (Entidade.Estoque_Atual > 99999) then
    raise EValidacaoException.Create('Estoque_Atual', 'Estoque atual deve estar entre 0 e 99.999.');

  // Validar Estoque_Minimo: entre 0 e 99999
  if (Entidade.Estoque_Minimo < 0) or (Entidade.Estoque_Minimo > 99999) then
    raise EValidacaoException.Create('Estoque_Minimo', 'Estoque mínimo deve estar entre 0 e 99.999.');

  Result := True;
end;

function TControllerProduto.ValidarUnicidadeCodigoBarras: Boolean;
var
  LCodigoBarras: string;
  LExistentes: TObjectList<TProduto>;
  I: Integer;
begin
  Result := True;
  LCodigoBarras := Trim(Entidade.Codigo_Barras);

  LExistentes := DAO.Where('Codigo_Barras', TValue.From<string>(LCodigoBarras)).FindAll;
  try
    for I := 0 to LExistentes.Count - 1 do
    begin
      if LExistentes[I].Id <> Entidade.Id then
      begin
        Result := False;
        Exit;
      end;
    end;
  finally
    LExistentes.Free;
  end;
end;

function TControllerProduto.Gravar: Boolean;
var
  LIsNovo: Boolean;
begin
  Result := False;

  // Validar campos
  if not Validar then
    Exit;

  // Verificar unicidade de código de barras
  if not ValidarUnicidadeCodigoBarras then
    raise EValidacaoException.Create('Codigo_Barras', 'Código de barras já está registrado para outro produto.');

  LIsNovo := (Entidade.Id = 0);

  // Gravar via DAO (inherited)
  Result := inherited Gravar;

  // Registrar auditoria
  if Result then
  begin
    if LIsNovo then
      RegistrarAuditoria('INSERT', 'PRODUTO', Entidade.Id,
        'Cadastro de produto: ' + Entidade.Nome)
    else
      RegistrarAuditoria('UPDATE', 'PRODUTO', Entidade.Id,
        'Edição de produto: ' + Entidade.Nome);
  end;
end;

function TControllerProduto.FiltrarPorCategoria(ACategoriaId: Integer): TObjectList<TProduto>;
begin
  Result := DAO.Where('Categoria_Id', TValue.From<Integer>(ACategoriaId)).FindAll;
end;

function TControllerProduto.ProdutosAtivos: TObjectList<TProduto>;
begin
  Result := DAO.Where('Situacao', TValue.From<Integer>(1)).FindAll;
end;

function TControllerProduto.ProdutosEstoqueBaixo: TObjectList<TProduto>;
var
  LTodos: TObjectList<TProduto>;
  I: Integer;
begin
  Result := TObjectList<TProduto>.Create(True);
  LTodos := DAO.FindAll;
  try
    for I := 0 to LTodos.Count - 1 do
    begin
      if LTodos[I].Estoque_Atual <= LTodos[I].Estoque_Minimo then
        Result.Add(LTodos[I]);
    end;
    // Remover itens transferidos para Result da ownership de LTodos
    // para evitar double-free. Precisamos extrair sem destruir.
    LTodos.OwnsObjects := False;
  finally
    LTodos.Free;
  end;
end;

function TControllerProduto.PodeExcluir: Boolean;
var
  LDAOVendaItem: IDAO<TVendaItem>;
  LDAOVisitaConsumo: IDAO<TVisitaConsumo>;
  LCountVendaItem, LCountVisitaConsumo: Integer;
begin
  Result := True;

  // Verificar se existem itens de venda vinculados ao produto
  LDAOVendaItem := TMockDAO<TVendaItem>.Create;
  LCountVendaItem := LDAOVendaItem.Where('Produto_Id', TValue.From<Integer>(Entidade.Id)).Count;
  if LCountVendaItem > 0 then
  begin
    Result := False;
    Exit;
  end;

  // Verificar se existem consumos de visita vinculados ao produto
  LDAOVisitaConsumo := TMockDAO<TVisitaConsumo>.Create;
  LCountVisitaConsumo := LDAOVisitaConsumo.Where('Produto_Id', TValue.From<Integer>(Entidade.Id)).Count;
  if LCountVisitaConsumo > 0 then
  begin
    Result := False;
    Exit;
  end;
end;

procedure TControllerProduto.Desativar;
begin
  Entidade.Situacao := 0;
  DAO.Update(Entidade);
  RegistrarAuditoria('UPDATE', 'PRODUTO', Entidade.Id,
    'Produto desativado: ' + Entidade.Nome);
end;

procedure TControllerProduto.Reativar;
begin
  Entidade.Situacao := 1;
  DAO.Update(Entidade);
  RegistrarAuditoria('UPDATE', 'PRODUTO', Entidade.Id,
    'Produto reativado: ' + Entidade.Nome);
end;

end.
