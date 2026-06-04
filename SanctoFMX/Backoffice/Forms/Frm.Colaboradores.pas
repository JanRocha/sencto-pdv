unit Frm.Colaboradores;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.Graphics,
  FMX.Edit,
  FMX.ListBox,
  FMX.DialogService,
  Model.Entidade.Colaborador,
  Controller.Colaborador;

type
  /// <summary>
  /// Tela CRUD de Colaboradores no Backoffice.
  /// Grid com Nome, CPF, Email, Papel, Status, Ultimo Acesso, Acoes.
  /// Form overlay para cadastro/edicao.
  /// Criada programaticamente (sem .fmx).
  /// </summary>
  TFrmColaboradores = class(TFrame)
  private
    { Controller }
    FController: TControllerColaborador;

    { Mock data }
    FColaboradores: TObjectList<TColaborador>;
    FColaboradorEditando: TColaborador;
    FModoEdicao: Boolean;

    { ID do colaborador logado — impede auto-desativacao }
    FColaboradorLogadoId: Integer;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Header — Titulo + Busca + Botao Novo }
    FLayoutHeader: TLayout;
    FLblTitulo: TLabel;
    FEdtBusca: TEdit;
    FCmbFiltroPapel: TComboBox;
    FBtnNovo: TButton;

    { Grid area — lista de colaboradores }
    FLayoutGrid: TLayout;
    FScrollGrid: TVertScrollBox;
    FLayoutGridHeader: TLayout;

    { Form overlay — cadastro/edicao }
    FLayoutOverlay: TLayout;
    FRectOverlay: TRectangle;
    FLayoutForm: TLayout;
    FRectForm: TRectangle;
    FLblFormTitulo: TLabel;
    FEdtNome: TEdit;
    FEdtCPF: TEdit;
    FEdtEmail: TEdit;
    FEdtTelefone: TEdit;
    FEdtSenha: TEdit;
    FEdtConfirmarSenha: TEdit;
    FBtnToggleSenha: TButton;
    FCmbPapel: TComboBox;
    FSwitchAtivo: TSwitch;
    FLblAtivo: TLabel;
    FBtnSalvar: TButton;
    FBtnCancelarForm: TButton;

    { Senha visivel }
    FSenhaVisivel: Boolean;

    procedure CriarComponentes;
    procedure CriarHeader;
    procedure CriarGridHeader;
    procedure CriarGridArea;
    procedure CriarFormOverlay;

    { Mock data }
    procedure PopularDadosMock;

    { Grid }
    procedure RenderizarGrid;
    function CriarLinhaColaborador(AColab: TColaborador; AIndex: Integer): TLayout;

    { Filtro }
    procedure EdtBuscaChange(Sender: TObject);
    procedure CmbFiltroPapelChange(Sender: TObject);
    function ColaboradorPassaFiltro(AColab: TColaborador): Boolean;

    { Acoes }
    procedure BtnNovoClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnDesativarClick(Sender: TObject);
    procedure BtnDesbloquearClick(Sender: TObject);
    procedure BtnExcluirClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarFormClick(Sender: TObject);
    procedure BtnToggleSenhaClick(Sender: TObject);

    { Form }
    procedure AbrirForm(AColab: TColaborador);
    procedure FecharForm;
    procedure LimparForm;
    procedure PreencherFormComColaborador(AColab: TColaborador);

    { Helpers }
    function FormatarCPF(const ACPF: string): string;
    function FormatarStatus(ASituacao: Integer): string;
    function FormatarUltimoAcesso(AData: TDateTime): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ColaboradorLogadoId: Integer read FColaboradorLogadoId write FColaboradorLogadoId;
  end;

implementation

const
  COR_FUNDO = $FFF5F5F5;
  COR_HEADER = $FFFFFFFF;
  COR_GRID_HEADER = $FFE3F2FD;
  COR_LINHA_PAR = $FFFFFFFF;
  COR_LINHA_IMPAR = $FFFAFAFA;
  COR_BTN_NOVO = $FF1E88E5;
  COR_BTN_EDITAR = $FF1976D2;
  COR_BTN_DESATIVAR = $FFFF9800;
  COR_BTN_REATIVAR = $FF4CAF50;
  COR_BTN_DESBLOQUEAR = $FF9C27B0;
  COR_BTN_EXCLUIR = $FFE53935;
  COR_BTN_SALVAR = $FF4CAF50;
  COR_BTN_CANCELAR = $FF757575;
  COR_OVERLAY = $99000000;
  COR_FORM_BG = $FFFFFFFF;
  COR_ATIVO = $FF4CAF50;
  COR_INATIVO = $FFE53935;
  COR_BLOQUEADO = $FF9C27B0;

  FONT_TITULO = 22;
  FONT_BTN = 14;
  FONT_GRID = 13;
  FONT_GRID_HEADER = 13;
  HEADER_HEIGHT = 60;
  GRID_HEADER_HEIGHT = 36;
  LINHA_HEIGHT = 44;
  FORM_WIDTH = 480;
  FORM_HEIGHT = 560;

{ TFrmColaboradores }

constructor TFrmColaboradores.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FController := TControllerColaborador.Create;
  FColaboradores := TObjectList<TColaborador>.Create(True);
  FColaboradorEditando := nil;
  FModoEdicao := False;
  FSenhaVisivel := False;
  FColaboradorLogadoId := 1; // Default: primeiro colaborador (admin)

  Align := TAlignLayout.Client;

  CriarComponentes;
  PopularDadosMock;
  RenderizarGrid;
end;

destructor TFrmColaboradores.Destroy;
begin
  FColaboradores.Free;
  FController.Free;
  inherited Destroy;
end;

