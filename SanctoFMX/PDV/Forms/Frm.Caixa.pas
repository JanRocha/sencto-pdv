unit Frm.Caixa;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Objects,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.Graphics,
  FMX.ListBox,
  Controller.Caixa,
  Model.Entidade.Caixa,
  Model.Entidade.MovimentacaoCaixa,
  Utils.Exceptions;

type
  /// <summary>
  /// Tela de Caixa do PDV.
  /// Criada programaticamente (sem .fmx).
  /// Seções:
  ///   1. Status card (topo): caixa aberto/fechado, colaborador, hora, saldo
  ///   2. Abertura de caixa (visível quando fechado)
  ///   3. Movimentações (visível quando aberto): sangria/suprimento
  ///   4. Fechamento (visível quando aberto): reconciliação financeira
  /// Touch-friendly: botões 48px+, fontes 14-18pt, espaçamento 8px.
  /// </summary>
  TFrmCaixa = class(TForm)
  private
    { Dados do operador }
    FColaboradorId: Integer;
    FColaboradorNome: string;

    { Controller }
    FController: TControllerCaixa;
    FCaixaAberto: Boolean;

    { Layout principal }
    FLayoutPrincipal: TLayout;
    FScrollBox: TVertScrollBox;

    { Seção 1 — Status Card }
    FRectStatus: TRectangle;
    FLblStatusTitulo: TLabel;
    FLblStatusColaborador: TLabel;
    FLblStatusHoraAbertura: TLabel;
    FLblStatusSaldo: TLabel;

    { Seção 2 — Abertura de Caixa }
    FLayoutAbertura: TLayout;
    FRectAbertura: TRectangle;
    FLblAberturaTitulo: TLabel;
    FLblAberturaValor: TLabel;
    FEdtAberturaValor: TEdit;
    FBtnAbrirCaixa: TButton;
    FLblAberturaErro: TLabel;

    { Seção 3 — Movimentações }
    FLayoutMovimentacoes: TLayout;
    FRectMovimentacoes: TRectangle;
    FLblMovTitulo: TLabel;
    FLblMovTipo: TLabel;
    FBtnTipoSangria: TButton;
    FBtnTipoSuprimento: TButton;
    FLayoutTipoBtns: TLayout;
    FLblMovValor: TLabel;
    FEdtMovValor: TEdit;
    FLblMovMotivo: TLabel;
    FEdtMovMotivo: TEdit;
    FBtnRegistrar: TButton;
    FLblMovErro: TLabel;

    { Lista de movimentações }
    FLblMovListaTitulo: TLabel;
    FListBoxMovimentacoes: TListBox;

    { Seção 4 — Fechamento }
    FLayoutFechamento: TLayout;
    FRectFechamento: TRectangle;
    FLblFechTitulo: TLabel;
    FLblFechSaldoEsperado: TLabel;
    FLblFechSaldoValor: TLabel;
    FLblFechContagem: TLabel;
    FEdtFechContagem: TEdit;
    FLblFechDiferenca: TLabel;
    FLblFechDiferencaValor: TLabel;
    FLblFechJustificativa: TLabel;
    FEdtFechJustificativa: TEdit;
    FBtnFecharCaixa: TButton;
    FLblFechErro: TLabel;

    { Tipo de movimentação selecionado }
    FTipoMovSelecionado: string; // 'SANGRIA' ou 'SUPRIMENTO'

    procedure CriarComponentes;
    procedure CriarStatusCard;
    procedure CriarSecaoAbertura;
    procedure CriarSecaoMovimentacoes;
    procedure CriarSecaoFechamento;
    procedure AtualizarEstado;
    procedure AtualizarStatusCard;
    procedure AtualizarListaMovimentacoes;
    procedure AtualizarDiferenca;

    { Event handlers }
    procedure BtnAbrirCaixaClick(Sender: TObject);
    procedure BtnTipoSangriaClick(Sender: TObject);
    procedure BtnTipoSuprimentoClick(Sender: TObject);
    procedure BtnRegistrarClick(Sender: TObject);
    procedure BtnFecharCaixaClick(Sender: TObject);
    procedure EdtFechContagemChangeTracking(Sender: TObject);

    { Touch feedback }
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    { Helpers }
    function ParseCurrency(const ATexto: string): Currency;
    procedure SelecionarTipoMov(const ATipo: string);
  public
    constructor Create(AOwner: TComponent; AColaboradorId: Integer;
      const AColaboradorNome: string); reintroduce;
    destructor Destroy; override;

    /// <summary>Atualiza a tela (recarrega dados do controller)</summary>
    procedure Refresh;

    property ColaboradorId: Integer read FColaboradorId;
    property CaixaAberto: Boolean read FCaixaAberto;
  end;

implementation

const
  COR_CARD_BG = $FFFFFFFF;
  COR_CARD_BORDER = $FFE0E0E0;
  COR_STATUS_ABERTO = $FF4CAF50;   // Green 500
  COR_STATUS_FECHADO = $FF9E9E9E;  // Grey 500
  COR_PRIMARIO = $FF1565C0;        // Blue 800
  COR_PERIGO = $FFD32F2F;          // Red 700
  COR_SUCESSO = $FF388E3C;         // Green 700
  COR_TEXTO = $FF212121;           // Grey 900
  COR_TEXTO_SEC = $FF757575;       // Grey 600
  COR_SELECIONADO = $FF1E88E5;     // Blue 600
  COR_NAO_SELECIONADO = $FFE0E0E0; // Grey 300

  PADDING_H = 16;
  PADDING_V = 12;
  BTN_HEIGHT = 52;
  EDIT_HEIGHT = 48;
  CARD_RADIUS = 8;

