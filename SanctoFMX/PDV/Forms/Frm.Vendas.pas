unit Frm.Vendas;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Generics.Collections,
  System.Math,
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
  Model.Entidade.Categoria,
  Model.Entidade.Produto,
  Model.Entidade.VendaItem,
  Controller.Venda;

type
  TFrmVendas = class(TForm)
  private
    { Colaborador }
    FColaboradorId: Integer;
    FColaboradorNome: string;
    FColaboradorPapel: string;

    { Controller }
    FControllerVenda: TControllerVenda;

    { Mock data }
    FCategorias: TObjectList<TCategoria>;
    FProdutos: TObjectList<TProduto>;
    FCategoriaSelecionadaId: Integer;

    { Top bar }
    FLayoutTopBar: TLayout;
    FRectTopBar: TRectangle;
    FEdtBusca: TEdit;
    FLblAtalhoF2: TLabel;
    FBtnMenu: TButton;
    FBtnFullscreen: TButton;

    { Main content area }
    FLayoutContent: TLayout;

    { Left panel - Produtos }
    FLayoutLeftPanel: TLayout;
    FLblProdutosTitulo: TLabel;
    FLayoutCategoryPills: TLayout;
    FScrollCategoryPills: THorzScrollBox;
    FScrollProdutos: TVertScrollBox;
    FFlowProdutos: TFlowLayout;
    FPillButtons: TObjectList<TRectangle>;

    { Right panel - Venda atual }
    FLayoutRightPanel: TLayout;
    FRectRightPanel: TRectangle;
    FLblVendaTitulo: TLabel;
    FScrollCarrinhoItens: TVertScrollBox;
    FLayoutCartFooter: TLayout;
    FEdtDesconto: TEdit;
    FLblDescontoPercent: TLabel;
    FLblSubtotal: TLabel;
    FLblDesconto: TLabel;
    FLblTotal: TLabel;
    FBtnFinalizar: TButton;

    { Bottom bar }
    FLayoutBottomBar: TLayout;
    FRectBottomBar: TRectangle;
    FLblOperador: TLabel;
    FBtnCancelar: TButton;
    FBtnSalvar: TButton;
    FBtnConfig: TButton;

    { Splitter visual }
    FRectSplitter: TRectangle;

    procedure CriarTopBar;
    procedure CriarContent;
    procedure CriarLeftPanel;
    procedure CriarCategoryPills;
    procedure CriarRightPanel;
    procedure CriarBottomBar;

    { Mock data }
    procedure PopularDadosMock;

    { Category pills }
    procedure RenderizarPills;
    procedure PillClick(Sender: TObject);
    procedure AtualizarPillAtiva;
    function CriarPill(const ATexto: string; ATag: Integer; ACor: TAlphaColor): TRectangle;

    { Produtos }
    procedure RenderizarProdutos;
    procedure ProdutoCardClick(Sender: TObject);
    function CriarCardProduto(AProduto: TProduto): TLayout;

    { Carrinho }
    procedure AtualizarCarrinho;
    procedure RenderizarItensCarrinho;
    procedure AtualizarTotais;
    procedure BtnMaisClick(Sender: TObject);
    procedure BtnMenosClick(Sender: TObject);
    procedure BtnRemoverClick(Sender: TObject);
    procedure EdtDescontoChange(Sender: TObject);

    { Actions }
    procedure BtnFinalizarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure EdtBuscaChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure ExibirDialogPagamento;

    { Helpers }
    function FormatarMoeda(AValor: Currency): string;
    function GetProdutoPorId(AId: Integer): TProduto;
    function GetCorCategoria(AIndex: Integer): TAlphaColor;
  public
    constructor Create(AOwner: TComponent; AColaboradorId: Integer;
      const AColaboradorNome, AColaboradorPapel: string); reintroduce;
    destructor Destroy; override;

    property ColaboradorId: Integer read FColaboradorId;
    property ColaboradorNome: string read FColaboradorNome;
    property ColaboradorPapel: string read FColaboradorPapel;
    property ControllerVenda: TControllerVenda read FControllerVenda;
  end;

implementation

const
  { Cores principais }
  COR_BRANCO         = $FFFFFFFF;
  COR_FUNDO          = $FFFFFFFF;
  COR_AZUL_ATIVO     = $FF2979FF;
  COR_AZUL_PRECO     = $FF2979FF;
  COR_AZUL_ESCURO    = $FF1565C0;
  COR_TEXTO_ESCURO   = $FF212121;
  COR_TEXTO_CINZA    = $FF616161;
  COR_TEXTO_CLARO    = $FF9E9E9E;
  COR_FUNDO_CINZA    = $FFF5F5F5;
  COR_BORDA_LEVE     = $FFE0E0E0;
  COR_BOTTOM_BAR     = $FFF5F5F5;
  COR_TOP_BAR        = $FFFFFFFF;
  COR_RIGHT_PANEL    = $FFFAFAFA;
  COR_BTN_FINALIZAR  = $FF2979FF;
  COR_BTN_CANCELAR   = $FFEF5350;
  COR_BTN_SALVAR     = $FF66BB6A;
  COR_VERDE_TOTAL    = $FF2E7D32;

  { Cores para pills de categoria (playful) }
  COR_PILL_LANCHES    = $FFFFA726;  // Orange
  COR_PILL_BEBIDAS    = $FF42A5F5;  // Blue
  COR_PILL_INGRESSOS  = $FF66BB6A;  // Green
  COR_PILL_BRINQUEDOS = $FFAB47BC;  // Purple
  COR_PILL_DOCES      = $FFEC407A;  // Pink
  COR_PILL_PAPELARIA  = $FF26C6DA;  // Cyan

  { Dimensoes }
  TOP_BAR_HEIGHT     = 56;
  BOTTOM_BAR_HEIGHT  = 52;
  RIGHT_PANEL_WIDTH  = 340;
  PILL_HEIGHT        = 36;
  PILL_SPACING       = 8;
  CARD_WIDTH         = 150;
  CARD_HEIGHT        = 160;
  CARD_SPACING       = 12;
  BTN_MIN_HEIGHT     = 44;
  FONT_SMALL         = 12;
  FONT_NORMAL        = 14;
  FONT_LARGE         = 16;
  FONT_TITLE         = 18;
  FONT_TOTAL         = 22;

{ TFrmVendas }

constructor TFrmVendas.Create(AOwner: TComponent; AColaboradorId: Integer;
  const AColaboradorNome, AColaboradorPapel: string);