procedure TFrmColaboradores.CriarComponentes;
begin
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;

  CriarHeader;
  CriarGridHeader;
  CriarGridArea;
  CriarFormOverlay;
end;

procedure TFrmColaboradores.CriarHeader;
begin
  FLayoutHeader := TLayout.Create(Self);
  FLayoutHeader.Parent := FLayoutPrincipal;
  FLayoutHeader.Align := TAlignLayout.Top;
  FLayoutHeader.Height := HEADER_HEIGHT;
  FLayoutHeader.Padding.Left := 16;
  FLayoutHeader.Padding.Right := 16;

  // Titulo
  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := FLayoutHeader;
  FLblTitulo.Align := TAlignLayout.Left;
  FLblTitulo.Width := 200;
  FLblTitulo.Text := 'Colaboradores';
  FLblTitulo.StyledSettings := [];
  FLblTitulo.TextSettings.Font.Size := FONT_TITULO;
  FLblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblTitulo.TextSettings.FontColor := $FF212121;
  FLblTitulo.TextSettings.VertAlign := TTextAlign.Center;

  // Botao + Novo Colaborador
  FBtnNovo := TButton.Create(Self);
  FBtnNovo.Parent := FLayoutHeader;
  FBtnNovo.Align := TAlignLayout.Right;
  FBtnNovo.Width := 160;
  FBtnNovo.Height := 36;
  FBtnNovo.Text := '+ Novo Colaborador';
  FBtnNovo.StyledSettings := [];
  FBtnNovo.TextSettings.Font.Size := FONT_BTN;
  FBtnNovo.TextSettings.FontColor := $FFFFFFFF;
  FBtnNovo.OnClick := BtnNovoClick;
  FBtnNovo.Margins.Top := 12;
  FBtnNovo.Margins.Bottom := 12;

  // Filtro por papel
  FCmbFiltroPapel := TComboBox.Create(Self);
  FCmbFiltroPapel.Parent := FLayoutHeader;
  FCmbFiltroPapel.Align := TAlignLayout.Right;
  FCmbFiltroPapel.Width := 150;
  FCmbFiltroPapel.Height := 36;
  FCmbFiltroPapel.Items.Add('Todos os Papéis');
  FCmbFiltroPapel.Items.Add('ADMINISTRADOR');
  FCmbFiltroPapel.Items.Add('GERENTE');
  FCmbFiltroPapel.Items.Add('OPERACIONAL');
  FCmbFiltroPapel.ItemIndex := 0;
  FCmbFiltroPapel.OnChange := CmbFiltroPapelChange;
  FCmbFiltroPapel.Margins.Top := 12;
  FCmbFiltroPapel.Margins.Bottom := 12;
  FCmbFiltroPapel.Margins.Right := 8;

  // Campo de busca
  FEdtBusca := TEdit.Create(Self);
  FEdtBusca.Parent := FLayoutHeader;
  FEdtBusca.Align := TAlignLayout.Right;
  FEdtBusca.Width := 220;
  FEdtBusca.Height := 36;
  FEdtBusca.TextPrompt := 'Buscar por nome ou CPF...';
  FEdtBusca.StyledSettings := [];
  FEdtBusca.TextSettings.Font.Size := FONT_BTN;
  FEdtBusca.OnChange := EdtBuscaChange;
  FEdtBusca.Margins.Top := 12;
  FEdtBusca.Margins.Bottom := 12;
  FEdtBusca.Margins.Right := 8;
end;

procedure TFrmColaboradores.CriarGridHeader;
var
  LColunas: array[0..6] of record Nome: string; Largura: Single; end;
  I: Integer;
  LLbl: TLabel;
  LPosX: Single;
  LRect: TRectangle;
begin
  LColunas[0].Nome := 'Nome'; LColunas[0].Largura := 180;
  LColunas[1].Nome := 'CPF'; LColunas[1].Largura := 130;
  LColunas[2].Nome := 'Email'; LColunas[2].Largura := 180;
  LColunas[3].Nome := 'Papel'; LColunas[3].Largura := 120;
  LColunas[4].Nome := 'Status'; LColunas[4].Largura := 80;
  LColunas[5].Nome := 'Último Acesso'; LColunas[5].Largura := 130;
  LColunas[6].Nome := 'Ações'; LColunas[6].Largura := 220;

  FLayoutGridHeader := TLayout.Create(Self);
  FLayoutGridHeader.Parent := FLayoutPrincipal;
  FLayoutGridHeader.Align := TAlignLayout.Top;
  FLayoutGridHeader.Height := GRID_HEADER_HEIGHT;
  FLayoutGridHeader.Margins.Left := 16;
  FLayoutGridHeader.Margins.Right := 16;

  LRect := TRectangle.Create(Self);
  LRect.Parent := FLayoutGridHeader;
  LRect.Align := TAlignLayout.Client;
  LRect.Fill.Kind := TBrushKind.Solid;
  LRect.Fill.Color := COR_GRID_HEADER;
  LRect.Stroke.Kind := TBrushKind.None;
  LRect.XRadius := 4;
  LRect.YRadius := 4;
  LRect.HitTest := False;

  LPosX := 8;
  for I := 0 to 6 do
  begin
    LLbl := TLabel.Create(Self);
    LLbl.Parent := FLayoutGridHeader;
    LLbl.Position.X := LPosX;
    LLbl.Position.Y := 0;
    LLbl.Width := LColunas[I].Largura;
    LLbl.Height := GRID_HEADER_HEIGHT;
    LLbl.Text := LColunas[I].Nome;
    LLbl.StyledSettings := [];
    LLbl.TextSettings.Font.Size := FONT_GRID_HEADER;
    LLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLbl.TextSettings.FontColor := $FF1565C0;
    LLbl.TextSettings.VertAlign := TTextAlign.Center;
    LLbl.HitTest := False;
    LPosX := LPosX + LColunas[I].Largura;
  end;