{ TFrmCaixa }

constructor TFrmCaixa.Create(AOwner: TComponent; AColaboradorId: Integer;
  const AColaboradorNome: string);
begin
  inherited CreateNew(AOwner);

  FColaboradorId := AColaboradorId;
  FColaboradorNome := AColaboradorNome;
  FCaixaAberto := False;
  FTipoMovSelecionado := 'SANGRIA';

  Caption := 'SANCTO PDV - Caixa';
  ClientWidth := 600;
  ClientHeight := 800;
  Position := TFormPosition.ScreenCenter;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := $FFF5F5F5; // Grey 100

  FController := TControllerCaixa.Create;

  CriarComponentes;

  // Verificar se já existe caixa aberto para este colaborador (mock: inicia fechado)
  AtualizarEstado;
end;

destructor TFrmCaixa.Destroy;
begin
  FController.Free;
  inherited Destroy;
end;

procedure TFrmCaixa.CriarComponentes;
begin
  // Layout principal
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;
  FLayoutPrincipal.Padding.Left := PADDING_H;
  FLayoutPrincipal.Padding.Right := PADDING_H;
  FLayoutPrincipal.Padding.Top := PADDING_V;
  FLayoutPrincipal.Padding.Bottom := PADDING_V;

  // ScrollBox para conteúdo scrollável
  FScrollBox := TVertScrollBox.Create(Self);
  FScrollBox.Parent := FLayoutPrincipal;
  FScrollBox.Align := TAlignLayout.Client;

  CriarStatusCard;
  CriarSecaoAbertura;
  CriarSecaoMovimentacoes;
  CriarSecaoFechamento;
end;

procedure TFrmCaixa.CriarStatusCard;
begin
  // Card de status (topo)
  FRectStatus := TRectangle.Create(Self);
  FRectStatus.Parent := FScrollBox;
  FRectStatus.Align := TAlignLayout.Top;
  FRectStatus.Height := 120;
  FRectStatus.Margins.Bottom := PADDING_V;
  FRectStatus.Fill.Kind := TBrushKind.Solid;
  FRectStatus.Fill.Color := COR_CARD_BG;
  FRectStatus.Stroke.Kind := TBrushKind.Solid;
  FRectStatus.Stroke.Color := COR_CARD_BORDER;
  FRectStatus.XRadius := CARD_RADIUS;
  FRectStatus.YRadius := CARD_RADIUS;

  // Título do status
  FLblStatusTitulo := TLabel.Create(Self);
  FLblStatusTitulo.Parent := FRectStatus;
  FLblStatusTitulo.Position.X := PADDING_H;
  FLblStatusTitulo.Position.Y := 12;
  FLblStatusTitulo.Width := 300;
  FLblStatusTitulo.Height := 28;
  FLblStatusTitulo.Text := 'CAIXA FECHADO';
  FLblStatusTitulo.StyledSettings := [];
  FLblStatusTitulo.TextSettings.Font.Size := 18;
  FLblStatusTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblStatusTitulo.TextSettings.FontColor := COR_STATUS_FECHADO;

  // Colaborador
  FLblStatusColaborador := TLabel.Create(Self);
  FLblStatusColaborador.Parent := FRectStatus;
  FLblStatusColaborador.Position.X := PADDING_H;
  FLblStatusColaborador.Position.Y := 42;
  FLblStatusColaborador.Width := 400;
  FLblStatusColaborador.Height := 22;
  FLblStatusColaborador.Text := 'Operador: ' + FColaboradorNome;
  FLblStatusColaborador.StyledSettings := [];
  FLblStatusColaborador.TextSettings.Font.Size := 14;
  FLblStatusColaborador.TextSettings.FontColor := COR_TEXTO_SEC;

  // Hora abertura
  FLblStatusHoraAbertura := TLabel.Create(Self);
  FLblStatusHoraAbertura.Parent := FRectStatus;
  FLblStatusHoraAbertura.Position.X := PADDING_H;
  FLblStatusHoraAbertura.Position.Y := 66;
  FLblStatusHoraAbertura.Width := 400;
  FLblStatusHoraAbertura.Height := 22;
  FLblStatusHoraAbertura.Text := 'Abertura: --';
  FLblStatusHoraAbertura.StyledSettings := [];
  FLblStatusHoraAbertura.TextSettings.Font.Size := 14;
  FLblStatusHoraAbertura.TextSettings.FontColor := COR_TEXTO_SEC;

  // Saldo atual
  FLblStatusSaldo := TLabel.Create(Self);
  FLblStatusSaldo.Parent := FRectStatus;
  FLblStatusSaldo.Position.X := PADDING_H;
  FLblStatusSaldo.Position.Y := 90;
  FLblStatusSaldo.Width := 400;
  FLblStatusSaldo.Height := 22;
  FLblStatusSaldo.Text := 'Saldo: R$ 0,00';
  FLblStatusSaldo.StyledSettings := [];
  FLblStatusSaldo.TextSettings.Font.Size := 16;
  FLblStatusSaldo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblStatusSaldo.TextSettings.FontColor := COR_TEXTO;
end;