begin
  inherited CreateNew(AOwner);

  FColaboradorId := AColaboradorId;
  FColaboradorNome := AColaboradorNome;
  FColaboradorPapel := AColaboradorPapel;

  FControllerVenda := TControllerVenda.Create;
  FCategorias := TObjectList<TCategoria>.Create(True);
  FProdutos := TObjectList<TProduto>.Create(True);
  FPillButtons := TObjectList<TRectangle>.Create(False);
  FCategoriaSelecionadaId := 0;

  { Form setup }
  Caption := 'Sancto PDV - Ponto de Venda';
  WindowState := TWindowState.wsMaximized;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := COR_FUNDO;
  BorderStyle := TFmxFormBorderStyle.Sizeable;
  OnKeyDown := FormKeyDown;

  { Build UI }
  CriarTopBar;
  CriarBottomBar;
  CriarContent;

  { Load data }
  PopularDadosMock;
  RenderizarPills;
  RenderizarProdutos;
  AtualizarTotais;
end;

destructor TFrmVendas.Destroy;
begin
  FPillButtons.Free;
  FCategorias.Free;
  FProdutos.Free;
  FControllerVenda.Free;
  inherited Destroy;
end;

procedure TFrmVendas.CriarTopBar;
begin
  FLayoutTopBar := TLayout.Create(Self);
  FLayoutTopBar.Parent := Self;
  FLayoutTopBar.Align := TAlignLayout.Top;
  FLayoutTopBar.Height := TOP_BAR_HEIGHT;

  FRectTopBar := TRectangle.Create(Self);
  FRectTopBar.Parent := FLayoutTopBar;
  FRectTopBar.Align := TAlignLayout.Client;
  FRectTopBar.Fill.Kind := TBrushKind.Solid;
  FRectTopBar.Fill.Color := COR_TOP_BAR;
  FRectTopBar.Stroke.Kind := TBrushKind.None;
  FRectTopBar.HitTest := False;

  { Bottom border line }
  with TRectangle.Create(Self) do
  begin
    Parent := FLayoutTopBar;
    Align := TAlignLayout.Bottom;
    Height := 1;
    Fill.Kind := TBrushKind.Solid;
    Fill.Color := COR_BORDA_LEVE;
    Stroke.Kind := TBrushKind.None;
    HitTest := False;
  end;

  { Search edit }
  FEdtBusca := TEdit.Create(Self);
  FEdtBusca.Parent := FLayoutTopBar;
  FEdtBusca.Align := TAlignLayout.Client;
  FEdtBusca.StyledSettings := [];
  FEdtBusca.TextSettings.Font.Size := FONT_NORMAL;
  FEdtBusca.TextPrompt := 'Buscar produto...';
  FEdtBusca.Margins.Left := 16;
  FEdtBusca.Margins.Top := 10;
  FEdtBusca.Margins.Bottom := 10;
  FEdtBusca.Margins.Right := 8;
  FEdtBusca.OnChange := EdtBuscaChange;

  { F2 hint label }
  FLblAtalhoF2 := TLabel.Create(Self);
  FLblAtalhoF2.Parent := FLayoutTopBar;
  FLblAtalhoF2.Align := TAlignLayout.Right;
  FLblAtalhoF2.Width := 40;
  FLblAtalhoF2.Text := '[F2]';
  FLblAtalhoF2.StyledSettings := [];
  FLblAtalhoF2.TextSettings.Font.Size := FONT_SMALL;
  FLblAtalhoF2.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblAtalhoF2.TextSettings.HorzAlign := TTextAlign.Center;
  FLblAtalhoF2.TextSettings.VertAlign := TTextAlign.Center;
  FLblAtalhoF2.HitTest := False;

  { Menu button }
  FBtnMenu := TButton.Create(Self);
  FBtnMenu.Parent := FLayoutTopBar;
  FBtnMenu.Align := TAlignLayout.Right;
  FBtnMenu.Width := 44;
  FBtnMenu.Text := #$2261; // hamburger
  FBtnMenu.StyledSettings := [];
  FBtnMenu.TextSettings.Font.Size := 20;
  FBtnMenu.Margins.Right := 4;
  FBtnMenu.Margins.Top := 6;
  FBtnMenu.Margins.Bottom := 6;

  { Fullscreen button }
  FBtnFullscreen := TButton.Create(Self);
  FBtnFullscreen.Parent := FLayoutTopBar;
  FBtnFullscreen.Align := TAlignLayout.Right;
  FBtnFullscreen.Width := 44;
  FBtnFullscreen.Text := #$229E; // square grid
  FBtnFullscreen.StyledSettings := [];
  FBtnFullscreen.TextSettings.Font.Size := 18;
  FBtnFullscreen.Margins.Right := 8;
  FBtnFullscreen.Margins.Top := 6;
  FBtnFullscreen.Margins.Bottom := 6;
end;

procedure TFrmVendas.CriarBottomBar;
begin
  FLayoutBottomBar := TLayout.Create(Self);
  FLayoutBottomBar.Parent := Self;
  FLayoutBottomBar.Align := TAlignLayout.Bottom;
  FLayoutBottomBar.Height := BOTTOM_BAR_HEIGHT;

  FRectBottomBar := TRectangle.Create(Self);
  FRectBottomBar.Parent := FLayoutBottomBar;
  FRectBottomBar.Align := TAlignLayout.Client;
  FRectBottomBar.Fill.Kind := TBrushKind.Solid;
  FRectBottomBar.Fill.Color := COR_BOTTOM_BAR;
  FRectBottomBar.Stroke.Kind := TBrushKind.None;
  FRectBottomBar.HitTest := False;

  { Top border line }
  with TRectangle.Create(Self) do
  begin
    Parent := FLayoutBottomBar;
    Align := TAlignLayout.Top;
    Height := 1;
    Fill.Kind := TBrushKind.Solid;
    Fill.Color := COR_BORDA_LEVE;
    Stroke.Kind := TBrushKind.None;
    HitTest := False;
  end;

  { Operator label }
  FLblOperador := TLabel.Create(Self);
  FLblOperador.Parent := FLayoutBottomBar;
  FLblOperador.Align := TAlignLayout.Left;
  FLblOperador.Width := 280;
  FLblOperador.Text := FColaboradorNome + ' (' + FColaboradorPapel + ')';
  FLblOperador.StyledSettings := [];
  FLblOperador.TextSettings.Font.Size := FONT_NORMAL;
  FLblOperador.TextSettings.FontColor := COR_TEXTO_CINZA;
  FLblOperador.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblOperador.TextSettings.VertAlign := TTextAlign.Center;
  FLblOperador.Margins.Left := 16;

  { Config button }
  FBtnConfig := TButton.Create(Self);
  FBtnConfig.Parent := FLayoutBottomBar;
  FBtnConfig.Align := TAlignLayout.Right;
  FBtnConfig.Width := 44;
  FBtnConfig.Height := BTN_MIN_HEIGHT;
  FBtnConfig.Text := #$2699; // gear
  FBtnConfig.StyledSettings := [];
  FBtnConfig.TextSettings.Font.Size := 18;
  FBtnConfig.Margins.Right := 12;
  FBtnConfig.Margins.Top := 4;
  FBtnConfig.Margins.Bottom := 4;

  { Save button }
  FBtnSalvar := TButton.Create(Self);
  FBtnSalvar.Parent := FLayoutBottomBar;
  FBtnSalvar.Align := TAlignLayout.Right;
  FBtnSalvar.Width := 130;
  FBtnSalvar.Height := BTN_MIN_HEIGHT;
  FBtnSalvar.Text := 'Salvar [F3]';
  FBtnSalvar.StyledSettings := [];
  FBtnSalvar.TextSettings.Font.Size := FONT_NORMAL;
  FBtnSalvar.TextSettings.FontColor := COR_BTN_SALVAR;
  FBtnSalvar.Margins.Right := 8;
  FBtnSalvar.Margins.Top := 4;
  FBtnSalvar.Margins.Bottom := 4;
  FBtnSalvar.OnClick := BtnSalvarClick;

  { Cancel button }
  FBtnCancelar := TButton.Create(Self);
  FBtnCancelar.Parent := FLayoutBottomBar;
  FBtnCancelar.Align := TAlignLayout.Right;
  FBtnCancelar.Width := 150;
  FBtnCancelar.Height := BTN_MIN_HEIGHT;
  FBtnCancelar.Text := 'Cancelar [Esc]';
  FBtnCancelar.StyledSettings := [];
  FBtnCancelar.TextSettings.Font.Size := FONT_NORMAL;
  FBtnCancelar.TextSettings.FontColor := COR_BTN_CANCELAR;
  FBtnCancelar.Margins.Right := 8;
  FBtnCancelar.Margins.Top := 4;
  FBtnCancelar.Margins.Bottom := 4;
  FBtnCancelar.OnClick := BtnCancelarClick;