end;

procedure TFrmColaboradores.CriarGridArea;
begin
  FLayoutGrid := TLayout.Create(Self);
  FLayoutGrid.Parent := FLayoutPrincipal;
  FLayoutGrid.Align := TAlignLayout.Client;
  FLayoutGrid.Margins.Left := 16;
  FLayoutGrid.Margins.Right := 16;
  FLayoutGrid.Margins.Bottom := 16;

  FScrollGrid := TVertScrollBox.Create(Self);
  FScrollGrid.Parent := FLayoutGrid;
  FScrollGrid.Align := TAlignLayout.Client;
  FScrollGrid.ShowScrollBars := True;
end;

procedure TFrmColaboradores.CriarFormOverlay;
var
  LLayoutCampos: TLayout;
  LLayoutBotoes: TLayout;
  LLayoutSenha: TLayout;
  LLayoutAtivo: TLayout;
  LLbl: TLabel;
begin
  // Overlay escuro (cobre a tela toda)
  FLayoutOverlay := TLayout.Create(Self);
  FLayoutOverlay.Parent := Self;
  FLayoutOverlay.Align := TAlignLayout.Contents;
  FLayoutOverlay.Visible := False;
  FLayoutOverlay.HitTest := True;

  FRectOverlay := TRectangle.Create(Self);
  FRectOverlay.Parent := FLayoutOverlay;
  FRectOverlay.Align := TAlignLayout.Client;
  FRectOverlay.Fill.Kind := TBrushKind.Solid;
  FRectOverlay.Fill.Color := COR_OVERLAY;
  FRectOverlay.Stroke.Kind := TBrushKind.None;
  FRectOverlay.HitTest := False;

  // Form centralizado
  FLayoutForm := TLayout.Create(Self);
  FLayoutForm.Parent := FLayoutOverlay;
  FLayoutForm.Align := TAlignLayout.Center;
  FLayoutForm.Width := FORM_WIDTH;
  FLayoutForm.Height := FORM_HEIGHT;

  FRectForm := TRectangle.Create(Self);
  FRectForm.Parent := FLayoutForm;
  FRectForm.Align := TAlignLayout.Client;
  FRectForm.Fill.Kind := TBrushKind.Solid;
  FRectForm.Fill.Color := COR_FORM_BG;
  FRectForm.Stroke.Kind := TBrushKind.None;
  FRectForm.XRadius := 8;
  FRectForm.YRadius := 8;
  FRectForm.HitTest := False;

  // Titulo do form
  FLblFormTitulo := TLabel.Create(Self);
  FLblFormTitulo.Parent := FLayoutForm;
  FLblFormTitulo.Align := TAlignLayout.Top;
  FLblFormTitulo.Height := 44;
  FLblFormTitulo.Text := 'Novo Colaborador';
  FLblFormTitulo.StyledSettings := [];
  FLblFormTitulo.TextSettings.Font.Size := 18;
  FLblFormTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFormTitulo.TextSettings.FontColor := $FF212121;
  FLblFormTitulo.TextSettings.HorzAlign := TTextAlign.Center;
  FLblFormTitulo.TextSettings.VertAlign := TTextAlign.Center;
  FLblFormTitulo.Margins.Top := 8;

  // Layout de campos
  LLayoutCampos := TLayout.Create(Self);
  LLayoutCampos.Parent := FLayoutForm;
  LLayoutCampos.Align := TAlignLayout.Client;
  LLayoutCampos.Padding.Left := 24;
  LLayoutCampos.Padding.Right := 24;
  LLayoutCampos.Padding.Top := 8;

  // Nome
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Nome *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FEdtNome := TEdit.Create(Self);
  FEdtNome.Parent := LLayoutCampos;
  FEdtNome.Align := TAlignLayout.Top;
  FEdtNome.Height := 32;
  FEdtNome.TextPrompt := 'Nome completo';
  FEdtNome.Margins.Bottom := 8;

  // CPF
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'CPF *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FEdtCPF := TEdit.Create(Self);
  FEdtCPF.Parent := LLayoutCampos;
  FEdtCPF.Align := TAlignLayout.Top;
  FEdtCPF.Height := 32;
  FEdtCPF.TextPrompt := '000.000.000-00';
  FEdtCPF.FilterChar := '0123456789.-';
  FEdtCPF.Margins.Bottom := 8;

  // Email
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Email *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FEdtEmail := TEdit.Create(Self);
  FEdtEmail.Parent := LLayoutCampos;
  FEdtEmail.Align := TAlignLayout.Top;
  FEdtEmail.Height := 32;
  FEdtEmail.TextPrompt := 'email@exemplo.com';
  FEdtEmail.Margins.Bottom := 8;

  // Telefone
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Telefone *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FEdtTelefone := TEdit.Create(Self);
  FEdtTelefone.Parent := LLayoutCampos;
  FEdtTelefone.Align := TAlignLayout.Top;
  FEdtTelefone.Height := 32;
  FEdtTelefone.TextPrompt := '(00) 00000-0000';
  FEdtTelefone.FilterChar := '0123456789()-. ';
  FEdtTelefone.Margins.Bottom := 8;

  // Senha
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Senha *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  LLayoutSenha := TLayout.Create(Self);
  LLayoutSenha.Parent := LLayoutCampos;
  LLayoutSenha.Align := TAlignLayout.Top;
  LLayoutSenha.Height := 32;
  LLayoutSenha.Margins.Bottom := 8;

  FEdtSenha := TEdit.Create(Self);
  FEdtSenha.Parent := LLayoutSenha;
  FEdtSenha.Align := TAlignLayout.Client;
  FEdtSenha.Password := True;
  FEdtSenha.TextPrompt := 'Mínimo 6 caracteres';

  FBtnToggleSenha := TButton.Create(Self);
  FBtnToggleSenha.Parent := LLayoutSenha;
  FBtnToggleSenha.Align := TAlignLayout.Right;
  FBtnToggleSenha.Width := 40;
  FBtnToggleSenha.Text := '👁';
  FBtnToggleSenha.StyledSettings := [];
  FBtnToggleSenha.TextSettings.Font.Size := 14;
  FBtnToggleSenha.OnClick := BtnToggleSenhaClick;

  // Confirmar Senha
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Confirmar Senha *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FEdtConfirmarSenha := TEdit.Create(Self);
  FEdtConfirmarSenha.Parent := LLayoutCampos;
  FEdtConfirmarSenha.Align := TAlignLayout.Top;
  FEdtConfirmarSenha.Height := 32;
  FEdtConfirmarSenha.Password := True;
  FEdtConfirmarSenha.TextPrompt := 'Repita a senha';
  FEdtConfirmarSenha.Margins.Bottom := 8;

  // Papel (Role)
  LLbl := TLabel.Create(Self);
  LLbl.Parent := LLayoutCampos;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 20;
  LLbl.Text := 'Papel *';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := $FF616161;

  FCmbPapel := TComboBox.Create(Self);
  FCmbPapel.Parent := LLayoutCampos;
  FCmbPapel.Align := TAlignLayout.Top;
  FCmbPapel.Height := 32;
  FCmbPapel.Items.Add('ADMINISTRADOR');
  FCmbPapel.Items.Add('GERENTE');
  FCmbPapel.Items.Add('OPERACIONAL');
  FCmbPapel.ItemIndex := 2;
  FCmbPapel.Margins.Bottom := 8;

  // Ativo toggle
  LLayoutAtivo := TLayout.Create(Self);
  LLayoutAtivo.Parent := LLayoutCampos;
  LLayoutAtivo.Align := TAlignLayout.Top;
  LLayoutAtivo.Height := 32;
  LLayoutAtivo.Margins.Bottom := 8;

  FLblAtivo := TLabel.Create(Self);
  FLblAtivo.Parent := LLayoutAtivo;
  FLblAtivo.Align := TAlignLayout.Left;
  FLblAtivo.Width := 60;
  FLblAtivo.Text := 'Ativo';
  FLblAtivo.StyledSettings := [];
  FLblAtivo.TextSettings.Font.Size := 13;
  FLblAtivo.TextSettings.FontColor := $FF212121;
  FLblAtivo.TextSettings.VertAlign := TTextAlign.Center;

  FSwitchAtivo := TSwitch.Create(Self);
  FSwitchAtivo.Parent := LLayoutAtivo;
  FSwitchAtivo.Align := TAlignLayout.Left;
  FSwitchAtivo.Width := 50;
  FSwitchAtivo.IsChecked := True;

  // Botoes do form
  LLayoutBotoes := TLayout.Create(Self);
  LLayoutBotoes.Parent := FLayoutForm;
  LLayoutBotoes.Align := TAlignLayout.Bottom;
  LLayoutBotoes.Height := 56;
  LLayoutBotoes.Padding.Left := 24;
  LLayoutBotoes.Padding.Right := 24;
  LLayoutBotoes.Padding.Bottom := 16;

  FBtnCancelarForm := TButton.Create(Self);
  FBtnCancelarForm.Parent := LLayoutBotoes;
  FBtnCancelarForm.Align := TAlignLayout.Left;
  FBtnCancelarForm.Width := 100;
  FBtnCancelarForm.Height := 36;
  FBtnCancelarForm.Text := 'Cancelar';
  FBtnCancelarForm.StyledSettings := [];
  FBtnCancelarForm.TextSettings.Font.Size := FONT_BTN;
  FBtnCancelarForm.TextSettings.FontColor := $FFFFFFFF;
  FBtnCancelarForm.OnClick := BtnCancelarFormClick;

  FBtnSalvar := TButton.Create(Self);
  FBtnSalvar.Parent := LLayoutBotoes;
  FBtnSalvar.Align := TAlignLayout.Right;
  FBtnSalvar.Width := 100;
  FBtnSalvar.Height := 36;
  FBtnSalvar.Text := 'Salvar';
  FBtnSalvar.StyledSettings := [];
  FBtnSalvar.TextSettings.Font.Size := FONT_BTN;
  FBtnSalvar.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnSalvar.TextSettings.FontColor := $FFFFFFFF;
  FBtnSalvar.OnClick := BtnSalvarClick;
