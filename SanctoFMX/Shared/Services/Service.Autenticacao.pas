unit Service.Autenticacao;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  System.RTTI,
  System.Generics.Collections,
  Mock.DAO,
  Model.Entidade.Colaborador,
  Model.Entidade.LogAuditoria,
  Rtti.Atributos,
  Utils.Exceptions,
  Controller.Base;

type
  /// <summary>
  /// Resultado da tentativa de login.
  /// </summary>
  TResultadoLogin = (
    rlSucesso,            // Login realizado com sucesso
    rlCredencialInvalida, // CPF inexistente ou senha incorreta
    rlContaBloqueada,     // Conta bloqueada por excesso de tentativas
    rlContaInativa,       // Conta desativada pelo administrador
    rlErroInterno         // Erro inesperado no processo de autenticação
  );

  /// <summary>
  /// Serviço de autenticação responsável por login, logout, controle de
  /// sessão, bloqueio por tentativas falhas e hash de senhas.
  /// Utiliza IDAO<TColaborador> para acesso a dados (MockDAO na fase atual).
  /// </summary>
  TServiceAutenticacao = class
  private
    FMaxTentativas: Integer;
    FTempoBloqueioMin: Integer;
    FTimeoutSessaoMin: Integer;
    FDAOColaborador: IDAO<TColaborador>;
    FDAOAuditoria: IDAO<TLogAuditoria>;

    /// <summary>
    /// Verifica se a conta está atualmente bloqueada.
    /// Uma conta está bloqueada se Data_Bloqueio está dentro dos últimos
    /// FTempoBloqueioMin minutos.
    /// </summary>
    function VerificarBloqueio(AColaborador: TColaborador): Boolean;

    /// <summary>
    /// Incrementa o contador de tentativas falhas do colaborador.
    /// Se atingir FMaxTentativas, bloqueia a conta.
    /// </summary>
    procedure IncrementarTentativas(AColaborador: TColaborador);

    /// <summary>
    /// Bloqueia a conta definindo Data_Bloqueio como Now e zerando tentativas.
    /// Registra o evento de bloqueio no log de auditoria.
    /// </summary>
    procedure BloquearConta(AColaborador: TColaborador);

    /// <summary>
    /// Zera o contador de tentativas após login bem-sucedido.
    /// </summary>
    procedure ZerarTentativas(AColaborador: TColaborador);

    /// <summary>
    /// Registra uma ação de auditoria no log do sistema.
    /// </summary>
    procedure RegistrarAuditoria(AColaboradorId: Integer;
      const ATipoAcao, ADetalhes: string);
  public
    constructor Create; overload;
    constructor Create(ADAOColaborador: IDAO<TColaborador>); overload;
    destructor Destroy; override;

    /// <summary>
    /// Realiza autenticação do colaborador por CPF e senha.
    /// Verifica status ativo, bloqueio, e hash de senha.
    /// Em caso de sucesso, reseta tentativas e registra acesso.
    /// </summary>
    function Login(const ACPF, ASenha: string): TResultadoLogin;

    /// <summary>
    /// Encerra a sessão do colaborador e registra no log de auditoria.
    /// </summary>
    procedure Logout(AColaboradorId: Integer);

    /// <summary>
    /// Verifica se a sessão expirou por inatividade.
    /// Retorna True se o tempo desde AUltimaAtividade excede FTimeoutSessaoMin.
    /// </summary>
    function SessaoExpirada(AUltimaAtividade: TDateTime): Boolean;

    /// <summary>
    /// Gera hash SHA-256 da senha com salt fixo.
    /// </summary>
    class function GerarHash(const ASenha: string): string;

    /// <summary>
    /// Verifica se a senha corresponde ao hash armazenado.
    /// </summary>
    class function VerificarHash(const ASenha, AHash: string): Boolean;

    /// <summary>Número máximo de tentativas antes do bloqueio (padrão: 5)</summary>
    property MaxTentativas: Integer read FMaxTentativas write FMaxTentativas;
    /// <summary>Tempo de bloqueio em minutos (padrão: 15)</summary>
    property TempoBloqueioMin: Integer read FTempoBloqueioMin write FTempoBloqueioMin;
    /// <summary>Timeout de sessão por inatividade em minutos (padrão: 30)</summary>
    property TimeoutSessaoMin: Integer read FTimeoutSessaoMin write FTimeoutSessaoMin;
    /// <summary>DAO de colaboradores (pode ser injetado para testes)</summary>
    property DAOColaborador: IDAO<TColaborador> read FDAOColaborador;
  end;