procedure TFrmCaixa.CriarSecaoAbertura;
begin
  // Seção de abertura (visível quando caixa está fechado)
  FLayoutAbertura := TLayout.Create(Self);
  FLayoutAbertura.Parent := FScrollBox;
  FLayoutAbertura.Align := TAlignLayout.Top;
  FLayoutAbertura.Height := 220;
  FLayoutAbertura.Margins.Bottom := PADDING_V;

  // Card de abertura
  FRectAbertura := TRectangle.Create(Self);
  FRectAbertura.Parent := FLayoutAbertura;
  FRectAbertura.Align := TAlignLayout.Client;
  FRectAbertura.Fill.Kind := TBrushKind.Solid;
  FRectAbertura.Fill.Color := COR_CARD_BG;
  FRectAbertura.Stroke.Kind := TBrushKind.Solid;
  FRectAbertura.Stroke.Color := COR_CARD_BORDER;
  FRectAbertura.XRadius := CARD_RADIUS;
  FRectAbertura.YRadius := CARD_RADIUS;

  // Título
  FLblAberturaTitulo := TLabel.Create(Self);
  FLblAberturaTitulo.Parent := FRectAbertura;
  FLblAberturaTitulo.Position.X := PADDING_H;
  FLblAberturaTitulo.Position.Y := 12;
  FLblAberturaTitulo.Width := 300;
  FLblAberturaTitulo.Height := 28;
  FLblAberturaTitulo.Text := 'Abrir Caixa';
  FLblAberturaTitulo.StyledSettings := [];
  FLblAberturaTitulo.TextSettings.Font.Size := 16;
  FLblAberturaTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblAberturaTitulo.TextSettings.FontColor := COR_TEXTO;

  // Label valor inicial
  FLblAberturaValor := TLabel.Create(Self);
  FLblAberturaValor.Parent := FRectAbertura;
  FLblAberturaValor.Position.X := PADDING_H;
  FLblAberturaValor.Position.Y := 48;
  FLblAberturaValor.Width := 300;
  FLblAberturaValor.Height := 22;
  FLblAberturaValor.Text := 'Valor Inicial (R$)';
  FLblAberturaValor.StyledSettings := [];
  FLblAberturaValor.TextSettings.Font.Size := 14;
  FLblAberturaValor.TextSettings.FontColor := COR_TEXTO_SEC;

  // Edit valor inicial
  FEdtAberturaValor := TEdit.Create(Self);
  FEdtAberturaValor.Parent := FRectAbertura;
  FEdtAberturaValor.Position.X := PADDING_H;
  FEdtAberturaValor.Position.Y := 72;
  FEdtAberturaValor.Width := 300;
  FEdtAberturaValor.Height := EDIT_HEIGHT;
  FEdtAberturaValor.StyledSettings := [];
  FEdtAberturaValor.TextSettings.Font.Size := 16;
  FEdtAberturaValor.TextPrompt := '0,00';
  FEdtAberturaValor.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  FEdtAberturaValor.TabOrder := 0;

  // Botão Abrir Caixa
  FBtnAbrirCaixa := TButton.Create(Self);
  FBtnAbrirCaixa.Parent := FRectAbertura;
  FBtnAbrirCaixa.Position.X := PADDING_H;
  FBtnAbrirCaixa.Position.Y := 135;
  FBtnAbrirCaixa.Width := 300;
  FBtnAbrirCaixa.Height := BTN_HEIGHT;
  FBtnAbrirCaixa.Text := 'Abrir Caixa';
  FBtnAbrirCaixa.StyledSettings := [];
  FBtnAbrirCaixa.TextSettings.Font.Size := 16;
  FBtnAbrirCaixa.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnAbrirCaixa.OnClick := BtnAbrirCaixaClick;
  FBtnAbrirCaixa.OnMouseDown := BtnMouseDown;
  FBtnAbrirCaixa.OnMouseUp := BtnMouseUp;

  // Label erro abertura
  FLblAberturaErro := TLabel.Create(Self);
  FLblAberturaErro.Parent := FRectAbertura;
  FLblAberturaErro.Position.X := PADDING_H;
  FLblAberturaErro.Position.Y := 192;
  FLblAberturaErro.Width := 400;
  FLblAberturaErro.Height := 22;
  FLblAberturaErro.Text := '';
  FLblAberturaErro.StyledSettings := [];
  FLblAberturaErro.TextSettings.Font.Size := 13;
  FLblAberturaErro.TextSettings.FontColor := COR_PERIGO;
  FLblAberturaErro.Visible := False;
end;