end;

procedure TFrmColaboradores.PopularDadosMock;
var
  LColab: TColaborador;
begin
  // Mock 1 — Administrador ativo
  LColab := TColaborador.Create;
  LColab.Id := 1;
  LColab.Nome := 'Carlos Admin Silva';
  LColab.CPF := '52998224725';
  LColab.Email := 'carlos@sancto.com.br';
  LColab.Telefone := '11999887766';
  LColab.Senha_Hash := 'HASH_MOCK_001';
  LColab.Papel := 'ADMINISTRADOR';
  LColab.Situacao := 1;
  LColab.Tentativas_Login := 0;
  LColab.Ultimo_Acesso := Now - 0.01;
  LColab.Data_Cadastro := Now - 90;
  FColaboradores.Add(LColab);

  // Mock 2 — Gerente ativo
  LColab := TColaborador.Create;
  LColab.Id := 2;
  LColab.Nome := 'Ana Gerente Souza';
  LColab.CPF := '71557048008';
  LColab.Email := 'ana@sancto.com.br';
  LColab.Telefone := '11988776655';
  LColab.Senha_Hash := 'HASH_MOCK_002';
  LColab.Papel := 'GERENTE';
  LColab.Situacao := 1;
  LColab.Tentativas_Login := 0;
  LColab.Ultimo_Acesso := Now - 1;
  LColab.Data_Cadastro := Now - 60;
  FColaboradores.Add(LColab);

  // Mock 3 — Operacional bloqueado
  LColab := TColaborador.Create;
  LColab.Id := 3;
  LColab.Nome := 'Pedro Operador Lima';
  LColab.CPF := '30514357040';
  LColab.Email := 'pedro@sancto.com.br';
  LColab.Telefone := '11977665544';
  LColab.Senha_Hash := 'HASH_MOCK_003';
  LColab.Papel := 'OPERACIONAL';
  LColab.Situacao := 1;
  LColab.Tentativas_Login := 5;
  LColab.Data_Bloqueio := Now - (5 / 1440); // bloqueado 5 min atras
  LColab.Ultimo_Acesso := Now - 2;
  LColab.Data_Cadastro := Now - 30;
  FColaboradores.Add(LColab);
