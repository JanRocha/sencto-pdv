unit Frm.Login;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  System.RTTI,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Objects,
  FMX.Layouts,
  FMX.Effects,
  FMX.Controls.Presentation,
  FMX.Graphics,
  FMX.Ani,
  Service.Autenticacao,
  Model.Entidade.Colaborador,
  Mock.DAO;

type
  /// <summary>
  /// Form de Login compartilhado entre PDV e Backoffice.
  /// O layout visual e definido no Frm.Login.fmx (editavel no Designer).
  /// Esta unit contem apenas a logica de autenticacao, mascara de CPF,
  /// toggle de senha e mensagens de erro/bloqueio.
  /// </summary>
  TFrmLogin = class(TForm)
    { Componentes publicados do .fmx }
    RectFundo: TRectangle;
    LayoutPrincipal: TLayout;
    RectCard: TRectangle;
    ShadowCard: TShadowEffect;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblCPF: TLabel;
    EdtCPF: TEdit;
    lblSenha: TLabel;
    EdtSenha: TEdit;
    BtnToggleSenha: TSpeedButton;
    BtnLogin: TRectangle;
    lblBtnLogin: TLabel;
    lblErro: TLabel;
    lblBloqueio: TLabel;
    Image1: TImage;
    Label1: TLabel;

    { Eventos publicado
    Rectangle1: TRectangle;s }
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
    procedure BtnToggleSenhaClick(Sender: TObject);
    procedure EdtCPFKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure EdtCPFChangeTracking(Sender: TObject);
    procedure EdtSenhaKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure lblLogoIconClick(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Rectangle1Click(Sender: TObject);
  private
    { Service }
    FServiceAutenticacao: TServiceAutenticacao;

    { Resultado }
    FColaboradorLogadoId: Integer;
    FColaboradorLogadoNome: string;
    FColaboradorLogadoPapel: string;

    { Helpers }
    procedure MostrarErro(const AMensagem: string);
    procedure MostrarBloqueio(AMinutosRestantes: Integer);
    procedure LimparMensagens;
    function ExtrairCPFNumeros(const ACPF: string): string;
    function FormatarCPF(const ANumeros: string): string;
    procedure ExecutarLogin;
    procedure CarregarDadosColaborador(const ACPF: string);
    procedure CriarUsuarioMock;
  public
    /// <summary>Id do colaborador autenticado após login com sucesso</summary>
    property ColaboradorLogadoId: Integer read FColaboradorLogadoId;
    /// <summary>Nome do colaborador autenticado</summary>
    property ColaboradorLogadoNome: string read FColaboradorLogadoNome;
    /// <summary>Papel do colaborador autenticado (ADMINISTRADOR, GERENTE, OPERACIONAL)</summary>
    property ColaboradorLogadoPapel: string read FColaboradorLogadoPapel;
    /// <summary>Serviço de autenticação (pode ser injetado para testes)</summary>
    property ServiceAutenticacao: TServiceAutenticacao read FServiceAutenticacao
      write FServiceAutenticacao;
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.fmx}

{ TFrmLogin }

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
  FColaboradorLogadoId := 0;
  FColaboradorLogadoNome := '';
  FColaboradorLogadoPapel := '';

  FServiceAutenticacao := TServiceAutenticacao.Create;

  // Seed: criar colaborador admin padrão para teste
  CriarUsuarioMock;
end;

procedure TFrmLogin.FormDestroy(Sender: TObject);
begin
  FServiceAutenticacao.Free;
end;

procedure TFrmLogin.Label1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFrmLogin.lblLogoIconClick(Sender: TObject);
begin

end;

{ Event Handlers }

procedure TFrmLogin.BtnLoginClick(Sender: TObject);
begin
  LimparMensagens;
  ExecutarLogin;
end;

procedure TFrmLogin.BtnToggleSenhaClick(Sender: TObject);
begin
  EdtSenha.Password := not EdtSenha.Password;
  if EdtSenha.Password then
    BtnToggleSenha.Text := 'ver'
  else
    BtnToggleSenha.Text := 'ocultar';
end;