end;

procedure TFrmVendas.CriarContent;
begin
  FLayoutContent := TLayout.Create(Self);
  FLayoutContent.Parent := Self;
  FLayoutContent.Align := TAlignLayout.Client;

  CriarRightPanel;
  CriarLeftPanel;
end;

procedure TFrmVendas.CriarLeftPanel;
begin
  FLayoutLeftPanel := TLayout.Create(Self);
  FLayoutLeftPanel.Parent := FLayoutContent;
  FLayoutLeftPanel.Align := TAlignLayout.Client;
  FLayoutLeftPanel.Padding.Left := 16;
  FLayoutLeftPanel.Padding.Top := 12;
  FLayoutLeftPanel.Padding.Right := 8;

  { Title "Produtos" }
  FLblProdutosTitulo := TLabel.Create(Self);
  FLblProdutosTitulo.Parent := FLayoutLeftPanel;
  FLblProdutosTitulo.Align := TAlignLayout.Top;
  FLblProdutosTitulo.Height := 30;
  FLblProdutosTitulo.Text := 'Produtos';
  FLblProdutosTitulo.StyledSettings := [];
  FLblProdutosTitulo.TextSettings.Font.Size := FONT_TITLE;
  FLblProdutosTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblProdutosTitulo.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblProdutosTitulo.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblProdutosTitulo.TextSettings.VertAlign := TTextAlign.Center;

  CriarCategoryPills;

  { Products grid }
  FScrollProdutos := TVertScrollBox.Create(Self);
  FScrollProdutos.Parent := FLayoutLeftPanel;
  FScrollProdutos.Align := TAlignLayout.Client;
  FScrollProdutos.ShowScrollBars := True;

  FFlowProdutos := TFlowLayout.Create(Self);
  FFlowProdutos.Parent := FScrollProdutos;
  FFlowProdutos.Align := TAlignLayout.Top;
  FFlowProdutos.Justify := TFlowJustify.Left;
  FFlowProdutos.JustifyLastLine := TFlowJustify.Left;
  FFlowProdutos.HorizontalGap := CARD_SPACING;
  FFlowProdutos.VerticalGap := CARD_SPACING;
  FFlowProdutos.Padding.Top := 4;
end;

procedure TFrmVendas.CriarCategoryPills;
begin
  FLayoutCategoryPills := TLayout.Create(Self);
  FLayoutCategoryPills.Parent := FLayoutLeftPanel;
  FLayoutCategoryPills.Align := TAlignLayout.Top;
  FLayoutCategoryPills.Height := PILL_HEIGHT + 16;

  FScrollCategoryPills := THorzScrollBox.Create(Self);
  FScrollCategoryPills.Parent := FLayoutCategoryPills;
  FScrollCategoryPills.Align := TAlignLayout.Client;
  FScrollCategoryPills.ShowScrollBars := False;
end;

procedure TFrmVendas.CriarRightPanel;
var
  LSeparador: TRectangle;