end;

procedure TFrmColaboradores.RenderizarGrid;
var
  I, LIndex: Integer;
  LColab: TColaborador;
  LLinha: TLayout;
begin
  FScrollGrid.Content.DeleteChildren;
  LIndex := 0;

  for I := 0 to FColaboradores.Count - 1 do
  begin
    LColab := FColaboradores[I];
    if not ColaboradorPassaFiltro(LColab) then
      Continue;

    LLinha := CriarLinhaColaborador(LColab, LIndex);
    LLinha.Parent := FScrollGrid;
    Inc(LIndex);
  end;
end;

function TFrmColaboradores.CriarLinhaColaborador(AColab: TColaborador;
  AIndex: Integer): TLayout;
var
  LRect: TRectangle;
  LLblNome, LLblCPF, LLblEmail, LLblPapel, LLblStatus, LLblAcesso: TLabel;
  LLayoutAcoes: TLayout;
  LBtnEditar, LBtnDesativar, LBtnDesbloquear, LBtnExcluir: TButton;
  LPosX: Single;
  LCorFundo: TAlphaColor;
  LBloqueado: Boolean;
begin
  Result := TLayout.Create(Self);
  Result.Align := TAlignLayout.Top;
  Result.Height := LINHA_HEIGHT;
  Result.Tag := AColab.Id;

  if (AIndex mod 2) = 0 then
    LCorFundo := COR_LINHA_PAR
  else
    LCorFundo := COR_LINHA_IMPAR;

  LRect := TRectangle.Create(Self);
  LRect.Parent := Result;
  LRect.Align := TAlignLayout.Client;
  LRect.Fill.Kind := TBrushKind.Solid;
  LRect.Fill.Color := LCorFundo;
  LRect.Stroke.Kind := TBrushKind.None;
  LRect.HitTest := False;

  LPosX := 8;

  // Nome
  LLblNome := TLabel.Create(Self);
  LLblNome.Parent := Result;
  LLblNome.Position.X := LPosX;
  LLblNome.Width := 180;
  LLblNome.Height := LINHA_HEIGHT;
  LLblNome.Text := AColab.Nome;
  LLblNome.StyledSettings := [];
  LLblNome.TextSettings.Font.Size := FONT_GRID;
  LLblNome.TextSettings.FontColor := $FF212121;
  LLblNome.TextSettings.VertAlign := TTextAlign.Center;
  LLblNome.HitTest := False;
  LPosX := LPosX + 180;

  // CPF
  LLblCPF := TLabel.Create(Self);
  LLblCPF.Parent := Result;
  LLblCPF.Position.X := LPosX;
  LLblCPF.Width := 130;
  LLblCPF.Height := LINHA_HEIGHT;
  LLblCPF.Text := FormatarCPF(AColab.CPF);
  LLblCPF.StyledSettings := [];
  LLblCPF.TextSettings.Font.Size := FONT_GRID;
  LLblCPF.TextSettings.FontColor := $FF424242;
  LLblCPF.TextSettings.VertAlign := TTextAlign.Center;
  LLblCPF.HitTest := False;
  LPosX := LPosX + 130;

  // Email
  LLblEmail := TLabel.Create(Self);
  LLblEmail.Parent := Result;
  LLblEmail.Position.X := LPosX;
  LLblEmail.Width := 180;
  LLblEmail.Height := LINHA_HEIGHT;
  LLblEmail.Text := AColab.Email;
  LLblEmail.StyledSettings := [];
  LLblEmail.TextSettings.Font.Size := FONT_GRID;
  LLblEmail.TextSettings.FontColor := $FF424242;
  LLblEmail.TextSettings.VertAlign := TTextAlign.Center;
  LLblEmail.HitTest := False;
  LPosX := LPosX + 180;

  // Papel
  LLblPapel := TLabel.Create(Self);
  LLblPapel.Parent := Result;
  LLblPapel.Position.X := LPosX;
  LLblPapel.Width := 120;
  LLblPapel.Height := LINHA_HEIGHT;
  LLblPapel.Text := AColab.Papel;
  LLblPapel.StyledSettings := [];
  LLblPapel.TextSettings.Font.Size := FONT_GRID;
  LLblPapel.TextSettings.FontColor := $FF424242;
  LLblPapel.TextSettings.VertAlign := TTextAlign.Center;
  LLblPapel.HitTest := False;
  LPosX := LPosX + 120;

  // Status
  LLblStatus := TLabel.Create(Self);
  LLblStatus.Parent := Result;
  LLblStatus.Position.X := LPosX;
  LLblStatus.Width := 80;
  LLblStatus.Height := LINHA_HEIGHT;
  LLblStatus.Text := FormatarStatus(AColab.Situacao);
  LLblStatus.StyledSettings := [];
  LLblStatus.TextSettings.Font.Size := FONT_GRID;
  LLblStatus.TextSettings.Font.Style := [TFontStyle.fsBold];
  if AColab.Situacao = 1 then
    LLblStatus.TextSettings.FontColor := COR_ATIVO
  else
    LLblStatus.TextSettings.FontColor := COR_INATIVO;
  LLblStatus.TextSettings.VertAlign := TTextAlign.Center;
  LLblStatus.HitTest := False;
  LPosX := LPosX + 80;

  // Ultimo Acesso
  LLblAcesso := TLabel.Create(Self);
  LLblAcesso.Parent := Result;
  LLblAcesso.Position.X := LPosX;
  LLblAcesso.Width := 130;
  LLblAcesso.Height := LINHA_HEIGHT;
  LLblAcesso.Text := FormatarUltimoAcesso(AColab.Ultimo_Acesso);
  LLblAcesso.StyledSettings := [];
  LLblAcesso.TextSettings.Font.Size := FONT_GRID;
  LLblAcesso.TextSettings.FontColor := $FF757575;
  LLblAcesso.TextSettings.VertAlign := TTextAlign.Center;
  LLblAcesso.HitTest := False;
  LPosX := LPosX + 130;

  // Acoes
  LLayoutAcoes := TLayout.Create(Self);
  LLayoutAcoes.Parent := Result;
  LLayoutAcoes.Position.X := LPosX;
  LLayoutAcoes.Width := 220;
  LLayoutAcoes.Height := LINHA_HEIGHT;

  LBloqueado := (AColab.Tentativas_Login >= 5) and (AColab.Data_Bloqueio > 0);

  // Editar
  LBtnEditar := TButton.Create(Self);
  LBtnEditar.Parent := LLayoutAcoes;
  LBtnEditar.Align := TAlignLayout.Left;
  LBtnEditar.Width := 50;
  LBtnEditar.Height := 28;
  LBtnEditar.Text := 'Editar';
  LBtnEditar.Tag := AColab.Id;
  LBtnEditar.StyledSettings := [];
  LBtnEditar.TextSettings.Font.Size := 11;
  LBtnEditar.TextSettings.FontColor := $FFFFFFFF;
  LBtnEditar.OnClick := BtnEditarClick;
  LBtnEditar.Margins.Top := 8;
  LBtnEditar.Margins.Right := 4;

  // Desativar/Reativar
  LBtnDesativar := TButton.Create(Self);
  LBtnDesativar.Parent := LLayoutAcoes;
  LBtnDesativar.Align := TAlignLayout.Left;
  LBtnDesativar.Width := 60;
  LBtnDesativar.Height := 28;
  LBtnDesativar.Tag := AColab.Id;
  LBtnDesativar.StyledSettings := [];
  LBtnDesativar.TextSettings.Font.Size := 11;
  LBtnDesativar.TextSettings.FontColor := $FFFFFFFF;
  LBtnDesativar.OnClick := BtnDesativarClick;
  LBtnDesativar.Margins.Top := 8;
  LBtnDesativar.Margins.Right := 4;
  if AColab.Situacao = 1 then
    LBtnDesativar.Text := 'Desativar'
  else
    LBtnDesativar.Text := 'Reativar';

  // Desbloquear (se bloqueado)
  if LBloqueado then
  begin
    LBtnDesbloquear := TButton.Create(Self);
    LBtnDesbloquear.Parent := LLayoutAcoes;
    LBtnDesbloquear.Align := TAlignLayout.Left;
    LBtnDesbloquear.Width := 70;
    LBtnDesbloquear.Height := 28;
    LBtnDesbloquear.Text := 'Desbloquear';
    LBtnDesbloquear.Tag := AColab.Id;
    LBtnDesbloquear.StyledSettings := [];
    LBtnDesbloquear.TextSettings.Font.Size := 11;
    LBtnDesbloquear.TextSettings.FontColor := $FFFFFFFF;
    LBtnDesbloquear.OnClick := BtnDesbloquearClick;
    LBtnDesbloquear.Margins.Top := 8;
    LBtnDesbloquear.Margins.Right := 4;
  end;

  // Excluir
  LBtnExcluir := TButton.Create(Self);
  LBtnExcluir.Parent := LLayoutAcoes;
  LBtnExcluir.Align := TAlignLayout.Left;
  LBtnExcluir.Width := 50;
  LBtnExcluir.Height := 28;
  LBtnExcluir.Text := 'Excluir';
  LBtnExcluir.Tag := AColab.Id;
  LBtnExcluir.StyledSettings := [];
  LBtnExcluir.TextSettings.Font.Size := 11;
  LBtnExcluir.TextSettings.FontColor := $FFFFFFFF;
  LBtnExcluir.OnClick := BtnExcluirClick;
  LBtnExcluir.Margins.Top := 8;