procedure TFrmCaixa.CriarSecaoMovimentacoes;
begin
  // Seção de movimentações (visível quando caixa aberto)
  FLayoutMovimentacoes := TLayout.Create(Self);
  FLayoutMovimentacoes.Parent := FScrollBox;
  FLayoutMovimentacoes.Align := TAlignLayout.Top;
  FLayoutMovimentacoes.Height := 480;
  FLayoutMovimentacoes.Margins.Bottom := PADDING_V;
  FLayoutMovimentacoes.Visible := False;

  // Card de movimentações
  FRectMovimentacoes := TRectangle.Create(Self);
  FRectMovimentacoes.Parent := FLayoutMovimentacoes;
  FRectMovimentacoes.Align := TAlignLayout.Client;
  FRectMovimentacoes.Fill.Kind := TBrushKind.Solid;
  FRectMovimentacoes.Fill.Color := COR_CARD_BG;
  FRectMovimentacoes.Stroke.Kind := TBrushKind.Solid;
  FRectMovimentacoes.Stroke.Color := COR_CARD_BORDER;
  FRectMovimentacoes.XRadius := CARD_RADIUS;
  FRectMovimentacoes.YRadius := CARD_RADIUS;

  // Título movimentações
  FLblMovTitulo := TLabel.Create(Self);
  FLblMovTitulo.Parent := FRectMovimentacoes;
  FLblMovTitulo.Position.X := PADDING_H;
  FLblMovTitulo.Position.Y := 12;
  FLblMovTitulo.Width := 300;
  FLblMovTitulo.Height := 28;
  FLblMovTitulo.Text := 'Registrar Movimentação';
  FLblMovTitulo.StyledSettings := [];
  FLblMovTitulo.TextSettings.Font.Size := 16;
  FLblMovTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblMovTitulo.TextSettings.FontColor := COR_TEXTO;

  // Label tipo
  FLblMovTipo := TLabel.Create(Self);
  FLblMovTipo.Parent := FRectMovimentacoes;
  FLblMovTipo.Position.X := PADDING_H;
  FLblMovTipo.Position.Y := 44;
  FLblMovTipo.Width := 300;
  FLblMovTipo.Height := 22;
  FLblMovTipo.Text := 'Tipo';
  FLblMovTipo.StyledSettings := [];
  FLblMovTipo.TextSettings.Font.Size := 14;
  FLblMovTipo.TextSettings.FontColor := COR_TEXTO_SEC;

  // Layout para botões de tipo (Sangria / Suprimento)
  FLayoutTipoBtns := TLayout.Create(Self);
  FLayoutTipoBtns.Parent := FRectMovimentacoes;
  FLayoutTipoBtns.Position.X := PADDING_H;
  FLayoutTipoBtns.Position.Y := 68;
  FLayoutTipoBtns.Width := 400;
  FLayoutTipoBtns.Height := 48;

  // Botão Sangria
  FBtnTipoSangria := TButton.Create(Self);
  FBtnTipoSangria.Parent := FLayoutTipoBtns;
  FBtnTipoSangria.Position.X := 0;
  FBtnTipoSangria.Position.Y := 0;
  FBtnTipoSangria.Width := 150;
  FBtnTipoSangria.Height := 48;
  FBtnTipoSangria.Text := 'Sangria';
  FBtnTipoSangria.StyledSettings := [];
  FBtnTipoSangria.TextSettings.Font.Size := 14;
  FBtnTipoSangria.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnTipoSangria.OnClick := BtnTipoSangriaClick;
  FBtnTipoSangria.OnMouseDown := BtnMouseDown;
  FBtnTipoSangria.OnMouseUp := BtnMouseUp;

  // Botão Suprimento
  FBtnTipoSuprimento := TButton.Create(Self);
  FBtnTipoSuprimento.Parent := FLayoutTipoBtns;
  FBtnTipoSuprimento.Position.X := 160;
  FBtnTipoSuprimento.Position.Y := 0;
  FBtnTipoSuprimento.Width := 150;
  FBtnTipoSuprimento.Height := 48;
  FBtnTipoSuprimento.Text := 'Suprimento';
  FBtnTipoSuprimento.StyledSettings := [];
  FBtnTipoSuprimento.TextSettings.Font.Size := 14;
  FBtnTipoSuprimento.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnTipoSuprimento.OnClick := BtnTipoSuprimentoClick;
  FBtnTipoSuprimento.OnMouseDown := BtnMouseDown;
  FBtnTipoSuprimento.OnMouseUp := BtnMouseUp;

  // Label valor
  FLblMovValor := TLabel.Create(Self);
  FLblMovValor.Parent := FRectMovimentacoes;
  FLblMovValor.Position.X := PADDING_H;
  FLblMovValor.Position.Y := 124;
  FLblMovValor.Width := 300;
  FLblMovValor.Height := 22;
  FLblMovValor.Text := 'Valor (R$)';
  FLblMovValor.StyledSettings := [];
  FLblMovValor.TextSettings.Font.Size := 14;
  FLblMovValor.TextSettings.FontColor := COR_TEXTO_SEC;

  // Edit valor
  FEdtMovValor := TEdit.Create(Self);
  FEdtMovValor.Parent := FRectMovimentacoes;
  FEdtMovValor.Position.X := PADDING_H;
  FEdtMovValor.Position.Y := 148;
  FEdtMovValor.Width := 300;
  FEdtMovValor.Height := EDIT_HEIGHT;
  FEdtMovValor.StyledSettings := [];
  FEdtMovValor.TextSettings.Font.Size := 16;
  FEdtMovValor.TextPrompt := '0,00';
  FEdtMovValor.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  FEdtMovValor.TabOrder := 1;

  // Label motivo
  FLblMovMotivo := TLabel.Create(Self);
  FLblMovMotivo.Parent := FRectMovimentacoes;
  FLblMovMotivo.Position.X := PADDING_H;
  FLblMovMotivo.Position.Y := 204;
  FLblMovMotivo.Width := 300;
  FLblMovMotivo.Height := 22;
  FLblMovMotivo.Text := 'Motivo';
  FLblMovMotivo.StyledSettings := [];
  FLblMovMotivo.TextSettings.Font.Size := 14;
  FLblMovMotivo.TextSettings.FontColor := COR_TEXTO_SEC;

  // Edit motivo
  FEdtMovMotivo := TEdit.Create(Self);
  FEdtMovMotivo.Parent := FRectMovimentacoes;
  FEdtMovMotivo.Position.X := PADDING_H;
  FEdtMovMotivo.Position.Y := 228;
  FEdtMovMotivo.Width := 400;
  FEdtMovMotivo.Height := EDIT_HEIGHT;
  FEdtMovMotivo.StyledSettings := [];
  FEdtMovMotivo.TextSettings.Font.Size := 16;
  FEdtMovMotivo.TextPrompt := 'Descreva o motivo (mín. 3 caracteres)';
  FEdtMovMotivo.MaxLength := 200;
  FEdtMovMotivo.TabOrder := 2;

  // Botão Registrar
  FBtnRegistrar := TButton.Create(Self);
  FBtnRegistrar.Parent := FRectMovimentacoes;
  FBtnRegistrar.Position.X := PADDING_H;
  FBtnRegistrar.Position.Y := 290;
  FBtnRegistrar.Width := 300;
  FBtnRegistrar.Height := BTN_HEIGHT;
  FBtnRegistrar.Text := 'Registrar';
  FBtnRegistrar.StyledSettings := [];
  FBtnRegistrar.TextSettings.Font.Size := 16;
  FBtnRegistrar.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnRegistrar.OnClick := BtnRegistrarClick;
  FBtnRegistrar.OnMouseDown := BtnMouseDown;
  FBtnRegistrar.OnMouseUp := BtnMouseUp;

  // Label erro movimentação
  FLblMovErro := TLabel.Create(Self);
  FLblMovErro.Parent := FRectMovimentacoes;
  FLblMovErro.Position.X := PADDING_H;
  FLblMovErro.Position.Y := 346;
  FLblMovErro.Width := 450;
  FLblMovErro.Height := 22;
  FLblMovErro.Text := '';
  FLblMovErro.StyledSettings := [];
  FLblMovErro.TextSettings.Font.Size := 13;
  FLblMovErro.TextSettings.FontColor := COR_PERIGO;
  FLblMovErro.Visible := False;

  // Título lista de movimentações
  FLblMovListaTitulo := TLabel.Create(Self);
  FLblMovListaTitulo.Parent := FRectMovimentacoes;
  FLblMovListaTitulo.Position.X := PADDING_H;
  FLblMovListaTitulo.Position.Y := 374;
  FLblMovListaTitulo.Width := 300;
  FLblMovListaTitulo.Height := 24;
  FLblMovListaTitulo.Text := 'Movimentações Registradas';
  FLblMovListaTitulo.StyledSettings := [];
  FLblMovListaTitulo.TextSettings.Font.Size := 14;
  FLblMovListaTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblMovListaTitulo.TextSettings.FontColor := COR_TEXTO;

  // ListBox de movimentações (scrollável)
  FListBoxMovimentacoes := TListBox.Create(Self);
  FListBoxMovimentacoes.Parent := FRectMovimentacoes;
  FListBoxMovimentacoes.Position.X := PADDING_H;
  FListBoxMovimentacoes.Position.Y := 400;
  FListBoxMovimentacoes.Width := 530;
  FListBoxMovimentacoes.Height := 70;
  FListBoxMovimentacoes.ItemHeight := 32;

  // Seleção padrão: Sangria
  SelecionarTipoMov('SANGRIA');
