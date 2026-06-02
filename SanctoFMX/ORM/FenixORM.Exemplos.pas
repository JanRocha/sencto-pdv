unit FenixORM.Exemplos;

interface

uses
  System.Generics.Collections,
  System.RTTI,
  Data.DB;

type
  TExemplosORM = class
  public
    // CRUD basico
    procedure ExemploInsert;
    procedure ExemploUpdate;
    procedure ExemploDelete;
    procedure ExemploSave;
    procedure ExemploGravar;

    // Consultas
    procedure ExemploFindPorId;
    procedure ExemploFindPorFiltro;
    procedure ExemploFindAll;
    procedure ExemploFindAllComFiltro;
    procedure ExemploCount;

    // Where tipado
    procedure ExemploWhereFindAll;
    procedure ExemploWhereFind;

    // Transacoes
    procedure ExemploTransacao;

    // Utilitarios
    procedure ExemploLastId;
    procedure ExemploRegistroExiste;
    procedure ExemploDataSource;
    procedure ExemploCarregarDados;
  end;

implementation

uses
  System.SysUtils,
  Controller.Pessoa,
  Model.Entidade.Pessoa,
  FenixPlus.View.Mensagens;

{ TExemplosORM }

// ============================================================================
// INSERT - Inserir nova pessoa via Controller
// ============================================================================
procedure TExemplosORM.ExemploInsert;
begin
  var lController := TControllerPessoa.Create;
  try
    lController.Entidade.Nome_razao_social := 'Maria Silva';
    lController.Entidade.Apelido_nome_fantasia := 'Maria';
    lController.Entidade.Cpf_cnpj := '12345678901';
    lController.Entidade.Tipo_pessoa := 'F';
    lController.Entidade.cliente := 1;
    lController.Entidade.Situacao := 1;
    lController.Entidade.Data_cadastro := Date;
    lController.Entidade.Limite_credito := 5000.00;

    // Insert direto via FDAO (query parametrizada, seguro contra SQL injection)
    if lController.FDAO.Insert(lController.Entidade) then
      TFrmMensagens.ExibirMensagem('Pessoa inserida com sucesso');
  finally
    lController.Free;
  end;
end;

// ============================================================================
// UPDATE - Atualizar pessoa existente
// ============================================================================
procedure TExemplosORM.ExemploUpdate;
begin
  // Carrega pelo ID no construtor
  var lController := TControllerPessoa.Create(42);
  try
    // Entidade ja vem preenchida
    lController.Entidade.Email := 'maria@email.com';
    lController.Entidade.Celular := '11999998888';

    if lController.FDAO.Update(lController.Entidade) then
      TFrmMensagens.ExibirMensagem('Pessoa atualizada com sucesso');
  finally
    lController.Free;
  end;
end;

// ============================================================================
// DELETE - Excluir pessoa via metodo herdado da Base
// ============================================================================
procedure TExemplosORM.ExemploDelete;
begin
  var lController := TControllerPessoa.Create(42);
  try
    // Delete herdado de TControllerBase — usa FDAO.Delete(Entidade)
    if lController.Delete then
      TFrmMensagens.ExibirMensagem('Pessoa excluida com sucesso');
  finally
    lController.Free;
  end;
end;

// ============================================================================
// SAVE (Upsert) - Insert ou Update automatico baseado na PK
// ============================================================================
procedure TExemplosORM.ExemploSave;
begin
  var lController := TControllerPessoa.Create;
  try
    // PK = 0 -> executa INSERT automaticamente
    lController.Entidade.Id := 0;
    lController.Entidade.Nome_razao_social := 'Joao Santos';
    lController.Entidade.Apelido_nome_fantasia := 'Joao';
    lController.Entidade.Cpf_cnpj := '98765432100';
    lController.Entidade.Tipo_pessoa := 'F';
    lController.Entidade.cliente := 1;
    lController.Entidade.Situacao := 1;
    lController.Entidade.Data_cadastro := Date;
    lController.FDAO.Save(lController.Entidade);

    // PK != 0 -> executa UPDATE automaticamente
    lController.Entidade.Id := 10;
    lController.Entidade.Nome_razao_social := 'Joao Santos Atualizado';
    lController.FDAO.Save(lController.Entidade);
  finally
    lController.Free;
  end;