end;

{ Filtro }

procedure TFrmColaboradores.EdtBuscaChange(Sender: TObject);
begin
  RenderizarGrid;
end;

procedure TFrmColaboradores.CmbFiltroPapelChange(Sender: TObject);
begin
  RenderizarGrid;
end;

function TFrmColaboradores.ColaboradorPassaFiltro(AColab: TColaborador): Boolean;
var
  LBusca, LPapelFiltro: string;
begin
  Result := True;

  // Filtro por papel
  if FCmbFiltroPapel.ItemIndex > 0 then
  begin
    LPapelFiltro := FCmbFiltroPapel.Items[FCmbFiltroPapel.ItemIndex];
    if not SameText(AColab.Papel, LPapelFiltro) then
    begin
      Result := False;
      Exit;
    end;
  end;

  // Filtro por busca (nome ou CPF)
  LBusca := Trim(LowerCase(FEdtBusca.Text));
  if LBusca <> '' then
  begin
    if (Pos(LBusca, LowerCase(AColab.Nome)) = 0) and
       (Pos(LBusca, AColab.CPF) = 0) then
    begin
      Result := False;
    end;
  end;
end;

{ Acoes }

procedure TFrmColaboradores.BtnNovoClick(Sender: TObject);
begin
  AbrirForm(nil);