end;

procedure TFrmCaixa.CriarSecaoFechamento;
begin
  // Seção de fechamento (visível quando caixa aberto)
  FLayoutFechamento := TLayout.Create(Self);
  FLayoutFechamento.Parent := FScrollBox;
  FLayoutFechamento.Align := TAlignLayout.Top;
  FLayoutFechamento.Height := 320;
  FLayoutFechamento.Margins.Bottom := PADDING_V;
  FLayoutFechamento.Visible := False;

  // Card de fechamento
  FRectFechamento := TRectangle.Create(Self);
  FRectFechamento.Parent := FLayoutFechamento;
  FRectFechamento.Align := TAlignLayout.Client;
  FRectFechamento.Fill.Kind := TBrushKind.Solid;
  FRectFechamento.Fill.Color := COR_CARD_BG;
  FRectFechamento.Stroke.Kind := TBrushKind.Solid;
  FRectFechamento.Stroke.Color := COR_CARD_BORDER;
  FRectFechamento.XRadius := CARD_RADIUS;
  FRectFechamento.YRadius := CARD_RADIUS;

  // Título fechamento
  FLblFechTitulo := TLabel.Create(Self);
  FLblFechTitulo.Parent := FRectFechamento;
  FLblFechTitulo.Position.X := PADDING_H;
  FLblFechTitulo.Position.Y := 12;
  FLblFechTitulo.Width := 300;
  FLblFechTitulo.Height := 28;
  FLblFechTitulo.Text := 'Fechar Caixa';
  FLblFechTitulo.StyledSettings := [];
  FLblFechTitulo.TextSettings.Font.Size := 16;
  FLblFechTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFechTitulo.TextSettings.FontColor := COR_TEXTO;

  // Label saldo esperado
  FLblFechSaldoEsperado := TLabel.Create(Self);
  FLblFechSaldoEsperado.Parent := FRectFechamento;
  FLblFechSaldoEsperado.Position.X := PADDING_H;
  FLblFechSaldoEsperado.Position.Y := 46;
  FLblFechSaldoEsperado.Width := 200;
  FLblFechSaldoEsperado.Height := 22;
  FLblFechSaldoEsperado.Text := 'Saldo Esperado:';
  FLblFechSaldoEsperado.StyledSettings := [];
  FLblFechSaldoEsperado.TextSettings.Font.Size := 14;
  FLblFechSaldoEsperado.TextSettings.FontColor := COR_TEXTO_SEC;

  // Valor do saldo esperado
  FLblFechSaldoValor := TLabel.Create(Self);
  FLblFechSaldoValor.Parent := FRectFechamento;
  FLblFechSaldoValor.Position.X := 220;
  FLblFechSaldoValor.Position.Y := 46;
  FLblFechSaldoValor.Width := 200;
  FLblFechSaldoValor.Height := 22;
  FLblFechSaldoValor.Text := 'R$ 0,00';
  FLblFechSaldoValor.StyledSettings := [];
  FLblFechSaldoValor.TextSettings.Font.Size := 16;
  FLblFechSaldoValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFechSaldoValor.TextSettings.FontColor := COR_TEXTO;

  // Label contagem física
  FLblFechContagem := TLabel.Create(Self);
  FLblFechContagem.Parent := FRectFechamento;
  FLblFechContagem.Position.X := PADDING_H;
  FLblFechContagem.Position.Y := 76;
  FLblFechContagem.Width := 300;
  FLblFechContagem.Height := 22;
  FLblFechContagem.Text := 'Contagem Física (R$)';
  FLblFechContagem.StyledSettings := [];
  FLblFechContagem.TextSettings.Font.Size := 14;
  FLblFechContagem.TextSettings.FontColor := COR_TEXTO_SEC;

  // Edit contagem física
  FEdtFechContagem := TEdit.Create(Self);
  FEdtFechContagem.Parent := FRectFechamento;
  FEdtFechContagem.Position.X := PADDING_H;
  FEdtFechContagem.Position.Y := 100;
  FEdtFechContagem.Width := 300;
  FEdtFechContagem.Height := EDIT_HEIGHT;
  FEdtFechContagem.StyledSettings := [];
  FEdtFechContagem.TextSettings.Font.Size := 16;
  FEdtFechContagem.TextPrompt := '0,00';
  FEdtFechContagem.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  FEdtFechContagem.OnChangeTracking := EdtFechContagemChangeTracking;
  FEdtFechContagem.TabOrder := 3;

  // Label diferença
  FLblFechDiferenca := TLabel.Create(Self);
  FLblFechDiferenca.Parent := FRectFechamento;
  FLblFechDiferenca.Position.X := PADDING_H;
  FLblFechDiferenca.Position.Y := 156;
  FLblFechDiferenca.Width := 150;
  FLblFechDiferenca.Height := 22;
  FLblFechDiferenca.Text := 'Diferença:';
  FLblFechDiferenca.StyledSettings := [];
  FLblFechDiferenca.TextSettings.Font.Size := 14;
  FLblFechDiferenca.TextSettings.FontColor := COR_TEXTO_SEC;

  // Valor da diferença (fica vermelho se > tolerância)
  FLblFechDiferencaValor := TLabel.Create(Self);
  FLblFechDiferencaValor.Parent := FRectFechamento;
  FLblFechDiferencaValor.Position.X := 170;
  FLblFechDiferencaValor.Position.Y := 156;
  FLblFechDiferencaValor.Width := 200;
  FLblFechDiferencaValor.Height := 22;
  FLblFechDiferencaValor.Text := 'R$ 0,00';
  FLblFechDiferencaValor.StyledSettings := [];
  FLblFechDiferencaValor.TextSettings.Font.Size := 16;
  FLblFechDiferencaValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFechDiferencaValor.TextSettings.FontColor := COR_SUCESSO;

  // Label justificativa (visível apenas se diferença > tolerância)
  FLblFechJustificativa := TLabel.Create(Self);
  FLblFechJustificativa.Parent := FRectFechamento;
  FLblFechJustificativa.Position.X := PADDING_H;
  FLblFechJustificativa.Position.Y := 184;
  FLblFechJustificativa.Width := 400;
  FLblFechJustificativa.Height := 22;
  FLblFechJustificativa.Text := 'Justificativa (obrigatória - mín. 10 caracteres)';
  FLblFechJustificativa.StyledSettings := [];
  FLblFechJustificativa.TextSettings.Font.Size := 14;
  FLblFechJustificativa.TextSettings.FontColor := COR_PERIGO;
  FLblFechJustificativa.Visible := False;

  // Edit justificativa
  FEdtFechJustificativa := TEdit.Create(Self);
  FEdtFechJustificativa.Parent := FRectFechamento;
  FEdtFechJustificativa.Position.X := PADDING_H;
  FEdtFechJustificativa.Position.Y := 208;
  FEdtFechJustificativa.Width := 450;
  FEdtFechJustificativa.Height := EDIT_HEIGHT;
  FEdtFechJustificativa.StyledSettings := [];
  FEdtFechJustificativa.TextSettings.Font.Size := 16;
  FEdtFechJustificativa.TextPrompt := 'Justifique a diferença encontrada';
  FEdtFechJustificativa.Visible := False;
  FEdtFechJustificativa.TabOrder := 4;

  // Botão Fechar Caixa
  FBtnFecharCaixa := TButton.Create(Self);
  FBtnFecharCaixa.Parent := FRectFechamento;
  FBtnFecharCaixa.Position.X := PADDING_H;
  FBtnFecharCaixa.Position.Y := 264;
  FBtnFecharCaixa.Width := 300;
  FBtnFecharCaixa.Height := BTN_HEIGHT;
  FBtnFecharCaixa.Text := 'Fechar Caixa';
  FBtnFecharCaixa.StyledSettings := [];
  FBtnFecharCaixa.TextSettings.Font.Size := 16;
  FBtnFecharCaixa.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnFecharCaixa.OnClick := BtnFecharCaixaClick;
  FBtnFecharCaixa.OnMouseDown := BtnMouseDown;
  FBtnFecharCaixa.OnMouseUp := BtnMouseUp;

  // Label erro fechamento
  FLblFechErro := TLabel.Create(Self);
  FLblFechErro.Parent := FRectFechamento;
  FLblFechErro.Position.X := PADDING_H;
  FLblFechErro.Position.Y := 294;
  FLblFechErro.Width := 450;
  FLblFechErro.Height := 22;
  FLblFechErro.Text := '';
  FLblFechErro.StyledSettings := [];
  FLblFechErro.TextSettings.Font.Size := 13;
  FLblFechErro.TextSettings.FontColor := COR_PERIGO;
  FLblFechErro.Visible := False;