end;

// ============================================================================
// GRAVAR - Metodo proprio da TControllerPessoa (valida + insert/update)
// ============================================================================
procedure TExemplosORM.ExemploGravar;
begin
  var lController := TControllerPessoa.Create;
  try
    lController.Entidade.Nome_razao_social := 'Empresa ABC Ltda';
    lController.Entidade.Apelido_nome_fantasia := 'ABC';
    lController.Entidade.Cpf_cnpj := '12345678000199';
    lController.Entidade.Tipo_pessoa := 'J';
    lController.Entidade.Fornecedor := 1;
    lController.Entidade.Situacao := 1;

    // Validar lanca excecao se dados invalidos
    lController.Validar;

    // Gravar decide entre Insert e Update pelo Id
    // Se Insert, ja preenche o Id com LastId
    if lController.Gravar then
      TFrmMensagens.ExibirMensagem(
        'Gravado com ID: ' + IntToStr(lController.Entidade.Id)
      );
  finally
    lController.Free;
  end;
end;

// ============================================================================
// FIND por ID - Carrega pessoa pelo identificador
// ============================================================================
procedure TExemplosORM.ExemploFindPorId;
begin
  // O construtor com Integer ja carrega a entidade
  var lController := TControllerPessoa.Create(42);
  try
    TFrmMensagens.ExibirMensagem(
      'Nome: ' + lController.Entidade.Nome_razao_social + sLineBreak +
      'CPF/CNPJ: ' + lController.Entidade.Cpf_cnpj + sLineBreak +
      'Email: ' + lController.Entidade.Email
    );
  finally
    lController.Free;
  end;
end;

// ============================================================================
// FIND por filtro SQL - Carrega pessoa com filtro textual
// ============================================================================
procedure TExemplosORM.ExemploFindPorFiltro;
begin
  // O construtor com string ja carrega a entidade pelo filtro
  var lController := TControllerPessoa.Create('AND CPF_CNPJ = ''12345678901''');
  try
    TFrmMensagens.ExibirMensagem('Encontrado: ' + lController.Entidade.Nome_razao_social);
  finally
    lController.Free;
  end;
end;

// ============================================================================
// FINDALL - Retorna lista de objetos tipados (TObjectList<TPessoa>)
// ============================================================================
procedure TExemplosORM.ExemploFindAll;
begin
  var lController := TControllerPessoa.Create;
  try
    // Todas as pessoas
    var lLista := lController.FDAO.FindAll;
    try
      TFrmMensagens.ExibirMensagem(
        'Total de pessoas: ' + IntToStr(lLista.Count)
      );

      for var lPessoa in lLista do
      begin
        // Cada item e uma TPessoa com todas as propriedades preenchidas
        // lPessoa.Nome_razao_social, lPessoa.Cpf_cnpj, etc.
      end;
    finally
      lLista.Free; // libera a lista e todos os objetos (OwnsObjects = True)
    end;
  finally
    lController.Free;
  end;
end;

// ============================================================================
// FINDALL com filtro - Retorna lista filtrada
// ============================================================================
procedure TExemplosORM.ExemploFindAllComFiltro;
begin
  var lController := TControllerPessoa.Create;
  try
    // Apenas clientes ativos
    var lLista := lController.FDAO.FindAll('CLIENTE = 1 AND SITUACAO = 1');
    try
      for var lPessoa in lLista do
        TFrmMensagens.ExibirMensagem(lPessoa.Nome_razao_social);
    finally
      lLista.Free;
    end;
  finally
    lController.Free;
  end;
end;

