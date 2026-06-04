unit Controller.Colaborador;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Controller.Base,
  Model.Entidade.Colaborador,
  Mock.DAO,
  Utils.Exceptions;

type
  /// <summary>
  /// Controller para gestão de Colaboradores.
  /// Implementa validações de cadastro (nome, CPF, email, telefone, senha),
  /// unicidade de CPF e email, hash de senha, ativação/desativação e desbloqueio.
  /// </summary>
  TControllerColaborador = class(TControllerBase<TColaborador>)
  private
    /// <summary>Remove caracteres não numéricos de uma string.</summary>
    function ApenasDigitos(const AValor: string): string;
    /// <summary>
    /// Gera hash da senha. Implementação mock usando hash simples.
    /// Será substituída por Service.Autenticacao.GerarHash na integração real.
    /// </summary>
    class function GerarHashSenha(const ASenha: string): string;
  public
    /// <summary>
    /// Valida todos os campos da entidade Colaborador:
    /// - Nome: 3 a 120 caracteres
    /// - CPF: 11 dígitos numéricos válidos (formato e dígitos verificadores)
    /// - Email: deve conter @ e . (validação simples)
    /// - Telefone: 10 ou 11 dígitos numéricos
    /// - Senha_Hash: obrigatório para novo registro (Id=0)
    /// - CPF não editável após criação (Id>0)
    /// Lança EValidacaoException em caso de falha.
    /// </summary>
    function Validar: Boolean; override;

    /// <summary>
    /// Valida formato do CPF: exatamente 11 dígitos numéricos e
    /// dígitos verificadores corretos (algoritmo padrão da Receita Federal).
    /// </summary>
    function ValidarCPF(const ACPF: string): Boolean;

    /// <summary>
    /// Verifica se o CPF da entidade atual já existe no DAO,
    /// excluindo o registro com o Id atual (para edição).
    /// </summary>
    function ValidarUnicidadeCPF: Boolean;

    /// <summary>
    /// Verifica se o Email da entidade atual já existe no DAO,
    /// excluindo o registro com o Id atual (para edição).
    /// </summary>
    function ValidarUnicidadeEmail: Boolean;

    /// <summary>
    /// Grava o colaborador: valida campos, verifica unicidade de CPF e email,
    /// aplica hash na senha para novos registros, então persiste via DAO.
    /// Retorna True se a operação foi bem-sucedida.
    /// </summary>
    function Gravar: Boolean; override;

    /// <summary>
    /// Desativa o colaborador: define Situacao=0 e atualiza no DAO.
    /// </summary>
    procedure Desativar;

    /// <summary>
    /// Reativa o colaborador: define Situacao=1 e atualiza no DAO.
    /// </summary>
    procedure Reativar;

    /// <summary>
    /// Desbloqueia a conta do colaborador: zera Tentativas_Login,
    /// limpa Data_Bloqueio e atualiza no DAO.
    /// </summary>
    procedure DesbloquearConta;
  end;

implementation

{ TControllerColaborador }

class function TControllerColaborador.GerarHashSenha(const ASenha: string): string;
var
  I: Integer;
  LHash: Cardinal;
begin
  // Implementação mock de hash para fase de validação de layout.
  // Na integração real, delegar para Service.Autenticacao.GerarHash (bcrypt/SHA-256).
  LHash := 5381;
  for I := 1 to Length(ASenha) do
    LHash := ((LHash shl 5) + LHash) + Ord(ASenha[I]);
  Result := 'HASH_' + IntToHex(LHash, 8);
end;

function TControllerColaborador.ApenasDigitos(const AValor: string): string;
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

function TControllerColaborador.ValidarCPF(const ACPF: string): Boolean;
var
  LDigitos: string;
  I, LSoma, LResto, LDigito: Integer;
begin
  Result := False;
  LDigitos := ApenasDigitos(ACPF);

  // Deve ter exatamente 11 dígitos
  if Length(LDigitos) <> 11 then
    Exit;

  // Rejeitar CPFs com todos os dígitos iguais (ex: 000.000.000-00)
  if (LDigitos = StringOfChar(LDigitos[1], 11)) then
    Exit;

  // Validar primeiro dígito verificador
  LSoma := 0;
  for I := 1 to 9 do
    LSoma := LSoma + StrToInt(LDigitos[I]) * (11 - I);
  LResto := LSoma mod 11;
  if LResto < 2 then
    LDigito := 0
  else
    LDigito := 11 - LResto;
  if StrToInt(LDigitos[10]) <> LDigito then
    Exit;

  // Validar segundo dígito verificador
  LSoma := 0;
  for I := 1 to 10 do
    LSoma := LSoma + StrToInt(LDigitos[I]) * (12 - I);
  LResto := LSoma mod 11;
  if LResto < 2 then
    LDigito := 0
  else
    LDigito := 11 - LResto;
  if StrToInt(LDigitos[11]) <> LDigito then
    Exit;

  Result := True;
end;

function TControllerColaborador.Validar: Boolean;
var
  LNome, LCPF, LEmail, LTelefone, LSenha: string;
  LDigitosTelefone: string;
  LPosArroba, LPosPonto: Integer;
  LExistente: TColaborador;