end;

procedure TFrmColaboradores.BtnEditarClick(Sender: TObject);
var
  LId, I: Integer;
begin
  if not (Sender is TButton) then Exit;
  LId := TButton(Sender).Tag;

  for I := 0 to FColaboradores.Count - 1 do
  begin
    if FColaboradores[I].Id = LId then
    begin
      AbrirForm(FColaboradores[I]);
      Exit;
    end;
  end;
end;

procedure TFrmColaboradores.BtnDesativarClick(Sender: TObject);
var
  LId, I: Integer;
  LColab: TColaborador;
  LMensagem: string;
begin
  if not (Sender is TButton) then Exit;
  LId := TButton(Sender).Tag;

  // Impedir auto-desativacao
  if LId = FColaboradorLogadoId then
  begin
    TDialogService.ShowMessage(
      'Você não pode desativar sua própria conta.');
    Exit;
  end;

  LColab := nil;
  for I := 0 to FColaboradores.Count - 1 do
  begin
    if FColaboradores[I].Id = LId then
    begin
      LColab := FColaboradores[I];
      Break;
    end;
  end;

  if not Assigned(LColab) then Exit;

  if LColab.Situacao = 1 then
    LMensagem := 'Desativar o colaborador "' + LColab.Nome + '"?'
  else
    LMensagem := 'Reativar o colaborador "' + LColab.Nome + '"?';

  TDialogService.MessageDialog(
    LMensagem,
    TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        if LColab.Situacao = 1 then
          LColab.Situacao := 0
        else
          LColab.Situacao := 1;
        RenderizarGrid;
      end;
    end
  );
end;

procedure TFrmColaboradores.BtnDesbloquearClick(Sender: TObject);
var
  LId, I: Integer;
  LColab: TColaborador;
begin
  if not (Sender is TButton) then Exit;
  LId := TButton(Sender).Tag;

  for I := 0 to FColaboradores.Count - 1 do
  begin
    if FColaboradores[I].Id = LId then
    begin
      LColab := FColaboradores[I];
      LColab.Tentativas_Login := 0;
      LColab.Data_Bloqueio := 0;
      TDialogService.ShowMessage(
        'Conta de "' + LColab.Nome + '" desbloqueada com sucesso.');
      RenderizarGrid;
      Exit;
    end;
  end;
end;

procedure TFrmColaboradores.BtnExcluirClick(Sender: TObject);
var
  LId, I: Integer;
  LColab: TColaborador;