// ============================================================================
// COUNT - Contagem de registros com filtro opcional
// ============================================================================
procedure TExemplosORM.ExemploCount;
begin
  var lController := TControllerPessoa.Create;
  try
    var lTotal := lController.FDAO.Count;
    var lAtivos := lController.FDAO.Count('CLIENTE = 1 AND SITUACAO = 1');
    var lFornecedores := lController.FDAO.Count('FORNECEDOR = 1');

    TFrmMensagens.ExibirMensagem(
      'Total: ' + IntToStr(lTotal) + sLineBreak +
      'Clientes ativos: ' + IntToStr(lAtivos) + sLineBreak +
      'Fornecedores: ' + IntToStr(lFornecedores)
    );
  finally
    lController.Free;
  end;
end;

// ============================================================================
// WHERE tipado + FindAll - Filtro parametrizado (previne SQL injection)
// ============================================================================
procedure TExemplosORM.ExemploWhereFindAll;
begin
  var lController := TControllerPessoa.Create;
  try
    // Busca por CPF usando parametro tipado — seguro contra SQL injection
    var lLista := lController.FDAO
      .Where('CPF_CNPJ', TValue.From<string>('12345678901'))
      .FindAll;
    try
      for var lPessoa in lLista do
        TFrmMensagens.ExibirMensagem(lPessoa.Nome_razao_social);
    finally
      lLista.Free;
    end;

    // O filtro Where e limpo automaticamente apos a execucao
    // A proxima consulta nao e afetada
    var lTodos := lController.FDAO.FindAll;
    try
      TFrmMensagens.ExibirMensagem('Total sem filtro: ' + IntToStr(lTodos.Count));
    finally
      lTodos.Free;
    end;
  finally
    lController.Free;
  end;
end;

// ============================================================================
// WHERE tipado + Find - Busca unico registro parametrizado
// ============================================================================
procedure TExemplosORM.ExemploWhereFind;
begin
  var lController := TControllerPessoa.Create;
  try
    // Where com String — busca por email
    lController.FDAO
      .Where('EMAIL', TValue.From<string>('maria@email.com'))
      .Find(lController.Entidade, '');
    TFrmMensagens.ExibirMensagem('Por email: ' + lController.Entidade.Nome_razao_social);

    // Where com Integer — busca por situacao
    lController.FDAO
      .Where('SITUACAO', TValue.From<Integer>(1))
      .Find(lController.Entidade, '');
    TFrmMensagens.ExibirMensagem('Ativo: ' + lController.Entidade.Nome_razao_social);

    // Where com Currency — busca por limite de credito
    lController.FDAO
      .Where('LIMITE_CREDITO', TValue.From<Currency>(5000.00))
      .Find(lController.Entidade, '');
    TFrmMensagens.ExibirMensagem('Por limite: ' + lController.Entidade.Nome_razao_social);
  finally
    lController.Free;
  end;
end;

// ============================================================================
// TRANSACOES - Agrupar operacoes atomicas
// ============================================================================
procedure TExemplosORM.ExemploTransacao;
begin
  var lController := TControllerPessoa.Create;
  try
    lController.FDAO.BeginTransaction;
    try
      // Primeira pessoa
      var lPessoa1 := TPessoa.Create;
      try
        lPessoa1.Nome_razao_social := 'Empresa ABC Ltda';
        lPessoa1.Apelido_nome_fantasia := 'ABC';
        lPessoa1.Cpf_cnpj := '12345678000199';
        lPessoa1.Tipo_pessoa := 'J';
        lPessoa1.Fornecedor := 1;
        lPessoa1.Situacao := 1;
        lPessoa1.Data_cadastro := Date;
        lController.FDAO.Insert(lPessoa1);
      finally
        lPessoa1.Free;
      end;

      // Segunda pessoa
      var lPessoa2 := TPessoa.Create;
      try
        lPessoa2.Nome_razao_social := 'Empresa XYZ Ltda';
        lPessoa2.Apelido_nome_fantasia := 'XYZ';
        lPessoa2.Cpf_cnpj := '98765432000188';
        lPessoa2.Tipo_pessoa := 'J';
        lPessoa2.Fornecedor := 1;
        lPessoa2.Situacao := 1;
        lPessoa2.Data_cadastro := Date;
        lController.FDAO.Insert(lPessoa2);
      finally
        lPessoa2.Free;
      end;

      // Tudo certo — confirma ambas
      lController.FDAO.Commit;
      TFrmMensagens.ExibirMensagem('Ambas inseridas com sucesso');
    except
      // Qualquer falha — desfaz tudo
      lController.FDAO.Rollback;
      TFrmMensagens.ExibirMensagem('Erro: operacao desfeita');
    end;
  finally
    lController.Free;
  end;