begin
  { Vertical splitter line }
  FRectSplitter := TRectangle.Create(Self);
  FRectSplitter.Parent := FLayoutContent;
  FRectSplitter.Align := TAlignLayout.Right;
  FRectSplitter.Width := 1;
  FRectSplitter.Fill.Kind := TBrushKind.Solid;
  FRectSplitter.Fill.Color := COR_BORDA_LEVE;
  FRectSplitter.Stroke.Kind := TBrushKind.None;
  FRectSplitter.HitTest := False;

  FLayoutRightPanel := TLayout.Create(Self);
  FLayoutRightPanel.Parent := FLayoutContent;
  FLayoutRightPanel.Align := TAlignLayout.Right;
  FLayoutRightPanel.Width := RIGHT_PANEL_WIDTH;

  FRectRightPanel := TRectangle.Create(Self);
  FRectRightPanel.Parent := FLayoutRightPanel;
  FRectRightPanel.Align := TAlignLayout.Client;
  FRectRightPanel.Fill.Kind := TBrushKind.Solid;
  FRectRightPanel.Fill.Color := COR_RIGHT_PANEL;
  FRectRightPanel.Stroke.Kind := TBrushKind.None;
  FRectRightPanel.HitTest := False;

  { Title "Venda atual" }
  FLblVendaTitulo := TLabel.Create(Self);
  FLblVendaTitulo.Parent := FLayoutRightPanel;
  FLblVendaTitulo.Align := TAlignLayout.Top;
  FLblVendaTitulo.Height := 44;
  FLblVendaTitulo.Text := 'Venda atual';
  FLblVendaTitulo.StyledSettings := [];
  FLblVendaTitulo.TextSettings.Font.Size := FONT_TITLE;
  FLblVendaTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblVendaTitulo.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblVendaTitulo.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblVendaTitulo.TextSettings.VertAlign := TTextAlign.Center;
  FLblVendaTitulo.Margins.Left := 16;

  { Footer with totals and button }
  FLayoutCartFooter := TLayout.Create(Self);
  FLayoutCartFooter.Parent := FLayoutRightPanel;
  FLayoutCartFooter.Align := TAlignLayout.Bottom;
  FLayoutCartFooter.Height := 200;
  FLayoutCartFooter.Padding.Left := 16;
  FLayoutCartFooter.Padding.Right := 16;
  FLayoutCartFooter.Padding.Bottom := 12;

  { Finalizar button - at the very bottom }
  FBtnFinalizar := TButton.Create(Self);
  FBtnFinalizar.Parent := FLayoutCartFooter;
  FBtnFinalizar.Align := TAlignLayout.Bottom;
  FBtnFinalizar.Height := 50;
  FBtnFinalizar.Text := 'Finalizar venda  F5';
  FBtnFinalizar.StyledSettings := [];
  FBtnFinalizar.TextSettings.Font.Size := FONT_LARGE;
  FBtnFinalizar.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnFinalizar.TextSettings.FontColor := COR_BRANCO;
  FBtnFinalizar.OnClick := BtnFinalizarClick;
  FBtnFinalizar.Margins.Top := 12;

  { Total }
  FLblTotal := TLabel.Create(Self);
  FLblTotal.Parent := FLayoutCartFooter;
  FLblTotal.Align := TAlignLayout.Bottom;
  FLblTotal.Height := 30;
  FLblTotal.Text := 'Total         R$ 0,00';
  FLblTotal.StyledSettings := [];
  FLblTotal.TextSettings.Font.Size := FONT_TITLE;
  FLblTotal.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblTotal.TextSettings.FontColor := COR_VERDE_TOTAL;
  FLblTotal.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLblTotal.TextSettings.VertAlign := TTextAlign.Center;

  { Desconto display }
  FLblDesconto := TLabel.Create(Self);
  FLblDesconto.Parent := FLayoutCartFooter;
  FLblDesconto.Align := TAlignLayout.Bottom;
  FLblDesconto.Height := 24;
  FLblDesconto.Text := 'Desconto      - R$ 0,00';
  FLblDesconto.StyledSettings := [];
  FLblDesconto.TextSettings.Font.Size := FONT_NORMAL;
  FLblDesconto.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblDesconto.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLblDesconto.TextSettings.VertAlign := TTextAlign.Center;

  { Subtotal }
  FLblSubtotal := TLabel.Create(Self);
  FLblSubtotal.Parent := FLayoutCartFooter;
  FLblSubtotal.Align := TAlignLayout.Bottom;
  FLblSubtotal.Height := 24;
  FLblSubtotal.Text := 'Subtotal       R$ 0,00';
  FLblSubtotal.StyledSettings := [];
  FLblSubtotal.TextSettings.Font.Size := FONT_NORMAL;
  FLblSubtotal.TextSettings.FontColor := COR_TEXTO_CINZA;
  FLblSubtotal.TextSettings.HorzAlign := TTextAlign.Trailing;
  FLblSubtotal.TextSettings.VertAlign := TTextAlign.Center;

  { Separator above totals }
  LSeparador := TRectangle.Create(Self);
  LSeparador.Parent := FLayoutCartFooter;
  LSeparador.Align := TAlignLayout.Bottom;
  LSeparador.Height := 1;
  LSeparador.Fill.Kind := TBrushKind.Solid;
  LSeparador.Fill.Color := COR_BORDA_LEVE;
  LSeparador.Stroke.Kind := TBrushKind.None;
  LSeparador.HitTest := False;
  LSeparador.Margins.Bottom := 8;
  LSeparador.Margins.Top := 8;

  { Discount input row }
  FLblDescontoPercent := TLabel.Create(Self);
  FLblDescontoPercent.Parent := FLayoutCartFooter;
  FLblDescontoPercent.Align := TAlignLayout.Bottom;
  FLblDescontoPercent.Height := 36;
  FLblDescontoPercent.Text := 'Adicionar desconto  %';
  FLblDescontoPercent.StyledSettings := [];
  FLblDescontoPercent.TextSettings.Font.Size := FONT_SMALL;
  FLblDescontoPercent.TextSettings.FontColor := COR_TEXTO_CLARO;
  FLblDescontoPercent.TextSettings.HorzAlign := TTextAlign.Leading;
  FLblDescontoPercent.TextSettings.VertAlign := TTextAlign.Center;

  FEdtDesconto := TEdit.Create(Self);
  FEdtDesconto.Parent := FLayoutCartFooter;
  FEdtDesconto.Align := TAlignLayout.Bottom;
  FEdtDesconto.Height := 32;
  FEdtDesconto.Text := '0,00';
  FEdtDesconto.StyledSettings := [];
  FEdtDesconto.TextSettings.Font.Size := FONT_NORMAL;
  FEdtDesconto.FilterChar := '0123456789,';
  FEdtDesconto.OnChange := EdtDescontoChange;
  FEdtDesconto.Margins.Bottom := 4;

  { Cart items scrollbox }
  FScrollCarrinhoItens := TVertScrollBox.Create(Self);
  FScrollCarrinhoItens.Parent := FLayoutRightPanel;
  FScrollCarrinhoItens.Align := TAlignLayout.Client;
  FScrollCarrinhoItens.ShowScrollBars := True;
  FScrollCarrinhoItens.Padding.Left := 12;
  FScrollCarrinhoItens.Padding.Right := 12;
end;

procedure TFrmVendas.PopularDadosMock;

  function CriarCategoria(AId: Integer; const ANome: string): TCategoria;
  begin
    Result := TCategoria.Create;
    Result.Id := AId;
    Result.Nome := ANome;
    Result.Situacao := 1;
  end;

  function CriarProduto(AId: Integer; const ANome: string;
    ACategoriaId: Integer; APreco: Currency;
    AEstoque: Integer): TProduto;
  begin
    Result := TProduto.Create;
    Result.Id := AId;
    Result.Nome := ANome;
    Result.Categoria_Id := ACategoriaId;
    Result.Preco_Venda := APreco;
    Result.Estoque_Atual := AEstoque;
    Result.Estoque_Minimo := 5;
    Result.Codigo_Barras := Format('789%010d', [AId]);
    Result.Situacao := 1;
  end;

begin
  { 6 categorias }
  FCategorias.Add(CriarCategoria(1, 'Lanches'));
  FCategorias.Add(CriarCategoria(2, 'Bebidas'));
  FCategorias.Add(CriarCategoria(3, 'Ingressos'));
  FCategorias.Add(CriarCategoria(4, 'Brinquedos'));
  FCategorias.Add(CriarCategoria(5, 'Doces'));
  FCategorias.Add(CriarCategoria(6, 'Papelaria'));

  { 12 produtos }
  FProdutos.Add(CriarProduto(1, 'Coca Cola 350ml', 2, 5.00, 50));
  FProdutos.Add(CriarProduto(2, 'Suco Natural', 2, 8.00, 30));
  FProdutos.Add(CriarProduto(3, 'Hot Dog', 1, 12.00, 20));
  FProdutos.Add(CriarProduto(4, 'Pizza Fatia', 1, 10.00, 25));
  FProdutos.Add(CriarProduto(5, 'Ticket 1h', 3, 35.00, 100));
  FProdutos.Add(CriarProduto(6, 'Ticket 2h', 3, 55.00, 100));
  FProdutos.Add(CriarProduto(7, 'Bola Colorida', 4, 15.00, 20));
  FProdutos.Add(CriarProduto(8, 'Boneco Heroi', 4, 25.00, 8));
  FProdutos.Add(CriarProduto(9, 'Pipoca Doce', 5, 8.00, 40));
  FProdutos.Add(CriarProduto(10, 'Algodao Doce', 5, 10.00, 35));
  FProdutos.Add(CriarProduto(11, 'Kit Colorir', 6, 12.00, 15));
  FProdutos.Add(CriarProduto(12, 'Caderno Desenho', 6, 9.90, 18));
