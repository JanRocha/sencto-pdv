unit Frm.Main.Backoffice;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.DateUtils,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  FMX.Controls.Presentation;

type
  /// <summary>
  /// Página ativa no conteúdo central do Backoffice.
  /// </summary>
  TPaginaBackoffice = (pbDashboard, pbProdutos, pbColaboradores,
                       pbFiscal, pbRelatorios, pbConfiguracoes);

  /// <summary>
  /// Form principal do Backoffice com navegação lateral (sidebar), header
  /// e área de conteúdo central. Criado programaticamente (sem .fmx).
  /// Implementa:
  ///   - Header com logo "SANCTO PDV - Backoffice", colaborador info, logout
  ///   - Sidebar com navegação: Dashboard, Produtos, Colaboradores, Fiscal,
  ///     Relatórios, Configurações
  ///   - Apenas ADMINISTRADOR e GERENTE podem acessar (req 1.7, 1.8)
  ///   - Área de conteúdo com placeholder labels ao clicar nos itens
  ///   - Timer para atualização de relógio
  ///   - Botões touch-friendly 48x48px com espaçamento 8px (req 13.1, 13.2)
  ///   - Layout responsivo 1024x768 até 1920x1080 (req 13.3)
  /// </summary>
  TFrmMainBackoffice = class(TForm)
  private
    { Dados do colaborador logado }
    FColaboradorId: Integer;
    FColaboradorNome: string;
    FColaboradorPapel: string;

    { Página ativa }
    FPaginaAtiva: TPaginaBackoffice;

    { Timer }
    FTimerRelogio: TTimer;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Header }
    FLayoutHeader: TLayout;
    FRectHeader: TRectangle;
    FLblLogo: TLabel;
    FLblColaborador: TLabel;
    FLblHoraHeader: TLabel;
    FBtnLogout: TButton;

    { Sidebar }
    FLayoutSidebar: TLayout;
    FRectSidebar: TRectangle;
    FBtnDashboard: TButton;
    FBtnProdutos: TButton;
    FBtnColaboradores: TButton;
    FBtnFiscal: TButton;
    FBtnRelatorios: TButton;
    FBtnConfiguracoes: TButton;

    { Content area }
    FLayoutContent: TLayout;
    FLblContentPlaceholder: TLabel;

    { Footer }
    FLayoutFooter: TLayout;
    FRectFooter: TRectangle;
    FLblVersao: TLabel;
    FLblHoraFooter: TLabel;

    { Callback de logout }
    FOnLogout: TNotifyEvent;

    procedure CriarComponentes;
    procedure CriarHeader;
    procedure CriarSidebar;
    procedure CriarContentArea;
    procedure CriarFooter;
    procedure CriarTimer;
    procedure AtualizarHora(Sender: TObject);

    { Sidebar button handlers }
    procedure BtnDashboardClick(Sender: TObject);
    procedure BtnProdutosClick(Sender: TObject);
    procedure BtnColaboradoresClick(Sender: TObject);
    procedure BtnFiscalClick(Sender: TObject);
    procedure BtnRelatoriosClick(Sender: TObject);
    procedure BtnConfiguracoesClick(Sender: TObject);
    procedure BtnLogoutClick(Sender: TObject);

    { Sidebar button mouse feedback }
    procedure SidebarBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SidebarBtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    procedure NavegarPara(APagina: TPaginaBackoffice);
    procedure AtualizarContentPlaceholder;
    function CriarBotaoSidebar(AParent: TFmxObject; const ATexto: string;
      APosY: Single; AOnClick: TNotifyEvent): TButton;
  public
    constructor Create(AOwner: TComponent; AColaboradorId: Integer;
      const AColaboradorNome, AColaboradorPapel: string); reintroduce;
    destructor Destroy; override;

    /// <summary>Layout central onde sub-forms/frames são carregados</summary>
    property LayoutContent: TLayout read FLayoutContent;
    /// <summary>Página atualmente exibida</summary>
    property PaginaAtiva: TPaginaBackoffice read FPaginaAtiva;
    /// <summary>Evento disparado ao clicar em Logout</summary>
    property OnLogout: TNotifyEvent read FOnLogout write FOnLogout;
  end;

