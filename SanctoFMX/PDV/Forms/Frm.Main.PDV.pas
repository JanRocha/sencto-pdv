unit Frm.Main.PDV;

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
  FMX.Graphics,
  FMX.Controls.Presentation;

type
  /// <summary>
  /// Página ativa no conteúdo central do PDV.
  /// </summary>
  TPaginaPDV = (ppVendas, ppCaixa, ppVisitantes, ppFestas,
                ppProdutos, ppColaboradores, ppRelatorios);

  /// <summary>
  /// Form principal do PDV com navegação lateral (sidebar), header, footer
  /// e área de conteúdo central. Criado programaticamente (sem .fmx).
  /// Implementa:
  ///   - Header com logo, colaborador, caixa ID, hora, logout (req 13.1)
  ///   - Sidebar com botões de navegação baseados no papel (req 1.5, 1.6)
  ///   - Área de conteúdo para carregar sub-forms/frames
  ///   - Footer com status fiscal, hora atualizada a cada segundo, alertas
  ///   - Botões touch-friendly 48x48px com espaçamento 8px (req 13.1, 13.2)
  ///   - Layout responsivo 1024x768 até 1920x1080 (req 13.3)
  /// </summary>
  TFrmMainPDV = class(TForm)
  private
    { Dados do colaborador logado }
    FColaboradorId: Integer;
    FColaboradorNome: string;
    FColaboradorPapel: string;
    FCaixaId: Integer;

    { Página ativa }
    FPaginaAtiva: TPaginaPDV;

    { Timer }
    FTimerRelogio: TTimer;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Header }
    FLayoutHeader: TLayout;
    FRectHeader: TRectangle;
    FLblLogo: TLabel;
    FLblColaborador: TLabel;
    FLblCaixaId: TLabel;
    FLblHoraHeader: TLabel;
    FBtnLogout: TButton;

    { Sidebar }
    FLayoutSidebar: TLayout;
    FRectSidebar: TRectangle;
    FBtnVendas: TButton;
    FBtnCaixa: TButton;
    FBtnVisitantes: TButton;
    FBtnFestas: TButton;
    FBtnProdutos: TButton;
    FBtnColaboradores: TButton;
    FBtnRelatorios: TButton;

    { Content area }
    FLayoutContent: TLayout;
    FLblContentPlaceholder: TLabel;

    { Footer }
    FLayoutFooter: TLayout;
    FRectFooter: TRectangle;
    FLblStatusFiscal: TLabel;
    FLblHoraFooter: TLabel;
    FLblAlertas: TLabel;

    { Callback de logout }
    FOnLogout: TNotifyEvent;

    procedure CriarComponentes;
    procedure CriarHeader;
    procedure CriarSidebar;
    procedure CriarContentArea;
    procedure CriarFooter;
    procedure CriarTimer;
    procedure ConfigurarVisibilidadeSidebar;
    procedure AtualizarHora(Sender: TObject);

    { Sidebar button handlers }
    procedure BtnVendasClick(Sender: TObject);
    procedure BtnCaixaClick(Sender: TObject);
    procedure BtnVisitantesClick(Sender: TObject);
    procedure BtnFestasClick(Sender: TObject);
    procedure BtnProdutosClick(Sender: TObject);
    procedure BtnColaboradoresClick(Sender: TObject);
    procedure BtnRelatoriosClick(Sender: TObject);
    procedure BtnLogoutClick(Sender: TObject);

    { Sidebar button mouse feedback }
    procedure SidebarBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SidebarBtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    procedure NavegarPara(APagina: TPaginaPDV);
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
    property PaginaAtiva: TPaginaPDV read FPaginaAtiva;
    /// <summary>ID do caixa aberto (0 = nenhum)</summary>
    property CaixaId: Integer read FCaixaId write FCaixaId;
    /// <summary>Evento disparado ao clicar em Logout</summary>
    property OnLogout: TNotifyEvent read FOnLogout write FOnLogout;
  end;