end;

{ Estado e atualização }

procedure TFrmCaixa.AtualizarEstado;
var
  LCaixa: TCaixa;
begin
  // Verificar se existe caixa aberto para o colaborador
  LCaixa := FController.CaixaAberto(FColaboradorId);
  try
    if Assigned(LCaixa) then
    begin
      // Caixa aberto encontrado: carregar no controller
      FCaixaAberto := True;
      FController.Free;
      FController := TControllerCaixa.Create(LCaixa.Id);
    end
    else
    begin
      // Nenhum caixa aberto: modo abertura
      FCaixaAberto := False;
    end;
  finally
    LCaixa.Free;
  end;

  // Atualizar visibilidade das seções
  FLayoutAbertura.Visible := not FCaixaAberto;
  FLayoutMovimentacoes.Visible := FCaixaAberto;
  FLayoutFechamento.Visible := FCaixaAberto;

  // Atualizar status card
  AtualizarStatusCard;

  // Atualizar lista de movimentações se aberto
  if FCaixaAberto then
  begin
    AtualizarListaMovimentacoes;
    AtualizarDiferenca;
  end;
end;

procedure TFrmCaixa.AtualizarStatusCard;
var
  LSaldo: Currency;
begin
  if FCaixaAberto then
  begin
    FLblStatusTitulo.Text := 'CAIXA ABERTO';
    FLblStatusTitulo.TextSettings.FontColor := COR_STATUS_ABERTO;
    FLblStatusHoraAbertura.Text := 'Abertura: ' +
      FormatDateTime('dd/mm/yyyy hh:nn', FController.Entidade.Data_Abertura);
    LSaldo := FController.CalcularSaldoEsperado;
    FLblStatusSaldo.Text := Format('Saldo: R$ %.2f', [LSaldo]);
  end
  else
  begin
    FLblStatusTitulo.Text := 'CAIXA FECHADO';
    FLblStatusTitulo.TextSettings.FontColor := COR_STATUS_FECHADO;
    FLblStatusHoraAbertura.Text := 'Abertura: --';
    FLblStatusSaldo.Text := 'Saldo: R$ 0,00';
  end;