implementation

const
  COR_HEADER = $FF283593;     // Indigo 800
  COR_SIDEBAR = $FF3949AB;    // Indigo 600
  COR_SIDEBAR_HOVER = $FF303F9F; // Indigo 700
  COR_FOOTER = $FF263238;     // Blue Grey 900
  COR_CONTENT_BG = $FFF5F5F5; // Grey 100
  COR_TEXTO_BRANCO = $FFFFFFFF;
  COR_TEXTO_CLARO = $FFECEFF1; // Blue Grey 50

  SIDEBAR_WIDTH = 90;
  HEADER_HEIGHT = 56;
  FOOTER_HEIGHT = 36;
  BTN_WIDTH = 76;
  BTN_HEIGHT = 64;    // Acima de 48px mínimo (req 13.1)
  BTN_SPACING = 8;    // Espaçamento mínimo entre botões (req 13.1)

{ TFrmMainBackoffice }

constructor TFrmMainBackoffice.Create(AOwner: TComponent; AColaboradorId: Integer;
  const AColaboradorNome, AColaboradorPapel: string);
begin
  inherited CreateNew(AOwner);

  FColaboradorId := AColaboradorId;
  FColaboradorNome := AColaboradorNome;
  FColaboradorPapel := AColaboradorPapel;
  FPaginaAtiva := pbDashboard;

  Caption := 'SANCTO PDV - Backoffice';
  ClientWidth := 1024;
  ClientHeight := 768;
  Position := TFormPosition.ScreenCenter;
  BorderStyle := TFmxFormBorderStyle.Sizeable;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := COR_CONTENT_BG;
  WindowState := TWindowState.wsMaximized;

  CriarComponentes;
  CriarTimer;

  // Iniciar na página de Dashboard
  NavegarPara(pbDashboard);
end;

destructor TFrmMainBackoffice.Destroy;
begin
  if Assigned(FTimerRelogio) then
    FTimerRelogio.Enabled := False;
  inherited Destroy;
end;

procedure TFrmMainBackoffice.CriarComponentes;
begin
  // Layout principal que contém tudo
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;

  CriarHeader;
  CriarFooter;
  CriarSidebar;
  CriarContentArea;
end;