end;

function TFrmVendas.GetCorCategoria(AIndex: Integer): TAlphaColor;
begin
  case AIndex of
    0: Result := COR_PILL_LANCHES;
    1: Result := COR_PILL_BEBIDAS;
    2: Result := COR_PILL_INGRESSOS;
    3: Result := COR_PILL_BRINQUEDOS;
    4: Result := COR_PILL_DOCES;
    5: Result := COR_PILL_PAPELARIA;
  else
    Result := COR_AZUL_ATIVO;
  end;
end;

function TFrmVendas.CriarPill(const ATexto: string; ATag: Integer; ACor: TAlphaColor): TRectangle;
var
  LLbl: TLabel;
begin
  Result := TRectangle.Create(Self);
  Result.Width := Length(ATexto) * 9 + 24;
  Result.Height := PILL_HEIGHT;
  Result.XRadius := PILL_HEIGHT / 2;
  Result.YRadius := PILL_HEIGHT / 2;
  Result.Fill.Kind := TBrushKind.Solid;
  Result.Stroke.Kind := TBrushKind.None;
  Result.Tag := ATag;
  Result.HitTest := True;
  Result.Cursor := crHandPoint;
  Result.OnClick := PillClick;
  Result.Margins.Right := PILL_SPACING;
  Result.Margins.Top := 4;

  if ATag = FCategoriaSelecionadaId then
    Result.Fill.Color := ACor
  else
    Result.Fill.Color := COR_FUNDO_CINZA;

  LLbl := TLabel.Create(Self);
  LLbl.Parent := Result;
  LLbl.Align := TAlignLayout.Client;
  LLbl.Text := ATexto;
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := FONT_SMALL;
  LLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLbl.TextSettings.HorzAlign := TTextAlign.Center;
  LLbl.TextSettings.VertAlign := TTextAlign.Center;
  LLbl.HitTest := False;

  if ATag = FCategoriaSelecionadaId then
    LLbl.TextSettings.FontColor := COR_BRANCO
  else
    LLbl.TextSettings.FontColor := COR_TEXTO_CINZA;
end;

procedure TFrmVendas.RenderizarPills;
var
  I: Integer;
  LPill: TRectangle;
  LPosX: Single;
begin
  FPillButtons.Clear;
  FScrollCategoryPills.Content.DeleteChildren;

  LPosX := 0;

  { "Todos" pill }
  LPill := CriarPill('Todos', 0, COR_AZUL_ATIVO);
  LPill.Parent := FScrollCategoryPills;
  LPill.Position.X := LPosX;
  LPill.Position.Y := 4;
  FPillButtons.Add(LPill);
  LPosX := LPosX + LPill.Width + PILL_SPACING;

  { Category pills }
  for I := 0 to FCategorias.Count - 1 do
  begin
    LPill := CriarPill(FCategorias[I].Nome, FCategorias[I].Id, GetCorCategoria(I));
    LPill.Parent := FScrollCategoryPills;
    LPill.Position.X := LPosX;
    LPill.Position.Y := 4;
    FPillButtons.Add(LPill);
    LPosX := LPosX + LPill.Width + PILL_SPACING;
  end;
end;