begin
  Result := False;

  // Validar Nome: 3 a 120 caracteres
  LNome := Trim(Entidade.Nome);
  if (Length(LNome) < 3) or (Length(LNome) > 120) then
    raise EValidacaoException.Create('Nome', 'Nome deve ter entre 3 e 120 caracteres.');

  // Validar CPF: 11 dígitos numéricos válidos
  LCPF := ApenasDigitos(Entidade.CPF);
  if not ValidarCPF(LCPF) then
    raise EValidacaoException.Create('CPF', 'CPF inválido. Informe 11 dígitos numéricos válidos.');

  // CPF não pode ser alterado após criação (Id > 0)
  if Entidade.Id > 0 then
  begin
    LExistente := DAO.Find(Entidade.Id);
    if Assigned(LExistente) then
    begin
      try
        if ApenasDigitos(LExistente.CPF) <> LCPF then
          raise EValidacaoException.Create('CPF', 'CPF não pode ser alterado após o cadastro.');
      finally
        LExistente.Free;
      end;
    end;
  end;

  // Validar Email: deve conter @ e . (validação simples)
  LEmail := Trim(Entidade.Email);
  if LEmail = '' then
    raise EValidacaoException.Create('Email', 'Email é obrigatório.');
  LPosArroba := Pos('@', LEmail);
  if LPosArroba < 2 then
    raise EValidacaoException.Create('Email', 'Email deve conter @.');
  LPosPonto := Pos('.', Copy(LEmail, LPosArroba + 1, Length(LEmail)));
  if LPosPonto < 2 then
    raise EValidacaoException.Create('Email', 'Email deve conter domínio válido com ponto.');
  if Length(LEmail) > 255 then
    raise EValidacaoException.Create('Email', 'Email deve ter no máximo 255 caracteres.');

  // Validar Telefone: 10 ou 11 dígitos numéricos
  LDigitosTelefone := ApenasDigitos(Entidade.Telefone);
  if (Length(LDigitosTelefone) < 10) or (Length(LDigitosTelefone) > 11) then
    raise EValidacaoException.Create('Telefone', 'Telefone deve ter 10 ou 11 dígitos numéricos.');

  // Validar Senha: mínimo 6 caracteres (obrigatório apenas para novo registro)
  if Entidade.Id = 0 then
  begin
    LSenha := Entidade.Senha_Hash;
    if Length(LSenha) < 6 then
      raise EValidacaoException.Create('Senha', 'Senha deve ter no mínimo 6 caracteres.');
  end;

  Result := True;
end;

function TControllerColaborador.ValidarUnicidadeCPF: Boolean;
var
  LDigitosCPF: string;
  LExistentes: TObjectList<TColaborador>;
  I: Integer;
begin
  Result := True;
  LDigitosCPF := ApenasDigitos(Entidade.CPF);

  LExistentes := DAO.Where('CPF', TValue.From<string>(LDigitosCPF)).FindAll;
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

function TControllerColaborador.ValidarUnicidadeEmail: Boolean;
var
  LEmail: string;
  LExistentes: TObjectList<TColaborador>;
  I: Integer;
begin
  Result := True;
  LEmail := Trim(Entidade.Email);

  LExistentes := DAO.Where('Email', TValue.From<string>(LEmail)).FindAll;
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

function TControllerColaborador.Gravar: Boolean;
var
  LIsNovo: Boolean;
  LSenhaOriginal: string;
begin
  Result := False;

  // Validar campos
  if not Validar then
    Exit;

  // Verificar unicidade de CPF
  if not ValidarUnicidadeCPF then
    raise EValidacaoException.Create('CPF', 'CPF já está registrado para outro colaborador.');

  // Verificar unicidade de Email
  if not ValidarUnicidadeEmail then
    raise EValidacaoException.Create('Email', 'Email já está registrado para outro colaborador.');

  LIsNovo := (Entidade.Id = 0);

  // Para novos registros, aplica hash na senha antes de gravar
  if LIsNovo then
  begin
    LSenhaOriginal := Entidade.Senha_Hash;
    // Aplica hash simples (mock) — será substituído por Service.Autenticacao.GerarHash
    // quando o service estiver disponível
    Entidade.Senha_Hash := GerarHashSenha(LSenhaOriginal);
    Entidade.Data_Cadastro := Now;
  end;

  // Gravar via DAO (inherited)
  Result := inherited Gravar;

  // Registrar auditoria
  if Result then
  begin
    if LIsNovo then
      RegistrarAuditoria('INSERT', 'COLABORADOR', Entidade.Id,
        'Cadastro de colaborador: ' + Entidade.Nome)
    else
      RegistrarAuditoria('UPDATE', 'COLABORADOR', Entidade.Id,
        'Edição de colaborador: ' + Entidade.Nome);
  end;
end;

procedure TControllerColaborador.Desativar;
begin
  Entidade.Situacao := 0;
  DAO.Update(Entidade);
  RegistrarAuditoria('UPDATE', 'COLABORADOR', Entidade.Id,
    'Colaborador desativado: ' + Entidade.Nome);
end;

procedure TControllerColaborador.Reativar;
begin
  Entidade.Situacao := 1;
  DAO.Update(Entidade);
  RegistrarAuditoria('UPDATE', 'COLABORADOR', Entidade.Id,
    'Colaborador reativado: ' + Entidade.Nome);
end;

procedure TControllerColaborador.DesbloquearConta;
begin
  Entidade.Tentativas_Login := 0;
  Entidade.Data_Bloqueio := 0;
  DAO.Update(Entidade);
  RegistrarAuditoria('UPDATE', 'COLABORADOR', Entidade.Id,
    'Conta desbloqueada: ' + Entidade.Nome);
end;

end.