implementation


const
  COR_HEADER = $FF1565C0;    // Blue 800
  COR_SIDEBAR = $FF1E88E5;   // Blue 600
  COR_SIDEBAR_HOVER = $FF1976D2; // Blue 700
  COR_FOOTER = $FF263238;    // Blue Grey 900
  COR_CONTENT_BG = $FFF5F5F5; // Grey 100
  COR_TEXTO_BRANCO = $FFFFFFFF;
  COR_TEXTO_CLARO = $FFECEFF1; // Blue Grey 50
  COR_BADGE_ALERTA = $FFFF5722; // Deep Orange
  COR_STATUS_OK = $FF4CAF50;   // Green 500

  SIDEBAR_WIDTH = 80;
  HEADER_HEIGHT = 56;
  FOOTER_HEIGHT = 40;
  BTN_SIZE = 64;       // Acima de 48px mínimo (req 13.1)
  BTN_SPACING = 8;     // Espaçamento mínimo entre botões (req 13.1)

{ TFrmMainPDV }

constructor TFrmMainPDV.Create(AOwner: TComponent; AColaboradorId: Integer;
  const AColaboradorNome, AColaboradorPapel: string);
begin
  inherited CreateNew(AOwner);

  FColaboradorId := AColaboradorId;
  FColaboradorNome := AColaboradorNome;
  FColaboradorPapel := AColaboradorPapel;
  FCaixaId := 0;
  FPaginaAtiva := ppVendas;

  Caption := 'SANCTO PDV';
  ClientWidth := 1024;
  ClientHeight := 768;
  Position := TFormPosition.ScreenCenter;
  BorderStyle := TFmxFormBorderStyle.Sizeable;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := COR_CONTENT_BG;
  WindowState := TWindowState.wsMaximized;

  CriarComponentes;
  ConfigurarVisibilidadeSidebar;
  CriarTimer;

  // Iniciar na página de Vendas
  NavegarPara(ppVendas);
end;

destructor TFrmMainPDV.Destroy;
begin
  if Assigned(FTimerRelogio) then
    FTimerRelogio.Enabled := False;
  inherited Destroy;
end;

procedure TFrmMainPDV.CriarComponentes;
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

procedure TFrmMainPDV.CriarHeader;
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

  // Logo "SANCTO PDV"
  FLblLogo := TLabel.Create(Self);
  FLblLogo.Parent := FLayoutHeader;
  FLblLogo.Align := TAlignLayout.Left;
  FLblLogo.Width := 160;
  FLblLogo.Margins.Left := 12;
  FLblLogo.Text := 'SANCTO PDV';
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
  FLblColaborador.Width := 250;
  FLblColaborador.Margins.Left := 16;
  FLblColaborador.Text := FColaboradorNome + ' (' + FColaboradorPapel + ')';
  FLblColaborador.StyledSettings := [];
  FLblColaborador.TextSettings.Font.Size := 14;
  FLblColaborador.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblColaborador.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblColaborador.TextSettings.VertAlign := TTextAlign.Center;

  // ID do Caixa
  FLblCaixaId := TLabel.Create(Self);
  FLblCaixaId.Parent := FLayoutHeader;
  FLblCaixaId.Align := TAlignLayout.Left;
  FLblCaixaId.Width := 120;
  FLblCaixaId.Margins.Left := 16;
  FLblCaixaId.Text := 'Caixa: --';
  FLblCaixaId.StyledSettings := [];
  FLblCaixaId.TextSettings.Font.Size := 14;
  FLblCaixaId.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblCaixaId.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblCaixaId.TextSettings.VertAlign := TTextAlign.Center;

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