end;

procedure TFrmCaixa.AtualizarListaMovimentacoes;
var
  I: Integer;
  LMov: TMovimentacaoCaixa;
  LItem: TListBoxItem;
  LTexto: string;
begin
  FListBoxMovimentacoes.Clear;

  for I := 0 to FController.Movimentacoes.Count - 1 do
  begin
    LMov := FController.Movimentacoes[I];
    LTexto := Format('%s | R$ %.2f | %s | %s',
      [LMov.Tipo, LMov.Valor, LMov.Motivo,
       FormatDateTime('hh:nn', LMov.Data_Hora)]);

    LItem := TListBoxItem.Create(FListBoxMovimentacoes);
    LItem.Parent := FListBoxMovimentacoes;
    LItem.Text := LTexto;
    LItem.StyledSettings := [];
    LItem.TextSettings.Font.Size := 12;
    if LMov.Tipo = 'SANGRIA' then
      LItem.TextSettings.FontColor := COR_PERIGO
    else
      LItem.TextSettings.FontColor := COR_SUCESSO;
  end;

  // Ajustar altura do ListBox baseado no número de itens
  if FController.Movimentacoes.Count > 0 then
    FListBoxMovimentacoes.Height :=
      Min(FController.Movimentacoes.Count * 32, 160)
  else
    FListBoxMovimentacoes.Height := 32;
end;

procedure TFrmCaixa.AtualizarDiferenca;
var
  LSaldoEsperado: Currency;
  LContagem: Currency;
  LDiferenca: Currency;
begin
  LSaldoEsperado := FController.CalcularSaldoEsperado;
  FLblFechSaldoValor.Text := Format('R$ %.2f', [LSaldoEsperado]);

  // Calcular diferença se há contagem informada
  if FEdtFechContagem.Text <> '' then
  begin
    LContagem := ParseCurrency(FEdtFechContagem.Text);
    LDiferenca := LContagem - LSaldoEsperado;
    FLblFechDiferencaValor.Text := Format('R$ %.2f', [LDiferenca]);

    // Mostrar vermelho se diferença > tolerância
    if Abs(LDiferenca) > FController.Tolerancia then
    begin
      FLblFechDiferencaValor.TextSettings.FontColor := COR_PERIGO;
      FLblFechJustificativa.Visible := True;
      FEdtFechJustificativa.Visible := True;
    end
    else
    begin
      FLblFechDiferencaValor.TextSettings.FontColor := COR_SUCESSO;
      FLblFechJustificativa.Visible := False;
      FEdtFechJustificativa.Visible := False;
    end;
  end
  else
  begin
    FLblFechDiferencaValor.Text := 'R$ 0,00';
    FLblFechDiferencaValor.TextSettings.FontColor := COR_SUCESSO;
    FLblFechJustificativa.Visible := False;
    FEdtFechJustificativa.Visible := False;
  end;
end;

procedure TFrmCaixa.Refresh;
begin
  AtualizarEstado;