begin
  if not (Sender is TButton) then Exit;
  LId := TButton(Sender).Tag;

  LColab := nil;
  for I := 0 to FColaboradores.Count - 1 do
  begin
    if FColaboradores[I].Id = LId then
    begin
      LColab := FColaboradores[I];
      Break;
    end;
  end;

  if not Assigned(LColab) then Exit;

  // Primeira confirmacao
  TDialogService.MessageDialog(
    'Excluir permanentemente o colaborador "' + LColab.Nome + '"?'
      + #13#10 + 'Esta ação não pode ser desfeita.',
    TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        // Segunda confirmacao (dupla confirmacao)
        TDialogService.MessageDialog(
          'TEM CERTEZA? Confirme novamente para excluir "' + LColab.Nome + '".',
          TMsgDlgType.mtWarning,
          [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
          TMsgDlgBtn.mbNo, 0,
          procedure(const AResult2: TModalResult)
          begin
            if AResult2 = mrYes then
            begin
              FColaboradores.Remove(LColab);
              RenderizarGrid;
            end;
          end
        );
      end;
    end
  );
end;

procedure TFrmColaboradores.BtnSalvarClick(Sender: TObject);
var
  LNome, LCPF, LEmail, LTelefone, LSenha, LConfirmar, LPapel: string;
  LColab: TColaborador;
  LNextId, I: Integer;
begin
  LNome := Trim(FEdtNome.Text);
  LCPF := Trim(FEdtCPF.Text);
  LEmail := Trim(FEdtEmail.Text);
  LTelefone := Trim(FEdtTelefone.Text);
  LSenha := FEdtSenha.Text;
  LConfirmar := FEdtConfirmarSenha.Text;
  LPapel := FCmbPapel.Items[FCmbPapel.ItemIndex];

  // Validacoes basicas de UI
  if LNome = '' then
  begin
    TDialogService.ShowMessage('Nome é obrigatório.');
    Exit;
  end;

  if LCPF = '' then
  begin
    TDialogService.ShowMessage('CPF é obrigatório.');
    Exit;
  end;

  if LEmail = '' then
  begin
    TDialogService.ShowMessage('Email é obrigatório.');
    Exit;
  end;

  // Senha obrigatoria apenas para novo colaborador
  if (not FModoEdicao) then
  begin
    if Length(LSenha) < 6 then
    begin
      TDialogService.ShowMessage('Senha deve ter no mínimo 6 caracteres.');
      Exit;
    end;
    if LSenha <> LConfirmar then
    begin
      TDialogService.ShowMessage('As senhas não conferem.');
      Exit;
    end;
  end
  else
  begin
    // Em edicao, se preencheu senha, validar confirmacao
    if (LSenha <> '') and (LSenha <> LConfirmar) then
    begin
      TDialogService.ShowMessage('As senhas não conferem.');
      Exit;
    end;
  end;

  if FModoEdicao and Assigned(FColaboradorEditando) then
  begin
    // Edicao
    FColaboradorEditando.Nome := LNome;
    FColaboradorEditando.Email := LEmail;
    FColaboradorEditando.Telefone := LTelefone;
    FColaboradorEditando.Papel := LPapel;
    if FSwitchAtivo.IsChecked then
      FColaboradorEditando.Situacao := 1
    else
      FColaboradorEditando.Situacao := 0;
    // Atualizar senha se preenchida
    if LSenha <> '' then
      FColaboradorEditando.Senha_Hash := 'HASH_' + LSenha;
  end
  else
  begin
    // Novo colaborador
    LNextId := 1;
    for I := 0 to FColaboradores.Count - 1 do
    begin
      if FColaboradores[I].Id >= LNextId then
        LNextId := FColaboradores[I].Id + 1;
    end;

    LColab := TColaborador.Create;
    LColab.Id := LNextId;
    LColab.Nome := LNome;
    LColab.CPF := LCPF;
    LColab.Email := LEmail;
    LColab.Telefone := LTelefone;
    LColab.Senha_Hash := 'HASH_' + LSenha;
    LColab.Papel := LPapel;
    if FSwitchAtivo.IsChecked then
      LColab.Situacao := 1
    else
      LColab.Situacao := 0;
    LColab.Data_Cadastro := Now;
    LColab.Ultimo_Acesso := 0;
    FColaboradores.Add(LColab);
  end;

  FecharForm;
  RenderizarGrid;
end;

procedure TFrmColaboradores.BtnCancelarFormClick(Sender: TObject);
begin
  FecharForm;
end;

procedure TFrmColaboradores.BtnToggleSenhaClick(Sender: TObject);
begin
  FSenhaVisivel := not FSenhaVisivel;
  FEdtSenha.Password := not FSenhaVisivel;
  FEdtConfirmarSenha.Password := not FSenhaVisivel;
  if FSenhaVisivel then
    FBtnToggleSenha.Text := '🙈'
  else
    FBtnToggleSenha.Text := '👁';
end;

{ Form overlay }

procedure TFrmColaboradores.AbrirForm(AColab: TColaborador);
begin
  LimparForm;

  if Assigned(AColab) then
  begin
    FModoEdicao := True;
    FColaboradorEditando := AColab;
    FLblFormTitulo.Text := 'Editar Colaborador';
    PreencherFormComColaborador(AColab);
    // CPF read-only na edicao
    FEdtCPF.Enabled := False;
  end
  else
  begin
    FModoEdicao := False;
    FColaboradorEditando := nil;
    FLblFormTitulo.Text := 'Novo Colaborador';
    FEdtCPF.Enabled := True;
  end;

  FLayoutOverlay.Visible := True;
  FLayoutOverlay.BringToFront;
end;

procedure TFrmColaboradores.FecharForm;
begin
  FLayoutOverlay.Visible := False;
  FColaboradorEditando := nil;
  FModoEdicao := False;
  FSenhaVisivel := False;
  FEdtSenha.Password := True;
  FEdtConfirmarSenha.Password := True;
  FBtnToggleSenha.Text := '👁';
end;

procedure TFrmColaboradores.LimparForm;
begin
  FEdtNome.Text := '';
  FEdtCPF.Text := '';
  FEdtEmail.Text := '';
  FEdtTelefone.Text := '';
  FEdtSenha.Text := '';
  FEdtConfirmarSenha.Text := '';
  FCmbPapel.ItemIndex := 2; // OPERACIONAL
  FSwitchAtivo.IsChecked := True;
  FEdtCPF.Enabled := True;
end;

procedure TFrmColaboradores.PreencherFormComColaborador(AColab: TColaborador);
begin
  FEdtNome.Text := AColab.Nome;
  FEdtCPF.Text := FormatarCPF(AColab.CPF);
  FEdtEmail.Text := AColab.Email;
  FEdtTelefone.Text := AColab.Telefone;
  FEdtSenha.Text := '';
  FEdtConfirmarSenha.Text := '';
  FSwitchAtivo.IsChecked := (AColab.Situacao = 1);

  // Selecionar papel no combo
  if SameText(AColab.Papel, 'ADMINISTRADOR') then
    FCmbPapel.ItemIndex := 0
  else if SameText(AColab.Papel, 'GERENTE') then
    FCmbPapel.ItemIndex := 1
  else
    FCmbPapel.ItemIndex := 2;
end;

{ Helpers }

function TFrmColaboradores.FormatarCPF(const ACPF: string): string;
var
  LDigitos: string;
  I: Integer;
begin
  // Extrai apenas digitos
  LDigitos := '';
  for I := 1 to Length(ACPF) do
  begin
    if CharInSet(ACPF[I], ['0'..'9']) then
      LDigitos := LDigitos + ACPF[I];
  end;

  if Length(LDigitos) = 11 then
    Result := Copy(LDigitos, 1, 3) + '.' +
              Copy(LDigitos, 4, 3) + '.' +
              Copy(LDigitos, 7, 3) + '-' +
              Copy(LDigitos, 10, 2)
  else
    Result := ACPF;
end;

function TFrmColaboradores.FormatarStatus(ASituacao: Integer): string;
begin
  if ASituacao = 1 then
    Result := 'Ativo'
  else
    Result := 'Inativo';
end;

function TFrmColaboradores.FormatarUltimoAcesso(AData: TDateTime): string;
begin
  if AData = 0 then
    Result := 'Nunca'
  else
    Result := FormatDateTime('dd/mm/yyyy hh:nn', AData);
end;

end.