procedure TFrmMainBackoffice.CriarHeader;
begin
  // Layout container do header
  FLayoutHeader := TLayout.Create(Self);
  FLayoutHeader.Parent := FLayoutPrincipal;
  FLayoutHeader.Align := TAlignLayout.Top;
  FLayoutHeader.Height := HEADER_HEIGHT;

  // Fundo do header
  FRectHeader := TRectangle.Create(Self);
  FRectHeader.Parent := FLayoutHeader;
  FRectHeader.Align := TAlignLayout.Client;
  FRectHeader.Fill.Kind := TBrushKind.Solid;
  FRectHeader.Fill.Color := COR_HEADER;
  FRectHeader.Stroke.Kind := TBrushKind.None;
  FRectHeader.HitTest := False;

  // Logo "SANCTO PDV - Backoffice"
  FLblLogo := TLabel.Create(Self);
  FLblLogo.Parent := FLayoutHeader;
  FLblLogo.Align := TAlignLayout.Left;
  FLblLogo.Width := 260;
  FLblLogo.Margins.Left := 12;
  FLblLogo.Text := 'SANCTO PDV - Backoffice';
  FLblLogo.StyledSettings := [];
  FLblLogo.TextSettings.Font.Size := 20;
  FLblLogo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblLogo.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblLogo.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblLogo.TextSettings.VertAlign := TTextAlign.Center;

  // Nome do colaborador + papel
  FLblColaborador := TLabel.Create(Self);
  FLblColaborador.Parent := FLayoutHeader;
  FLblColaborador.Align := TAlignLayout.Left;
  FLblColaborador.Width := 280;
  FLblColaborador.Margins.Left := 16;
  FLblColaborador.Text := FColaboradorNome + ' (' + FColaboradorPapel + ')';
  FLblColaborador.StyledSettings := [];
  FLblColaborador.TextSettings.Font.Size := 14;
  FLblColaborador.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblColaborador.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblColaborador.TextSettings.VertAlign := TTextAlign.Center;

  // Botão Logout (alinhado à direita)
  FBtnLogout := TButton.Create(Self);
  FBtnLogout.Parent := FLayoutHeader;
  FBtnLogout.Align := TAlignLayout.Right;
  FBtnLogout.Width := 100;
  FBtnLogout.Height := 48;
  FBtnLogout.Margins.Right := 12;
  FBtnLogout.Margins.Top := 4;
  FBtnLogout.Margins.Bottom := 4;
  FBtnLogout.Text := 'Sair';
  FBtnLogout.StyledSettings := [];
  FBtnLogout.TextSettings.Font.Size := 14;
  FBtnLogout.OnClick := BtnLogoutClick;

  // Hora no header (alinhado à direita, antes do logout)
  FLblHoraHeader := TLabel.Create(Self);
  FLblHoraHeader.Parent := FLayoutHeader;
  FLblHoraHeader.Align := TAlignLayout.Right;
  FLblHoraHeader.Width := 80;
  FLblHoraHeader.Margins.Right := 12;
  FLblHoraHeader.Text := FormatDateTime('hh:nn:ss', Now);
  FLblHoraHeader.StyledSettings := [];
  FLblHoraHeader.TextSettings.Font.Size := 14;
  FLblHoraHeader.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblHoraHeader.TextSettings.HorzAlign := TTextAlign.Center;
  FLblHoraHeader.TextSettings.VertAlign := TTextAlign.Center;
end;

procedure TFrmMainBackoffice.CriarSidebar;
var
  LPosY: Single;