procedure TFrmMainPDV.CriarSidebar;
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

  // Botões de navegação — todos os papéis
  // Emojis via surrogate pairs UTF-16 (Delphi 10.2 = UnicodeString UTF-16)
  LPosY := BTN_SPACING;

  FBtnVendas := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DED2) + #13#10 + 'Vendas', LPosY, BtnVendasClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  FBtnCaixa := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCB0) + #13#10 + 'Caixa', LPosY, BtnCaixaClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  FBtnVisitantes := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DC66) + #13#10 + 'Visitantes', LPosY, BtnVisitantesClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  FBtnFestas := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83C) + Char($DF82) + #13#10 + 'Festas', LPosY, BtnFestasClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  // Botões somente para ADMINISTRADOR e GERENTE (req 1.6)
  FBtnProdutos := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCE6) + #13#10 + 'Produtos', LPosY, BtnProdutosClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  FBtnColaboradores := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DC65) + #13#10 + 'Equipe', LPosY, BtnColaboradoresClick);
  LPosY := LPosY + BTN_SIZE + BTN_SPACING;

  FBtnRelatorios := CriarBotaoSidebar(FLayoutSidebar,
    Char($D83D) + Char($DCCA) + #13#10 + 'Relat.', LPosY, BtnRelatoriosClick);
end;

function TFrmMainPDV.CriarBotaoSidebar(AParent: TFmxObject;
  const ATexto: string; APosY: Single; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Position.X := (SIDEBAR_WIDTH - BTN_SIZE) / 2; // Centralizar horizontalmente
  Result.Position.Y := APosY;
  Result.Width := BTN_SIZE;
  Result.Height := BTN_SIZE;  // 64x64px > 48x48px mínimo (req 13.1)
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

procedure TFrmMainPDV.CriarContentArea;
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
  FLblContentPlaceholder.Text := 'Vendas';
end;

procedure TFrmMainPDV.CriarFooter;
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

  // Status fiscal (esquerda)
  FLblStatusFiscal := TLabel.Create(Self);
  FLblStatusFiscal.Parent := FLayoutFooter;
  FLblStatusFiscal.Align := TAlignLayout.Left;
  FLblStatusFiscal.Width := 200;
  FLblStatusFiscal.Margins.Left := 12;
  FLblStatusFiscal.Text := Char($2705) + ' Fiscal: Normal';
  FLblStatusFiscal.StyledSettings := [];
  FLblStatusFiscal.TextSettings.Font.Size := 12;
  FLblStatusFiscal.TextSettings.FontColor := COR_STATUS_OK;
  FLblStatusFiscal.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblStatusFiscal.TextSettings.VertAlign := TTextAlign.Center;

  // Alertas (direita)
  FLblAlertas := TLabel.Create(Self);
  FLblAlertas.Parent := FLayoutFooter;
  FLblAlertas.Align := TAlignLayout.Right;
  FLblAlertas.Width := 150;
  FLblAlertas.Margins.Right := 12;
  FLblAlertas.Text := '0 alertas';
  FLblAlertas.StyledSettings := [];
  FLblAlertas.TextSettings.Font.Size := 12;
  FLblAlertas.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblAlertas.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLblAlertas.TextSettings.VertAlign := TTextAlign.Center;

  // Hora no footer (centro)
  FLblHoraFooter := TLabel.Create(Self);
  FLblHoraFooter.Parent := FLayoutFooter;
  FLblHoraFooter.Align := TAlignLayout.Center;
  FLblHoraFooter.Width := 120;
  FLblHoraFooter.Text := FormatDateTime('hh:nn:ss', Now);
  FLblHoraFooter.StyledSettings := [];
  FLblHoraFooter.TextSettings.Font.Size := 14;
  FLblHoraFooter.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblHoraFooter.TextSettings.HorzAlign := TTextAlign.Center;
  FLblHoraFooter.TextSettings.VertAlign := TTextAlign.Center;
end;

procedure TFrmMainPDV.CriarTimer;
begin
  FTimerRelogio := TTimer.Create(Self);
  FTimerRelogio.Interval := 1000; // Atualizar a cada 1 segundo
  FTimerRelogio.OnTimer := AtualizarHora;
  FTimerRelogio.Enabled := True;
end;

procedure TFrmMainPDV.ConfigurarVisibilidadeSidebar;
var
  LEhAdmin: Boolean;
begin
  // Operacional vê: Vendas, Caixa, Visitantes, Festas (req 1.5)
  // Gerente/Admin vê todos (req 1.6)
  LEhAdmin := SameText(FColaboradorPapel, 'ADMINISTRADOR') or
              SameText(FColaboradorPapel, 'GERENTE');

  FBtnVendas.Visible := True;
  FBtnCaixa.Visible := True;
  FBtnVisitantes.Visible := True;
  FBtnFestas.Visible := True;

  FBtnProdutos.Visible := LEhAdmin;
  FBtnColaboradores.Visible := LEhAdmin;
  FBtnRelatorios.Visible := LEhAdmin;
end;

procedure TFrmMainPDV.AtualizarHora(Sender: TObject);
var
  LHoraAtual: string;
begin
  LHoraAtual := FormatDateTime('hh:nn:ss', Now);
  FLblHoraHeader.Text := LHoraAtual;
  FLblHoraFooter.Text := LHoraAtual;

  // Atualizar label do caixa
  if FCaixaId > 0 then
    FLblCaixaId.Text := 'Caixa: #' + IntToStr(FCaixaId)
  else
    FLblCaixaId.Text := 'Caixa: --';
end;

{ Sidebar button handlers }

procedure TFrmMainPDV.BtnVendasClick(Sender: TObject);
begin
  NavegarPara(ppVendas);
end;

procedure TFrmMainPDV.BtnCaixaClick(Sender: TObject);
begin
  NavegarPara(ppCaixa);
end;

procedure TFrmMainPDV.BtnVisitantesClick(Sender: TObject);
begin
  NavegarPara(ppVisitantes);
end;

procedure TFrmMainPDV.BtnFestasClick(Sender: TObject);
begin
  NavegarPara(ppFestas);
end;

procedure TFrmMainPDV.BtnProdutosClick(Sender: TObject);
begin
  NavegarPara(ppProdutos);
end;

procedure TFrmMainPDV.BtnColaboradoresClick(Sender: TObject);
begin
  NavegarPara(ppColaboradores);
end;

procedure TFrmMainPDV.BtnRelatoriosClick(Sender: TObject);
begin
  NavegarPara(ppRelatorios);
end;

procedure TFrmMainPDV.BtnLogoutClick(Sender: TObject);
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

procedure TFrmMainPDV.SidebarBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 0.92;
    TButton(Sender).Scale.Y := 0.92;
  end;
end;

procedure TFrmMainPDV.SidebarBtnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 1.0;
    TButton(Sender).Scale.Y := 1.0;
  end;
end;

procedure TFrmMainPDV.NavegarPara(APagina: TPaginaPDV);
begin
  FPaginaAtiva := APagina;
  AtualizarContentPlaceholder;
end;

procedure TFrmMainPDV.AtualizarContentPlaceholder;
begin
  case FPaginaAtiva of
    ppVendas:        FLblContentPlaceholder.Text := Char($D83D) + Char($DED2) + ' Vendas';
    ppCaixa:         FLblContentPlaceholder.Text := Char($D83D) + Char($DCB0) + ' Caixa';
    ppVisitantes:    FLblContentPlaceholder.Text := Char($D83D) + Char($DC66) + ' Visitantes';
    ppFestas:        FLblContentPlaceholder.Text := Char($D83C) + Char($DF82) + ' Festas';
    ppProdutos:      FLblContentPlaceholder.Text := Char($D83D) + Char($DCE6) + ' Produtos';
    ppColaboradores: FLblContentPlaceholder.Text := Char($D83D) + Char($DC65) + ' Colaboradores';
    ppRelatorios:    FLblContentPlaceholder.Text := Char($D83D) + Char($DCCA) + ' Relat' + Char($00F3) + 'rios';
  end;
end;

end.