procedure TFrmLogin.EdtCPFKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  // Permitir apenas dígitos, backspace, delete, tab e setas
  if not (CharInSet(KeyChar, ['0'..'9', #0, #8]) or
     (Key in [vkBack, vkDelete, vkLeft, vkRight, vkTab])) then
  begin
    KeyChar := #0;
    Key := 0;
  end;
end;

procedure TFrmLogin.EdtCPFChangeTracking(Sender: TObject);
begin
  // Nao aplicamos mascara em tempo real no FMX 10.2 (conflito de cursor).
  // Apenas limitamos a 14 chars e o placeholder orienta o formato.
  // A validacao extrai somente os digitos.
end;

procedure TFrmLogin.EdtSenhaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  // Enter no campo senha submete o login
  if Key = vkReturn then
  begin
    Key := 0;
    KeyChar := #0;
    BtnLoginClick(Self);
  end;
end;

{ Helpers }

procedure TFrmLogin.MostrarErro(const AMensagem: string);
begin
  lblErro.Text := AMensagem;
  lblErro.Visible := True;
end;

procedure TFrmLogin.Rectangle1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFrmLogin.MostrarBloqueio(AMinutosRestantes: Integer);
begin
  lblBloqueio.Text := Format(
    'Conta bloqueada. Tente novamente em %d minuto(s).', [AMinutosRestantes]);
  lblBloqueio.Visible := True;
end;

procedure TFrmLogin.LimparMensagens;
begin
  lblErro.Visible := False;
  lblErro.Text := '';
  lblBloqueio.Visible := False;
  lblBloqueio.Text := '';
end;

function TFrmLogin.ExtrairCPFNumeros(const ACPF: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(ACPF) do
  begin
    if CharInSet(ACPF[I], ['0'..'9']) then
      Result := Result + ACPF[I];
  end;
end;

function TFrmLogin.FormatarCPF(const ANumeros: string): string;
var
  LLen: Integer;
begin
  Result := '';
  LLen := Length(ANumeros);

  if LLen = 0 then
    Exit;

  // Formata progressivamente: 000.000.000-00
  if LLen <= 3 then
    Result := ANumeros
  else if LLen <= 6 then
    Result := Copy(ANumeros, 1, 3) + '.' + Copy(ANumeros, 4, LLen - 3)
  else if LLen <= 9 then
    Result := Copy(ANumeros, 1, 3) + '.' + Copy(ANumeros, 4, 3) + '.' +
              Copy(ANumeros, 7, LLen - 6)
  else
    Result := Copy(ANumeros, 1, 3) + '.' + Copy(ANumeros, 4, 3) + '.' +
              Copy(ANumeros, 7, 3) + '-' + Copy(ANumeros, 10, LLen - 9);
end;

procedure TFrmLogin.ExecutarLogin;
var
  LCPF: string;
  LSenha: string;
  LResultado: TResultadoLogin;
begin
  LCPF := ExtrairCPFNumeros(EdtCPF.Text);
  LSenha := EdtSenha.Text;

  // Validação local básica
  if Length(LCPF) < 11 then
  begin
    MostrarErro('Informe o CPF completo.');
    EdtCPF.SetFocus;
    Exit;
  end;

  if LSenha.IsEmpty then
  begin
    MostrarErro('Informe a senha.');
    EdtSenha.SetFocus;
    Exit;
  end;

  // Chamar serviço de autenticação
  LResultado := FServiceAutenticacao.Login(LCPF, LSenha);

  case LResultado of
    rlSucesso:
    begin
      // Carregar dados do colaborador logado
      CarregarDadosColaborador(LCPF);
      ModalResult := mrOk;
    end;

    rlCredencialInvalida:
    begin
      // Mensagem genérica: não revelar se CPF ou senha está incorreto (req 1.2)
      MostrarErro('Credenciais inválidas.');
      EdtSenha.Text := '';
      EdtSenha.SetFocus;
    end;

    rlContaBloqueada:
    begin
      // Calcular tempo restante de bloqueio e exibir (req 1.4)
      MostrarErro('Conta bloqueada por excesso de tentativas.');
      MostrarBloqueio(FServiceAutenticacao.TempoBloqueioMin);
    end;

    rlContaInativa:
    begin
      // Mensagem genérica: não revelar que a conta está inativa (req 1.10)
      MostrarErro('Credenciais inválidas.');
      EdtSenha.Text := '';
      EdtSenha.SetFocus;
    end;

    rlErroInterno:
    begin
      MostrarErro('Erro interno. Tente novamente.');
    end;
  end;
end;

procedure TFrmLogin.CarregarDadosColaborador(const ACPF: string);
var
  LLista: TObjectList<TColaborador>;
begin
  LLista := FServiceAutenticacao.DAOColaborador.Where('CPF', ACPF).FindAll;
  try
    if LLista.Count > 0 then
    begin
      FColaboradorLogadoId := LLista[0].Id;
      FColaboradorLogadoNome := LLista[0].Nome;
      FColaboradorLogadoPapel := LLista[0].Papel;
    end;
  finally
    LLista.Free;
  end;
end;

procedure TFrmLogin.CriarUsuarioMock;
var
  LAdmin: TColaborador;
begin
  // Criar usuário admin padrão para testes
  // CPF: 12345678901 / Senha: admin1
  LAdmin := TColaborador.Create;
  try
    LAdmin.Nome := 'Admin Sancto';
    LAdmin.CPF := '12345678901';
    LAdmin.Email := 'admin@sancto.com.br';
    LAdmin.Telefone := '11999999999';
    LAdmin.Senha_Hash := TServiceAutenticacao.GerarHash('admin1');
    LAdmin.Papel := 'ADMINISTRADOR';
    LAdmin.Situacao := 1;
    LAdmin.Tentativas_Login := 0;
    LAdmin.Data_Cadastro := Now;
    FServiceAutenticacao.DAOColaborador.Insert(LAdmin);
  finally
    LAdmin.Free;
  end;
end;

end.
