unit Controller.Base;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Mock.DAO,
  Model.Entidade.LogAuditoria,
  Rtti.Atributos,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller base genérico que implementa o padrão Model → Controller → DAO.
  /// Fornece operações CRUD, flag para alternar entre Mock e DAO real,
  /// extração do nome da tabela via RTTI e registro de auditoria.
  /// </summary>
  TControllerBase<T: class, constructor> = class
  private
    FDAO: IDAO<T>;
    FEntidade: T;
    FUsarMock: Boolean;
    function GetNomeTabela: string;
  protected
    /// <summary>
    /// Cria a instância do DAO. Por padrão cria TMockDAO.
    /// Sobrescrever nos controllers filhos para usar DAO real (FenixORM).
    /// </summary>
    procedure CriarDAO; virtual;
  public
    /// <summary>
    /// Id do colaborador logado atualmente no sistema.
    /// Utilizado para registrar auditoria de ações críticas.
    /// </summary>
    class var ColaboradorLogadoId: Integer;

    constructor Create; overload;
    constructor Create(const AId: Integer); overload;
    destructor Destroy; override;

    /// <summary>
    /// Entidade atual sendo manipulada pelo controller.
    /// </summary>
    property Entidade: T read FEntidade write FEntidade;

    /// <summary>
    /// Instância do DAO (MockDAO ou DAO real conforme FUsarMock).
    /// </summary>
    property DAO: IDAO<T> read FDAO;

    /// <summary>
    /// Nome da tabela extraído do atributo [Tabela] da entidade via RTTI.
    /// </summary>
    property NomeTabela: string read GetNomeTabela;

    /// <summary>
    /// Grava a entidade atual no DAO (Insert ou Update conforme Id).
    /// Retorna True se a operação foi bem-sucedida.
    /// </summary>
    function Gravar: Boolean; virtual;

    /// <summary>
    /// Valida os dados da entidade antes de gravar.
    /// Deve ser implementado por cada controller filho.
    /// </summary>
    function Validar: Boolean; virtual; abstract;

    /// <summary>
    /// Exclui a entidade atual do DAO.
    /// Retorna True se a operação foi bem-sucedida.
    /// </summary>
    function Delete: Boolean; virtual;

    /// <summary>
    /// Registra uma ação de auditoria no log do sistema.
    /// Cria um TLogAuditoria e persiste via MockDAO interno.
    /// </summary>
    /// <param name="ATipoAcao">Tipo da ação (ex: INSERT, UPDATE, DELETE, LOGIN)</param>
    /// <param name="AEntidade">Nome da entidade afetada</param>
    /// <param name="AEntidadeId">Id do registro afetado</param>
    /// <param name="ADetalhes">Detalhes adicionais da ação</param>
    procedure RegistrarAuditoria(const ATipoAcao, AEntidade: string;
      AEntidadeId: Integer; const ADetalhes: string);
  end;

implementation

{ TControllerBase<T> }

constructor TControllerBase<T>.Create;
begin
  inherited Create;
  FUsarMock := True;
  FEntidade := T.Create;
  CriarDAO;
end;

constructor TControllerBase<T>.Create(const AId: Integer);
var
  LEntidadeCarregada: T;
begin
  inherited Create;
  FUsarMock := True;
  FEntidade := T.Create;
  CriarDAO;

  // Carrega a entidade pelo Id
  LEntidadeCarregada := FDAO.Find(AId);
  if Assigned(LEntidadeCarregada) then
  begin
    FEntidade.Free;
    FEntidade := LEntidadeCarregada;
  end;
end;

destructor TControllerBase<T>.Destroy;
begin
  if Assigned(FEntidade) then
    FEntidade.Free;
  // FDAO é interface, liberado automaticamente por reference counting
  inherited;
end;

procedure TControllerBase<T>.CriarDAO;
begin
  if FUsarMock then
    FDAO := TMockDAO<T>.Create
  else
  begin
    // TODO: Criar DAO real com FenixORM quando integração com banco estiver pronta
    FDAO := TMockDAO<T>.Create;
  end;
end;

function TControllerBase<T>.GetNomeTabela: string;
var
  LContexto: TRttiContext;
  LTipo: TRttiType;
  LAtributo: TCustomAttribute;
begin
  Result := '';
  LTipo := LContexto.GetType(TypeInfo(T));
  if Assigned(LTipo) then
  begin
    for LAtributo in LTipo.GetAttributes do
    begin
      if LAtributo is Tabela then
      begin
        Result := (LAtributo as Tabela).Name;
        Exit;
      end;
    end;
  end;
end;

function TControllerBase<T>.Gravar: Boolean;
begin
  Result := FDAO.Save(FEntidade);
end;

function TControllerBase<T>.Delete: Boolean;
begin
  Result := FDAO.Delete(FEntidade);
end;

procedure TControllerBase<T>.RegistrarAuditoria(const ATipoAcao, AEntidade: string;
  AEntidadeId: Integer; const ADetalhes: string);
var
  LLog: TLogAuditoria;
  LDAOAuditoria: IDAO<TLogAuditoria>;
begin
  LLog := TLogAuditoria.Create;
  try
    LLog.Colaborador_Id := ColaboradorLogadoId;
    LLog.Tipo_Acao := ATipoAcao;
    LLog.Entidade := AEntidade;
    LLog.Entidade_Id := AEntidadeId;
    LLog.Detalhes := ADetalhes;
    LLog.Data_Hora := Now;

    LDAOAuditoria := TMockDAO<TLogAuditoria>.Create;
    LDAOAuditoria.Save(LLog);
  finally
    LLog.Free;
  end;
end;

end.