end;

{ Event handlers }

procedure TFrmCaixa.BtnAbrirCaixaClick(Sender: TObject);
var
  LValor: Currency;
begin
  FLblAberturaErro.Visible := False;

  try
    LValor := ParseCurrency(FEdtAberturaValor.Text);
  except
    FLblAberturaErro.Text := 'Valor inválido. Use formato numérico (ex: 100,00).';
    FLblAberturaErro.Visible := True;
    Exit;
  end;

  try
    FController.AbrirCaixa(LValor, FColaboradorId);
    FCaixaAberto := True;
    FEdtAberturaValor.Text := '';
    AtualizarEstado;
  except
    on E: EValidacaoException do
    begin
      FLblAberturaErro.Text := E.Message;
      FLblAberturaErro.Visible := True;
    end;
    on E: ECaixaException do
    begin
      FLblAberturaErro.Text := E.Message;
      FLblAberturaErro.Visible := True;
    end;
  end;
end;

procedure TFrmCaixa.BtnTipoSangriaClick(Sender: TObject);
begin
  SelecionarTipoMov('SANGRIA');
end;

procedure TFrmCaixa.BtnTipoSuprimentoClick(Sender: TObject);
begin
  SelecionarTipoMov('SUPRIMENTO');
end;

procedure TFrmCaixa.BtnRegistrarClick(Sender: TObject);
var
  LValor: Currency;
  LMotivo: string;
  LResult: Boolean;
begin
  FLblMovErro.Visible := False;

  // Validar valor
  try
    LValor := ParseCurrency(FEdtMovValor.Text);
  except
    FLblMovErro.Text := 'Valor inválido. Use formato numérico (ex: 50,00).';
    FLblMovErro.Visible := True;
    Exit;
  end;

  LMotivo := Trim(FEdtMovMotivo.Text);

  try
    if FTipoMovSelecionado = 'SANGRIA' then
      LResult := FController.RegistrarSangria(LValor, LMotivo)
    else
      LResult := FController.RegistrarSuprimento(LValor, LMotivo);

    if LResult then
    begin
      // Limpar campos após sucesso
      FEdtMovValor.Text := '';
      FEdtMovMotivo.Text := '';
      AtualizarStatusCard;
      AtualizarListaMovimentacoes;
      AtualizarDiferenca;
    end;
  except
    on E: EValidacaoException do
    begin
      FLblMovErro.Text := E.Message;
      FLblMovErro.Visible := True;
    end;
    on E: ECaixaException do
    begin
      FLblMovErro.Text := E.Message;
      FLblMovErro.Visible := True;
    end;
  end;
end;

procedure TFrmCaixa.BtnFecharCaixaClick(Sender: TObject);
var
  LContagem: Currency;
  LJustificativa: string;
begin
  FLblFechErro.Visible := False;

  // Validar contagem
  try
    LContagem := ParseCurrency(FEdtFechContagem.Text);
  except
    FLblFechErro.Text := 'Contagem inválida. Use formato numérico (ex: 500,00).';
    FLblFechErro.Visible := True;
    Exit;
  end;

  LJustificativa := Trim(FEdtFechJustificativa.Text);

  try
    FController.FecharCaixa(LContagem, LJustificativa);
    FCaixaAberto := False;

    // Limpar campos
    FEdtFechContagem.Text := '';
    FEdtFechJustificativa.Text := '';

    // Recriar controller para próximo caixa
    FController.Free;
    FController := TControllerCaixa.Create;

    AtualizarEstado;
  except
    on E: EValidacaoException do
    begin
      FLblFechErro.Text := E.Message;
      FLblFechErro.Visible := True;
    end;
    on E: ECaixaException do
    begin
      FLblFechErro.Text := E.Message;
      FLblFechErro.Visible := True;
    end;
  end;
end;

procedure TFrmCaixa.EdtFechContagemChangeTracking(Sender: TObject);
begin
  // Recalcular diferença ao digitar contagem
  if FCaixaAberto then
    AtualizarDiferenca;
end;

{ Touch feedback — <100ms (req 13.2) }

procedure TFrmCaixa.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 0.94;
    TButton(Sender).Scale.Y := 0.94;
  end;
end;

procedure TFrmCaixa.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 1.0;
    TButton(Sender).Scale.Y := 1.0;
  end;
end;

{ Helpers }

function TFrmCaixa.ParseCurrency(const ATexto: string): Currency;
var
  LTexto: string;
begin
  LTexto := Trim(ATexto);
  if LTexto = '' then
  begin
    Result := 0;
    Exit;
  end;

  // Substituir vírgula por ponto para conversão
  LTexto := StringReplace(LTexto, '.', '', [rfReplaceAll]); // Remove separador de milhar
  LTexto := StringReplace(LTexto, ',', '.', [rfReplaceAll]); // Vírgula decimal -> ponto

  Result := StrToCurr(LTexto);
end;

procedure TFrmCaixa.SelecionarTipoMov(const ATipo: string);
begin
  FTipoMovSelecionado := ATipo;

  // Feedback visual nos botões de tipo
  if ATipo = 'SANGRIA' then
  begin
    FBtnTipoSangria.TextSettings.FontColor := COR_CARD_BG;
    FBtnTipoSuprimento.TextSettings.FontColor := COR_TEXTO;
  end
  else
  begin
    FBtnTipoSangria.TextSettings.FontColor := COR_TEXTO;
    FBtnTipoSuprimento.TextSettings.FontColor := COR_CARD_BG;
  end;
end;

end.