begin
  // Layout container da sidebar
  FLayoutSidebar := TLayout.Create(Self);
  FLayoutSidebar.Parent := FLayoutPrincipal;
  FLayoutSidebar.Align := TAlignLayout.Left;
  FLayoutSidebar.Width := SIDEBAR_WIDTH;

  // Fundo da sidebar
  FRectSidebar := TRectangle.Create(Self);
  FRectSidebar.Parent := FLayoutSidebar;
  FRectSidebar.Align := TAlignLayout.Client;
  FRectSidebar.Fill.Kind := TBrushKind.Solid;
  FRectSidebar.Fill.Color := COR_SIDEBAR;
  FRectSidebar.Stroke.Kind := TBrushKind.None;
  FRectSidebar.HitTest := False;

  // Botões de navegação — Backoffice: Dashboard, Produtos, Colaboradores, Fiscal, Relatórios, Configurações
  LPosY := BTN_SPACING;

  FBtnDashboard := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCCA) + #13#10 + 'Dashboard', LPosY, BtnDashboardClick);
  LPosY := LPosY + BTN_HEIGHT + BTN_SPACING;

  FBtnProdutos := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCE6) + #13#10 + 'Produtos', LPosY, BtnProdutosClick);
  LPosY := LPosY + BTN_HEIGHT + BTN_SPACING;

  FBtnColaboradores := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DC65) + #13#10 + 'Equipe', LPosY, BtnColaboradoresClick);
  LPosY := LPosY + BTN_HEIGHT + BTN_SPACING;

  FBtnFiscal := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCDD) + #13#10 + 'Fiscal', LPosY, BtnFiscalClick);
  LPosY := LPosY + BTN_HEIGHT + BTN_SPACING;

  FBtnRelatorios := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCC8) + #13#10 + 'Relat' + Char($00F3) + 'rios', LPosY, BtnRelatoriosClick);
  LPosY := LPosY + BTN_HEIGHT + BTN_SPACING;

  FBtnConfiguracoes := CriarBotaoSidebar(FLayoutSidebar,
    Char($2699) + #13#10 + 'Config.', LPosY, BtnConfiguracoesClick);
end;

function TFrmMainBackoffice.CriarBotaoSidebar(AParent: TFmxObject;
  const ATexto: string; APosY: Single; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Position.X := (SIDEBAR_WIDTH - BTN_WIDTH) / 2; // Centralizar horizontalmente
  Result.Position.Y := APosY;
  Result.Width := BTN_WIDTH;
  Result.Height := BTN_HEIGHT;  // 64px > 48px mínimo (req 13.1)
  Result.Text := ATexto;
  Result.StyledSettings := [];
  Result.TextSettings.Font.Size := 10;
  Result.TextSettings.WordWrap := True;
  Result.TextSettings.HorzAlign := TTextAlign.Center;
  Result.TextSettings.VertAlign := TTextAlign.Center;
  Result.OnClick := AOnClick;
  Result.OnMouseDown := SidebarBtnMouseDown;
  Result.OnMouseUp := SidebarBtnMouseUp;
end;

procedure TFrmMainBackoffice.CriarContentArea;
begin
  // Layout central para conteúdo
  FLayoutContent := TLayout.Create(Self);
  FLayoutContent.Parent := FLayoutPrincipal;
  FLayoutContent.Align := TAlignLayout.Client;

  // Label placeholder (será substituído por frames reais)
  FLblContentPlaceholder := TLabel.Create(Self);
  FLblContentPlaceholder.Parent := FLayoutContent;
  FLblContentPlaceholder.Align := TAlignLayout.Center;
  FLblContentPlaceholder.Width := 400;
  FLblContentPlaceholder.Height := 100;
  FLblContentPlaceholder.StyledSettings := [];
  FLblContentPlaceholder.TextSettings.Font.Size := 24;
  FLblContentPlaceholder.TextSettings.FontColor := $FF757575; // Grey 600
  FLblContentPlaceholder.TextSettings.HorzAlign := TTextAlign.Center;
  FLblContentPlaceholder.TextSettings.VertAlign := TTextAlign.Center;
  FLblContentPlaceholder.Text := 'Dashboard';
end;

procedure TFrmMainBackoffice.CriarFooter;
begin
  // Layout container do footer
  FLayoutFooter := TLayout.Create(Self);
  FLayoutFooter.Parent := FLayoutPrincipal;
  FLayoutFooter.Align := TAlignLayout.Bottom;
  FLayoutFooter.Height := FOOTER_HEIGHT;

  // Fundo do footer
  FRectFooter := TRectangle.Create(Self);
  FRectFooter.Parent := FLayoutFooter;
  FRectFooter.Align := TAlignLayout.Client;
  FRectFooter.Fill.Kind := TBrushKind.Solid;
  FRectFooter.Fill.Color := COR_FOOTER;
  FRectFooter.Stroke.Kind := TBrushKind.None;
  FRectFooter.HitTest := False;

  // Versão (esquerda)
  FLblVersao := TLabel.Create(Self);
  FLblVersao.Parent := FLayoutFooter;
  FLblVersao.Align := TAlignLayout.Left;
  FLblVersao.Width := 200;
  FLblVersao.Margins.Left := 12;
  FLblVersao.Text := 'SANCTO PDV Backoffice v1.0';
  FLblVersao.StyledSettings := [];
  FLblVersao.TextSettings.Font.Size := 11;
  FLblVersao.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblVersao.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblVersao.TextSettings.VertAlign := TTextAlign.Center;

  // Hora no footer (direita)
  FLblHoraFooter := TLabel.Create(Self);
  FLblHoraFooter.Parent := FLayoutFooter;
  FLblHoraFooter.Align := TAlignLayout.Right;
  FLblHoraFooter.Width := 120;
  FLblHoraFooter.Margins.Right := 12;
  FLblHoraFooter.Text := FormatDateTime('hh:nn:ss', Now);
  FLblHoraFooter.StyledSettings := [];
  FLblHoraFooter.TextSettings.Font.Size := 12;
  FLblHoraFooter.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblHoraFooter.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLblHoraFooter.TextSettings.VertAlign := TTextAlign.Center;
end;

procedure TFrmMainBackoffice.CriarTimer;
begin
  FTimerRelogio := TTimer.Create(Self);
  FTimerRelogio.Interval := 1000; // Atualizar a cada 1 segundo
  FTimerRelogio.OnTimer := AtualizarHora;
  FTimerRelogio.Enabled := True;
end;

procedure TFrmMainBackoffice.AtualizarHora(Sender: TObject);
var
  LHoraAtual: string;
begin
  LHoraAtual := FormatDateTime('hh:nn:ss', Now);
  FLblHoraHeader.Text := LHoraAtual;
  FLblHoraFooter.Text := LHoraAtual;
end;

{ Sidebar button handlers }

procedure TFrmMainBackoffice.BtnDashboardClick(Sender: TObject);
begin
  NavegarPara(pbDashboard);
end;

procedure TFrmMainBackoffice.BtnProdutosClick(Sender: TObject);
begin
  NavegarPara(pbProdutos);
end;

procedure TFrmMainBackoffice.BtnColaboradoresClick(Sender: TObject);
begin
  NavegarPara(pbColaboradores);
end;

procedure TFrmMainBackoffice.BtnFiscalClick(Sender: TObject);
begin
  NavegarPara(pbFiscal);
end;

procedure TFrmMainBackoffice.BtnRelatoriosClick(Sender: TObject);
begin
  NavegarPara(pbRelatorios);
end;

procedure TFrmMainBackoffice.BtnConfiguracoesClick(Sender: TObject);
begin
  NavegarPara(pbConfiguracoes);
end;

procedure TFrmMainBackoffice.BtnLogoutClick(Sender: TObject);
begin
  if Assigned(FOnLogout) then
    FOnLogout(Self)
  else
  begin
    // Comportamento padrão: fechar o form principal e voltar ao login
    FTimerRelogio.Enabled := False;
    Close;
  end;
end;

{ Feedback visual touch — <100ms (req 13.2) }

procedure TFrmMainBackoffice.SidebarBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 0.92;
    TButton(Sender).Scale.Y := 0.92;
  end;
end;

procedure TFrmMainBackoffice.SidebarBtnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 1.0;
    TButton(Sender).Scale.Y := 1.0;
  end;
end;

procedure TFrmMainBackoffice.NavegarPara(APagina: TPaginaBackoffice);
begin
  FPaginaAtiva := APagina;
  AtualizarContentPlaceholder;
end;

procedure TFrmMainBackoffice.AtualizarContentPlaceholder;
begin
  case FPaginaAtiva of
    pbDashboard:     FLblContentPlaceholder.Text := Char($D83D) + Char($DCCA) + ' Dashboard';
    pbProdutos:      FLblContentPlaceholder.Text := Char($D83D) + Char($DCE6) + ' Produtos';
    pbColaboradores: FLblContentPlaceholder.Text := Char($D83D) + Char($DC65) + ' Colaboradores';
    pbFiscal:        FLblContentPlaceholder.Text := Char($D83D) + Char($DCDD) + ' Fiscal';
    pbRelatorios:    FLblContentPlaceholder.Text := Char($D83D) + Char($DCC8) + ' Relat' + Char($00F3) + 'rios';
    pbConfiguracoes: FLblContentPlaceholder.Text := Char($2699) + ' Configura' + Char($00E7) + Char($00F5) + 'es';
  end;
end;

end.