const
  /// <summary>
  /// Salt fixo utilizado na geração de hash de senhas.
  /// Em produção, deve ser substituído por salt individual por usuário.
  /// </summary>
  SALT_SENHA = 'SanctoPDV@2024#Salt!';

implementation

{ TServiceAutenticacao }

constructor TServiceAutenticacao.Create;
begin
  inherited Create;
  FMaxTentativas := 5;
  FTempoBloqueioMin := 15;
  FTimeoutSessaoMin := 30;
  FDAOColaborador := TMockDAO<TColaborador>.Create;
  FDAOAuditoria := TMockDAO<TLogAuditoria>.Create;
end;

constructor TServiceAutenticacao.Create(ADAOColaborador: IDAO<TColaborador>);
begin
  inherited Create;
  FMaxTentativas := 5;
  FTempoBloqueioMin := 15;
  FTimeoutSessaoMin := 30;
  FDAOColaborador := ADAOColaborador;
  FDAOAuditoria := TMockDAO<TLogAuditoria>.Create;
end;

destructor TServiceAutenticacao.Destroy;
begin
  // Interfaces são liberadas automaticamente por reference counting
  inherited Destroy;
end;

function TServiceAutenticacao.Login(const ACPF, ASenha: string): TResultadoLogin;
var
  LLista: TObjectList<TColaborador>;
  LColaborador: TColaborador;
begin
  Result := rlErroInterno;

  try
    // Busca colaborador pelo CPF
    LLista := FDAOColaborador.Where('CPF', ACPF).FindAll;
    try
      // CPF não encontrado — credencial inválida
      if LLista.Count = 0 then
      begin
        Result := rlCredencialInvalida;
        Exit;
      end;

      LColaborador := LLista[0];

      // Verificar se a conta está ativa (Situacao = 1)
      if LColaborador.Situacao <> 1 then
      begin
        Result := rlContaInativa;
        Exit;
      end;

      // Verificar se a conta está bloqueada
      if VerificarBloqueio(LColaborador) then
      begin
        Result := rlContaBloqueada;
        Exit;
      end;

      // Verificar senha
      if not VerificarHash(ASenha, LColaborador.Senha_Hash) then
      begin
        // Senha incorreta: incrementar tentativas
        IncrementarTentativas(LColaborador);
        Result := rlCredencialInvalida;
        Exit;
      end;

      // Login bem-sucedido: zerar tentativas e registrar acesso
      ZerarTentativas(LColaborador);
      LColaborador.Ultimo_Acesso := Now;
      FDAOColaborador.Update(LColaborador);

      // Definir colaborador logado no controller base
      TControllerBase<TColaborador>.ColaboradorLogadoId := LColaborador.Id;

      // Registrar auditoria de login
      RegistrarAuditoria(LColaborador.Id, 'LOGIN',
        'Login realizado com sucesso. CPF: ' + ACPF);

      Result := rlSucesso;
    finally
      LLista.Free;
    end;
  except
    on E: Exception do
    begin
      Result := rlErroInterno;
    end;
  end;
end;

procedure TServiceAutenticacao.Logout(AColaboradorId: Integer);
var
  LColaborador: TColaborador;