end;

// ============================================================================
// LASTID - Obter ultimo ID inserido
// ============================================================================
procedure TExemplosORM.ExemploLastId;
begin
  var lController := TControllerPessoa.Create;
  try
    lController.Entidade.Nome_razao_social := 'Novo Cadastro';
    lController.Entidade.Apelido_nome_fantasia := 'Novo';
    lController.Entidade.Tipo_pessoa := 'F';
    lController.Entidade.cliente := 1;
    lController.Entidade.Situacao := 1;
    lController.Entidade.Data_cadastro := Date;

    lController.FDAO.Insert(lController.Entidade);

    var lNovoId := lController.FDAO.LastId;
    TFrmMensagens.ExibirMensagem('ID gerado: ' + IntToStr(lNovoId));
  finally
    lController.Free;
  end;
end;

// ============================================================================
// REGISTRO EXISTE - Verificar existencia por OID (herdado da Base)
// ============================================================================
procedure TExemplosORM.ExemploRegistroExiste;
begin
  var lController := TControllerPessoa.Create;
  try
    // Metodo herdado de TControllerBase — delega para FDAO.RegistroExiste
    var lId := lController.RegistroExiste('A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4');

    if lId > 0 then
      TFrmMensagens.ExibirMensagem('Registro encontrado com ID: ' + IntToStr(lId))
    else
      TFrmMensagens.ExibirMensagem('Registro nao encontrado');
  finally
    lController.Free;
  end;
end;

// ============================================================================
// DATASOURCE - Vincular dataset a um TDataSource (para grids)
// ============================================================================
procedure TExemplosORM.ExemploDataSource;
begin
  var lController := TControllerPessoa.Create;
  try
    var lDataSource := TDataSource.Create(nil);
    try
      // Vincula o dataset de PESSOA ao DataSource
      lController.FDAO.DataSource(lDataSource);

      // Agora lDataSource.DataSet contem todos os registros
      // Pode ser atribuido a um grid:
      // cxGrid1TableView1.DataController.DataSource := lDataSource;
    finally
      if Assigned(lDataSource.DataSet) then
        lDataSource.DataSet.Free;
      lDataSource.Free;
    end;
  finally
    lController.Free;
  end;
end;

// ============================================================================
// CARREGAR DADOS - Metodos herdados da Base para grids e combos
// ============================================================================
procedure TExemplosORM.ExemploCarregarDados;
begin
  var lController := TControllerPessoa.Create;
  try
    // CarregarDados em DataSource (herdado da Base)
    var lDataSource := TDataSource.Create(nil);
    try
      lController.CarregarDados(lDataSource);
      // lDataSource.DataSet agora tem todos os registros de PESSOA
    finally
      if Assigned(lDataSource.DataSet) then
        lDataSource.DataSet.Free;
      lDataSource.Free;
    end;

    // Carregar com SQL customizado
    var lQuery := lController.Carregar(
      'SELECT P.ID, P.NOME_RAZAO_SOCIAL, P.CPF_CNPJ ' +
      'FROM PESSOA P ' +
      'WHERE P.SITUACAO = 1 ' +
      'ORDER BY P.NOME_RAZAO_SOCIAL'
    );
    try
      while not lQuery.Eof do
      begin
        // lQuery.FieldByName('NOME_RAZAO_SOCIAL').AsString
        lQuery.Next;
      end;
    finally
      lQuery.Free;
    end;

    // NomeTabela — retorna 'PESSOA'
    TFrmMensagens.ExibirMensagem('Tabela: ' + lController.NomeTabela);
  finally
    lController.Free;
  end;
end;

end.