procedure TFrmVendas.PillClick(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    FCategoriaSelecionadaId := TRectangle(Sender).Tag;
    AtualizarPillAtiva;
    RenderizarProdutos;
  end;
end;

procedure TFrmVendas.AtualizarPillAtiva;
var
  I: Integer;
  LPill: TRectangle;
  LLbl: TLabel;
  J: Integer;
  LCor: TAlphaColor;
begin
  for I := 0 to FPillButtons.Count - 1 do
  begin
    LPill := FPillButtons[I];

    if I = 0 then
      LCor := COR_AZUL_ATIVO
    else
      LCor := GetCorCategoria(I - 1);

    { Find label child }
    LLbl := nil;
    for J := 0 to LPill.ChildrenCount - 1 do
    begin
      if LPill.Children[J] is TLabel then
      begin
        LLbl := TLabel(LPill.Children[J]);
        Break;
      end;
    end;

    if LPill.Tag = FCategoriaSelecionadaId then
    begin
      LPill.Fill.Color := LCor;
      if Assigned(LLbl) then
        LLbl.TextSettings.FontColor := COR_BRANCO;
    end
    else
    begin
      LPill.Fill.Color := COR_FUNDO_CINZA;
      if Assigned(LLbl) then
        LLbl.TextSettings.FontColor := COR_TEXTO_CINZA;
    end;
  end;
end;

procedure TFrmVendas.RenderizarProdutos;
var
  I: Integer;
  LCard: TLayout;
  LContagem: Integer;
  LBuscaTexto: string;
begin
  FFlowProdutos.DeleteChildren;

  LBuscaTexto := LowerCase(Trim(FEdtBusca.Text));
  LContagem := 0;

  for I := 0 to FProdutos.Count - 1 do
  begin
    { Filter by category }
    if (FCategoriaSelecionadaId <> 0) and
       (FProdutos[I].Categoria_Id <> FCategoriaSelecionadaId) then
      Continue;

    { Filter by search text }
    if (LBuscaTexto <> '') and
       (Pos(LBuscaTexto, LowerCase(FProdutos[I].Nome)) = 0) then
      Continue;

    { Only active products }
    if FProdutos[I].Situacao <> 1 then
      Continue;

    LCard := CriarCardProduto(FProdutos[I]);
    LCard.Parent := FFlowProdutos;
    Inc(LContagem);
  end;

  { Adjust flow height for scrolling }
  FFlowProdutos.Height := (Ceil(LContagem / 4) + 1) * (CARD_HEIGHT + CARD_SPACING);
end;

function TFrmVendas.CriarCardProduto(AProduto: TProduto): TLayout;
var
  LRect: TRectangle;
  LLblNome: TLabel;
  LLblPreco: TLabel;
begin
  Result := TLayout.Create(Self);
  Result.Width := CARD_WIDTH;
  Result.Height := CARD_HEIGHT;
  Result.Tag := AProduto.Id;
  Result.HitTest := True;
  Result.Cursor := crHandPoint;
  Result.OnClick := ProdutoCardClick;

  { Card background }
  LRect := TRectangle.Create(Self);
  LRect.Parent := Result;
  LRect.Align := TAlignLayout.Client;
  LRect.Fill.Kind := TBrushKind.Solid;
  LRect.Fill.Color := COR_BRANCO;
  LRect.Stroke.Kind := TBrushKind.Solid;
  LRect.Stroke.Color := COR_BORDA_LEVE;
  LRect.Stroke.Thickness := 1;
  LRect.XRadius := 8;
  LRect.YRadius := 8;
  LRect.HitTest := False;
  LRect.Margins.Left := 2;
  LRect.Margins.Right := 2;
  LRect.Margins.Top := 2;
  LRect.Margins.Bottom := 2;

  { Product name }
  LLblNome := TLabel.Create(Self);
  LLblNome.Parent := Result;
  LLblNome.Align := TAlignLayout.Client;
  LLblNome.Text := AProduto.Nome;
  LLblNome.StyledSettings := [];
  LLblNome.TextSettings.Font.Size := FONT_NORMAL;
  LLblNome.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LLblNome.TextSettings.HorzAlign := TTextAlign.Center;
  LLblNome.TextSettings.VertAlign := TTextAlign.Center;
  LLblNome.TextSettings.WordWrap := True;
  LLblNome.Margins.Left := 8;
  LLblNome.Margins.Right := 8;
  LLblNome.Margins.Top := 16;
  LLblNome.HitTest := False;

  { Price at bottom }
  LLblPreco := TLabel.Create(Self);
  LLblPreco.Parent := Result;
  LLblPreco.Align := TAlignLayout.Bottom;
  LLblPreco.Height := 32;
  LLblPreco.Text := FormatarMoeda(AProduto.Preco_Venda);
  LLblPreco.StyledSettings := [];
  LLblPreco.TextSettings.Font.Size := FONT_LARGE;
  LLblPreco.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLblPreco.TextSettings.FontColor := COR_AZUL_PRECO;
  LLblPreco.TextSettings.HorzAlign := TTextAlign.Center;
  LLblPreco.TextSettings.VertAlign := TTextAlign.Center;
  LLblPreco.HitTest := False;
  LLblPreco.Margins.Bottom := 8;
end;

procedure TFrmVendas.ProdutoCardClick(Sender: TObject);
var
  LProdutoId: Integer;
  LProduto: TProduto;
begin
  if Sender is TLayout then
    LProdutoId := TLayout(Sender).Tag
  else
    Exit;

  LProduto := GetProdutoPorId(LProdutoId);
  if not Assigned(LProduto) then
    Exit;

  try
    FControllerVenda.AdicionarProduto(LProduto, 1);
    AtualizarCarrinho;
  except
    on E: Exception do
      TDialogService.ShowMessage(E.Message);
  end;
end;

procedure TFrmVendas.AtualizarCarrinho;
begin
  RenderizarItensCarrinho;
  AtualizarTotais;
end;

procedure TFrmVendas.RenderizarItensCarrinho;
var
  I: Integer;
  LItem: TVendaItem;
  LProduto: TProduto;
  LLayoutItem: TLayout;
  LRectItem: TRectangle;
  LLblNome: TLabel;
  LLblQtdPreco: TLabel;
  LBtnMais, LBtnMenos, LBtnRemover: TButton;
  LLayoutBtns: TLayout;
begin
  FScrollCarrinhoItens.Content.DeleteChildren;

  for I := 0 to FControllerVenda.Carrinho.Count - 1 do
  begin
    LItem := FControllerVenda.Carrinho[I];
    LProduto := GetProdutoPorId(LItem.Produto_Id);

    LLayoutItem := TLayout.Create(Self);
    LLayoutItem.Parent := FScrollCarrinhoItens;
    LLayoutItem.Align := TAlignLayout.Top;
    LLayoutItem.Height := 68;
    LLayoutItem.Tag := I;
    LLayoutItem.Margins.Top := 4;
    LLayoutItem.Margins.Bottom := 4;

    { Item card background }
    LRectItem := TRectangle.Create(Self);
    LRectItem.Parent := LLayoutItem;
    LRectItem.Align := TAlignLayout.Client;
    LRectItem.Fill.Kind := TBrushKind.Solid;
    LRectItem.Fill.Color := COR_BRANCO;
    LRectItem.Stroke.Kind := TBrushKind.Solid;
    LRectItem.Stroke.Color := COR_BORDA_LEVE;
    LRectItem.Stroke.Thickness := 1;
    LRectItem.XRadius := 6;
    LRectItem.YRadius := 6;
    LRectItem.HitTest := False;

    { Product name }
    LLblNome := TLabel.Create(Self);
    LLblNome.Parent := LLayoutItem;
    LLblNome.Align := TAlignLayout.Top;
    LLblNome.Height := 24;
    if Assigned(LProduto) then
      LLblNome.Text := LProduto.Nome
    else
      LLblNome.Text := 'Produto #' + IntToStr(LItem.Produto_Id);
    LLblNome.StyledSettings := [];
    LLblNome.TextSettings.Font.Size := FONT_NORMAL;
    LLblNome.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblNome.TextSettings.FontColor := COR_TEXTO_ESCURO;
    LLblNome.TextSettings.HorzAlign := TTextAlign.Leading;
    LLblNome.HitTest := False;
    LLblNome.Margins.Left := 10;
    LLblNome.Margins.Top := 8;

    { Qty x Price = Subtotal }
    LLblQtdPreco := TLabel.Create(Self);
    LLblQtdPreco.Parent := LLayoutItem;
    LLblQtdPreco.Align := TAlignLayout.Top;
    LLblQtdPreco.Height := 20;
    LLblQtdPreco.Text := Format('%d x %s   %s',
      [LItem.Quantidade,
       FormatarMoeda(LItem.Preco_Unitario),
       FormatarMoeda(LItem.Subtotal)]);
    LLblQtdPreco.StyledSettings := [];
    LLblQtdPreco.TextSettings.Font.Size := FONT_SMALL;
    LLblQtdPreco.TextSettings.FontColor := COR_TEXTO_CINZA;
    LLblQtdPreco.TextSettings.HorzAlign := TTextAlign.Leading;
    LLblQtdPreco.HitTest := False;
    LLblQtdPreco.Margins.Left := 10;

    { Buttons layout }
    LLayoutBtns := TLayout.Create(Self);
    LLayoutBtns.Parent := LLayoutItem;
    LLayoutBtns.Align := TAlignLayout.Right;
    LLayoutBtns.Width := 100;

    { Remove button (X) }
    LBtnRemover := TButton.Create(Self);
    LBtnRemover.Parent := LLayoutBtns;
    LBtnRemover.Align := TAlignLayout.Right;
    LBtnRemover.Width := 30;
    LBtnRemover.Text := #$00D7; // multiplication sign
    LBtnRemover.Tag := I;
    LBtnRemover.StyledSettings := [];
    LBtnRemover.TextSettings.Font.Size := 14;
    LBtnRemover.TextSettings.FontColor := COR_BTN_CANCELAR;
    LBtnRemover.OnClick := BtnRemoverClick;
    LBtnRemover.Margins.Left := 2;
    LBtnRemover.Margins.Top := 8;
    LBtnRemover.Margins.Bottom := 8;

    { Plus button (+) }
    LBtnMais := TButton.Create(Self);
    LBtnMais.Parent := LLayoutBtns;
    LBtnMais.Align := TAlignLayout.Right;
    LBtnMais.Width := 30;
    LBtnMais.Text := '+';
    LBtnMais.Tag := I;
    LBtnMais.StyledSettings := [];
    LBtnMais.TextSettings.Font.Size := 16;
    LBtnMais.OnClick := BtnMaisClick;
    LBtnMais.Margins.Left := 2;
    LBtnMais.Margins.Top := 8;
    LBtnMais.Margins.Bottom := 8;

    { Minus button (-) }
    LBtnMenos := TButton.Create(Self);
    LBtnMenos.Parent := LLayoutBtns;
    LBtnMenos.Align := TAlignLayout.Right;
    LBtnMenos.Width := 30;
    LBtnMenos.Text := '-';
    LBtnMenos.Tag := I;
    LBtnMenos.StyledSettings := [];
    LBtnMenos.TextSettings.Font.Size := 16;
    LBtnMenos.OnClick := BtnMenosClick;
    LBtnMenos.Margins.Top := 8;
    LBtnMenos.Margins.Bottom := 8;
  end;
end;

procedure TFrmVendas.AtualizarTotais;
var
  LSubtotal, LDesconto, LTotal: Currency;
begin
  LSubtotal := FControllerVenda.CalcularSubtotal;
  LDesconto := FControllerVenda.Desconto;
  LTotal := FControllerVenda.CalcularTotal;

  FLblSubtotal.Text := 'Subtotal       ' + FormatarMoeda(LSubtotal);
  FLblDesconto.Text := 'Desconto      - ' + FormatarMoeda(LDesconto);
  FLblTotal.Text := 'Total         ' + FormatarMoeda(LTotal);
end;

procedure TFrmVendas.BtnMaisClick(Sender: TObject);
var
  LIndex: Integer;
  LItem: TVendaItem;
  LProduto: TProduto;
begin
  if not (Sender is TButton) then Exit;
  LIndex := TButton(Sender).Tag;
  if (LIndex < 0) or (LIndex >= FControllerVenda.Carrinho.Count) then Exit;

  LItem := FControllerVenda.Carrinho[LIndex];
  LProduto := GetProdutoPorId(LItem.Produto_Id);

  if Assigned(LProduto) then
  begin
    try
      FControllerVenda.AlterarQuantidade(LIndex, LItem.Quantidade + 1);
      AtualizarCarrinho;
    except
      on E: Exception do
        TDialogService.ShowMessage(E.Message);
    end;
  end;
end;

procedure TFrmVendas.BtnMenosClick(Sender: TObject);
var
  LIndex: Integer;
  LItem: TVendaItem;
begin
  if not (Sender is TButton) then Exit;
  LIndex := TButton(Sender).Tag;
  if (LIndex < 0) or (LIndex >= FControllerVenda.Carrinho.Count) then Exit;

  LItem := FControllerVenda.Carrinho[LIndex];

  if LItem.Quantidade <= 1 then
    FControllerVenda.RemoverItem(LIndex)
  else
  begin
    try
      FControllerVenda.AlterarQuantidade(LIndex, LItem.Quantidade - 1);
    except
      on E: Exception do
        TDialogService.ShowMessage(E.Message);
    end;
  end;

  AtualizarCarrinho;
end;

procedure TFrmVendas.BtnRemoverClick(Sender: TObject);
var
  LIndex: Integer;
begin
  if not (Sender is TButton) then Exit;
  LIndex := TButton(Sender).Tag;
  if (LIndex < 0) or (LIndex >= FControllerVenda.Carrinho.Count) then Exit;

  FControllerVenda.RemoverItem(LIndex);
  AtualizarCarrinho;
end;

procedure TFrmVendas.EdtDescontoChange(Sender: TObject);
var
  LValor: Currency;
  LTexto: string;
begin
  LTexto := StringReplace(FEdtDesconto.Text, ',', '.', [rfReplaceAll]);
  LTexto := Trim(LTexto);

  if LTexto = '' then
    LValor := 0
  else
  begin
    try
      LValor := StrToCurr(LTexto);
    except
      LValor := 0;
    end;
  end;

  try
    FControllerVenda.AplicarDesconto(LValor);
  except
    FControllerVenda.AplicarDesconto(0);
  end;

  AtualizarTotais;
end;

procedure TFrmVendas.EdtBuscaChange(Sender: TObject);
begin
  RenderizarProdutos;
end;

procedure TFrmVendas.BtnFinalizarClick(Sender: TObject);
begin
  if FControllerVenda.Carrinho.Count = 0 then
  begin
    TDialogService.ShowMessage('Carrinho vazio. Adicione produtos antes de finalizar.');
    Exit;
  end;
  ExibirDialogPagamento;
end;

procedure TFrmVendas.BtnCancelarClick(Sender: TObject);
begin
  if FControllerVenda.Carrinho.Count = 0 then
    Exit;

  TDialogService.MessageDialog(
    'Cancelar a venda atual? Todos os itens serao removidos.',
    TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        FControllerVenda.CancelarVenda;
        FEdtDesconto.Text := '0,00';
        AtualizarCarrinho;
      end;
    end
  );
end;

procedure TFrmVendas.BtnSalvarClick(Sender: TObject);
begin
  TDialogService.ShowMessage('Venda salva em rascunho.');
end;

procedure TFrmVendas.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkF2:
      begin
        FEdtBusca.SetFocus;
        Key := 0;
      end;
    vkF3:
      begin
        BtnSalvarClick(nil);
        Key := 0;
      end;
    vkF5:
      begin
        BtnFinalizarClick(nil);
        Key := 0;
      end;
    vkEscape:
      begin
        BtnCancelarClick(nil);
        Key := 0;
      end;
  end;
end;

procedure TFrmVendas.ExibirDialogPagamento;
var
  LForm: TForm;
  LLayout: TLayout;
  LLblTitulo, LLblTotal, LLblMetodo, LLblParcelas, LLblCPF: TLabel;
  LCmbMetodo: TComboBox;
  LCmbParcelas: TComboBox;
  LEdtCPF: TEdit;
  LBtnConfirmar, LBtnVoltar: TButton;
  I: Integer;
begin
  LForm := TForm.CreateNew(Self);
  try
    LForm.Caption := 'Finalizar Pagamento';
    LForm.ClientWidth := 420;
    LForm.ClientHeight := 420;
    LForm.Position := TFormPosition.ScreenCenter;
    LForm.BorderStyle := TFmxFormBorderStyle.Single;
    LForm.Fill.Kind := TBrushKind.Solid;
    LForm.Fill.Color := COR_BRANCO;

    LLayout := TLayout.Create(LForm);
    LLayout.Parent := LForm;
    LLayout.Align := TAlignLayout.Client;
    LLayout.Padding.Left := 24;
    LLayout.Padding.Right := 24;
    LLayout.Padding.Top := 20;
    LLayout.Padding.Bottom := 20;

    { Title }
    LLblTitulo := TLabel.Create(LForm);
    LLblTitulo.Parent := LLayout;
    LLblTitulo.Align := TAlignLayout.Top;
    LLblTitulo.Height := 36;
    LLblTitulo.Text := 'Finalizar Pagamento';
    LLblTitulo.StyledSettings := [];
    LLblTitulo.TextSettings.Font.Size := 20;
    LLblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblTitulo.TextSettings.FontColor := COR_TEXTO_ESCURO;
    LLblTitulo.TextSettings.HorzAlign := TTextAlign.Center;

    { Total display }
    LLblTotal := TLabel.Create(LForm);
    LLblTotal.Parent := LLayout;
    LLblTotal.Align := TAlignLayout.Top;
    LLblTotal.Height := 34;
    LLblTotal.Text := 'Total: ' + FormatarMoeda(FControllerVenda.CalcularTotal);
    LLblTotal.StyledSettings := [];
    LLblTotal.TextSettings.Font.Size := FONT_TITLE;
    LLblTotal.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblTotal.TextSettings.FontColor := COR_VERDE_TOTAL;
    LLblTotal.TextSettings.HorzAlign := TTextAlign.Center;
    LLblTotal.Margins.Bottom := 16;

    { Payment method label }
    LLblMetodo := TLabel.Create(LForm);
    LLblMetodo.Parent := LLayout;
    LLblMetodo.Align := TAlignLayout.Top;
    LLblMetodo.Height := 22;
    LLblMetodo.Text := 'Forma de Pagamento:';
    LLblMetodo.StyledSettings := [];
    LLblMetodo.TextSettings.Font.Size := FONT_NORMAL;
    LLblMetodo.TextSettings.FontColor := COR_TEXTO_CINZA;
    LLblMetodo.Margins.Top := 8;

    { Payment method combo }
    LCmbMetodo := TComboBox.Create(LForm);
    LCmbMetodo.Parent := LLayout;
    LCmbMetodo.Align := TAlignLayout.Top;
    LCmbMetodo.Height := BTN_MIN_HEIGHT;
    LCmbMetodo.Items.Add('DINHEIRO');
    LCmbMetodo.Items.Add('DEBITO');
    LCmbMetodo.Items.Add('CREDITO');
    LCmbMetodo.Items.Add('PIX');
    LCmbMetodo.Items.Add('COMANDA');
    LCmbMetodo.ItemIndex := 0;
    LCmbMetodo.Margins.Bottom := 8;

    { Parcelas label }
    LLblParcelas := TLabel.Create(LForm);
    LLblParcelas.Parent := LLayout;
    LLblParcelas.Align := TAlignLayout.Top;
    LLblParcelas.Height := 22;
    LLblParcelas.Text := 'Parcelas (somente credito):';
    LLblParcelas.StyledSettings := [];
    LLblParcelas.TextSettings.Font.Size := FONT_NORMAL;
    LLblParcelas.TextSettings.FontColor := COR_TEXTO_CINZA;

    { Parcelas combo }
    LCmbParcelas := TComboBox.Create(LForm);
    LCmbParcelas.Parent := LLayout;
    LCmbParcelas.Align := TAlignLayout.Top;
    LCmbParcelas.Height := BTN_MIN_HEIGHT;
    for I := 1 to 12 do
      LCmbParcelas.Items.Add(IntToStr(I) + 'x');
    LCmbParcelas.ItemIndex := 0;
    LCmbParcelas.Margins.Bottom := 8;

    { CPF label }
    LLblCPF := TLabel.Create(LForm);
    LLblCPF.Parent := LLayout;
    LLblCPF.Align := TAlignLayout.Top;
    LLblCPF.Height := 22;
    LLblCPF.Text := 'CPF na nota (opcional):';
    LLblCPF.StyledSettings := [];
    LLblCPF.TextSettings.Font.Size := FONT_NORMAL;
    LLblCPF.TextSettings.FontColor := COR_TEXTO_CINZA;

    { CPF edit }
    LEdtCPF := TEdit.Create(LForm);
    LEdtCPF.Parent := LLayout;
    LEdtCPF.Align := TAlignLayout.Top;
    LEdtCPF.Height := BTN_MIN_HEIGHT;
    LEdtCPF.TextPrompt := '000.000.000-00';
    LEdtCPF.FilterChar := '0123456789.-';
    LEdtCPF.StyledSettings := [];
    LEdtCPF.TextSettings.Font.Size := FONT_NORMAL;
    LEdtCPF.Margins.Bottom := 16;

    { Confirm button }
    LBtnConfirmar := TButton.Create(LForm);
    LBtnConfirmar.Parent := LLayout;
    LBtnConfirmar.Align := TAlignLayout.Bottom;
    LBtnConfirmar.Height := 50;
    LBtnConfirmar.Text := 'Confirmar Pagamento';
    LBtnConfirmar.StyledSettings := [];
    LBtnConfirmar.TextSettings.Font.Size := FONT_LARGE;
    LBtnConfirmar.TextSettings.Font.Style := [TFontStyle.fsBold];
    LBtnConfirmar.TextSettings.FontColor := COR_BRANCO;
    LBtnConfirmar.ModalResult := mrOk;

    { Back button }
    LBtnVoltar := TButton.Create(LForm);
    LBtnVoltar.Parent := LLayout;
    LBtnVoltar.Align := TAlignLayout.Bottom;
    LBtnVoltar.Height := 44;
    LBtnVoltar.Text := 'Voltar';
    LBtnVoltar.StyledSettings := [];
    LBtnVoltar.TextSettings.Font.Size := FONT_NORMAL;
    LBtnVoltar.TextSettings.FontColor := COR_TEXTO_CINZA;
    LBtnVoltar.ModalResult := mrCancel;
    LBtnVoltar.Margins.Bottom := 4;

    if LForm.ShowModal = mrOk then
    begin
      try
        FControllerVenda.FinalizarVenda(
          LCmbMetodo.Items[LCmbMetodo.ItemIndex],
          LCmbParcelas.ItemIndex + 1,
          Trim(LEdtCPF.Text),
          1, { CaixaId - mock }
          FColaboradorId
        );
        FEdtDesconto.Text := '0,00';
        AtualizarCarrinho;
        TDialogService.ShowMessage('Venda finalizada com sucesso!');
      except
        on E: Exception do
          TDialogService.ShowMessage('Erro ao finalizar: ' + E.Message);
      end;
    end;
  finally
    LForm.Free;
  end;
end;

function TFrmVendas.FormatarMoeda(AValor: Currency): string;
begin
  Result := Format('R$ %s', [FormatCurr('#,##0.00', AValor)]);
end;

function TFrmVendas.GetProdutoPorId(AId: Integer): TProduto;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FProdutos.Count - 1 do
  begin
    if FProdutos[I].Id = AId then
    begin
      Result := FProdutos[I];
      Exit;
    end;
  end;
end;

end.