begin
  LColaborador := FDAOColaborador.Find(AColaboradorId);
  try
    if Assigned(LColaborador) then
    begin
      // Registrar auditoria de logout
      RegistrarAuditoria(AColaboradorId, 'LOGOUT',
        'Logout realizado. Colaborador Id: ' + IntToStr(AColaboradorId));

      // Limpar colaborador logado
      if TControllerBase<TColaborador>.ColaboradorLogadoId = AColaboradorId then
        TControllerBase<TColaborador>.ColaboradorLogadoId := 0;
    end;
  finally
    LColaborador.Free;
  end;
end;

function TServiceAutenticacao.SessaoExpirada(AUltimaAtividade: TDateTime): Boolean;
begin
  // Sessão expira após FTimeoutSessaoMin minutos de inatividade
  Result := (Now - AUltimaAtividade) > (FTimeoutSessaoMin / (24 * 60));
end;

class function TServiceAutenticacao.GerarHash(const ASenha: string): string;
begin
  // SHA-256 com salt fixo prefixado
  Result := THashSHA2.GetHashString(SALT_SENHA + ASenha, THashSHA2.TSHA2Version.SHA256);
end;

class function TServiceAutenticacao.VerificarHash(const ASenha, AHash: string): Boolean;
begin
  Result := SameText(GerarHash(ASenha), AHash);
end;

function TServiceAutenticacao.VerificarBloqueio(AColaborador: TColaborador): Boolean;
var
  LMinutosDesdeBlockeio: Double;
begin
  Result := False;

  // Se Data_Bloqueio é 0 (não definida), a conta não está bloqueada
  if AColaborador.Data_Bloqueio = 0 then
    Exit;

  // Calcular minutos desde o bloqueio
  LMinutosDesdeBlockeio := MinutesBetween(Now, AColaborador.Data_Bloqueio);

  // A conta está bloqueada se o bloqueio ocorreu há menos de FTempoBloqueioMin minutos
  Result := LMinutosDesdeBlockeio < FTempoBloqueioMin;
end;

procedure TServiceAutenticacao.IncrementarTentativas(AColaborador: TColaborador);
begin
  AColaborador.Tentativas_Login := AColaborador.Tentativas_Login + 1;

  // Se atingiu o máximo de tentativas, bloquear a conta
  if AColaborador.Tentativas_Login >= FMaxTentativas then
    BloquearConta(AColaborador)
  else
    FDAOColaborador.Update(AColaborador);
end;

procedure TServiceAutenticacao.BloquearConta(AColaborador: TColaborador);
begin
  AColaborador.Data_Bloqueio := Now;
  AColaborador.Tentativas_Login := 0;
  FDAOColaborador.Update(AColaborador);

  // Registrar bloqueio na auditoria
  RegistrarAuditoria(AColaborador.Id, 'BLOQUEIO',
    'Conta bloqueada por ' + IntToStr(FMaxTentativas) +
    ' tentativas de login falhas consecutivas. CPF: ' + AColaborador.CPF);
end;

procedure TServiceAutenticacao.ZerarTentativas(AColaborador: TColaborador);
begin
  if AColaborador.Tentativas_Login > 0 then
  begin
    AColaborador.Tentativas_Login := 0;
    FDAOColaborador.Update(AColaborador);
  end;
end;

procedure TServiceAutenticacao.RegistrarAuditoria(AColaboradorId: Integer;
  const ATipoAcao, ADetalhes: string);
var
  LLog: TLogAuditoria;
begin
  LLog := TLogAuditoria.Create;
  try
    LLog.Colaborador_Id := AColaboradorId;
    LLog.Tipo_Acao := ATipoAcao;
    LLog.Entidade := 'COLABORADOR';
    LLog.Entidade_Id := AColaboradorId;
    LLog.Detalhes := ADetalhes;
    LLog.Data_Hora := Now;
    FDAOAuditoria.Save(LLog);
  finally
    LLog.Free;
  end;
end;

end.
