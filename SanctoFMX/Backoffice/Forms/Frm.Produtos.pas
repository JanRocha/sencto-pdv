unit Frm.Produtos;

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
  Model.Entidade.Produto,
  Controller.Produto;

type
  /// <summary>
  /// Tela CRUD de Produtos no Backoffice.
  /// Exibe grid/lista de produtos com busca, filtros e ações de
  /// criar, editar, desativar/reativar. Inclui importação/exportação Excel (placeholder).
  /// Criada programaticamente (sem .fmx) para ser embarcada no Main do Backoffice.
  /// Touch-friendly: elementos >= 48px, spacing >= 8px, font 14pt/18pt.
  /// </summary>
  TFrmProdutos = class(TFrame)
  private
    { Controller }
    FControllerProduto: TControllerProduto;

    { Mock data }
    FProdutos: TObjectList<TProduto>;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Toolbar — busca e ações }
    FLayoutToolbar: TLayout;
    FRectToolbar: TRectangle;
    FEdtBusca: TEdit;
    FBtnNovoProduto: TButton;
    FBtnImportar: TButton;
    FBtnExportar: TButton;

    { Grid de produtos }
    FScrollGrid: TVertScrollBox;
    FLayoutGridHeader: TLayout;

    { Painel de formulário (overlay direito) }
    FLayoutFormPanel: TLayout;
    FRectFormPanel: TRectangle;
    FScrollForm: TVertScrollBox;
    FLblFormTitulo: TLabel;
    FEdtNome: TEdit;
    FEdtCodigoBarras: TEdit;
    FEdtCategoria: TEdit;
    FEdtPrecoVenda: TEdit;
    FEdtPrecoPromocional: TEdit;
    FEdtEstoqueAtual: TEdit;
    FEdtEstoqueMinimo: TEdit;
    FEdtUnidade: TEdit;
    FCmbTipo: TComboBox;
    FEdtNCM: TEdit;
    FEdtCFOP: TEdit;
    FEdtCSTCSOSN: TEdit;
    FEdtAliqICMS: TEdit;
    FEdtAliqPIS: TEdit;
    FEdtAliqCOFINS: TEdit;
    FSwitchSituacao: TSwitch;
    FLblSituacao: TLabel;
    FEdtFornecedor: TEdit;
    FEdtDescricao: TEdit;
    FEdtObservacoes: TEdit;
    FBtnSalvar: TButton;
    FBtnCancelarForm: TButton;

    { Estado do formulário }
    FEditandoId: Integer; // 0 = novo, > 0 = editando

    procedure CriarComponentes;
    procedure CriarToolbar;
    procedure CriarGridHeader;
    procedure CriarGridContent;
    procedure CriarFormPanel;

    { Mock data }
    procedure PopularDadosMock;

    { Grid }
    procedure RenderizarGrid;
    function CriarLinhaGrid(AProduto: TProduto; AIndex: Integer): TLayout;

    { Toolbar actions }
    procedure BtnNovoProdutoClick(Sender: TObject);
    procedure BtnImportarClick(Sender: TObject);
    procedure BtnExportarClick(Sender: TObject);
    procedure EdtBuscaChange(Sender: TObject);

    { Row actions }
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnDesativarClick(Sender: TObject);

    { Form panel }
    procedure MostrarFormPanel(AProduto: TProduto);
    procedure OcultarFormPanel;
    procedure PreencherForm(AProduto: TProduto);
    procedure LimparForm;
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarFormClick(Sender: TObject);

    { Helpers }
    function FormatarMoeda(AValor: Currency): string;
    function GetProdutoPorId(AId: Integer): TProduto;
    function ProdutoPassaFiltro(AProduto: TProduto; const AFiltro: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

const
  COR_FUNDO = $FFF5F5F5;
  COR_TOOLBAR = $FFFFFFFF;
  COR_HEADER = $FFE3F2FD;
  COR_LINHA_PAR = $FFFFFFFF;
  COR_LINHA_IMPAR = $FFFAFAFA;
  COR_BTN_NOVO = $FF4CAF50;
  COR_BTN_IMPORTAR = $FF1E88E5;
  COR_BTN_EXPORTAR = $FF7B1FA2;
  COR_BTN_EDITAR = $FF1565C0;
  COR_BTN_DESATIVAR = $FFFF5722;
  COR_BTN_REATIVAR = $FF4CAF50;
  COR_FORM_BG = $FFFFFFFF;
  COR_BADGE_ALERTA = $FFE53935;
  COR_ATIVO = $FF4CAF50;
  COR_INATIVO = $FF9E9E9E;
  COR_SEPARADOR = $FFE0E0E0;

  TOOLBAR_HEIGHT = 60;
  HEADER_HEIGHT = 36;
  ROW_HEIGHT = 48;
  FORM_PANEL_WIDTH = 420;
  FIELD_HEIGHT = 36;
  LABEL_HEIGHT = 20;
  BTN_HEIGHT = 48;
  FONT_INFO = 14;
  FONT_BTN = 16;
  SPACING = 8;

{ TFrmProdutos }

constructor TFrmProdutos.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FControllerProduto := TControllerProduto.Create;
  FProdutos := TObjectList<TProduto>.Create(True);
  FEditandoId := 0;

  Align := TAlignLayout.Client;

  CriarComponentes;
  PopularDadosMock;
  RenderizarGrid;
end;

destructor TFrmProdutos.Destroy;
begin
  FProdutos.Free;
  FControllerProduto.Free;
  inherited Destroy;
end;

procedure TFrmProdutos.CriarComponentes;
begin
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;

  CriarToolbar;
  CriarFormPanel;
  CriarGridHeader;
  CriarGridContent;
end;

procedure TFrmProdutos.CriarToolbar;
begin
  FLayoutToolbar := TLayout.Create(Self);
  FLayoutToolbar.Parent := FLayoutPrincipal;
  FLayoutToolbar.Align := TAlignLayout.Top;
  FLayoutToolbar.Height := TOOLBAR_HEIGHT;
  FLayoutToolbar.Padding.Left := SPACING;
  FLayoutToolbar.Padding.Right := SPACING;

  FRectToolbar := TRectangle.Create(Self);
  FRectToolbar.Parent := FLayoutToolbar;
  FRectToolbar.Align := TAlignLayout.Client;
  FRectToolbar.Fill.Kind := TBrushKind.Solid;
  FRectToolbar.Fill.Color := COR_TOOLBAR;
  FRectToolbar.Stroke.Kind := TBrushKind.None;
  FRectToolbar.HitTest := False;

  // Campo de busca
  FEdtBusca := TEdit.Create(Self);
  FEdtBusca.Parent := FLayoutToolbar;
  FEdtBusca.Align := TAlignLayout.Left;
  FEdtBusca.Width := 300;
  FEdtBusca.Height := 40;
  FEdtBusca.TextPrompt := 'Buscar produto (nome, codigo, categoria)...';
  FEdtBusca.StyledSettings := [];
  FEdtBusca.TextSettings.Font.Size := FONT_INFO;
  FEdtBusca.Margins.Top := 10;
  FEdtBusca.Margins.Bottom := 10;
  FEdtBusca.Margins.Right := SPACING;
  FEdtBusca.OnChange := EdtBuscaChange;

  // Botao + Novo Produto
  FBtnNovoProduto := TButton.Create(Self);
  FBtnNovoProduto.Parent := FLayoutToolbar;
  FBtnNovoProduto.Align := TAlignLayout.Left;
  FBtnNovoProduto.Width := 140;
  FBtnNovoProduto.Height := BTN_HEIGHT;
  FBtnNovoProduto.Text := '+ Novo Produto';
  FBtnNovoProduto.StyledSettings := [];
  FBtnNovoProduto.TextSettings.Font.Size := FONT_BTN;
  FBtnNovoProduto.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnNovoProduto.TextSettings.FontColor := $FFFFFFFF;
  FBtnNovoProduto.OnClick := BtnNovoProdutoClick;
  FBtnNovoProduto.Margins.Top := 6;
  FBtnNovoProduto.Margins.Right := SPACING;

  // Botao Exportar Excel
  FBtnExportar := TButton.Create(Self);
  FBtnExportar.Parent := FLayoutToolbar;
  FBtnExportar.Align := TAlignLayout.Right;
  FBtnExportar.Width := 130;
  FBtnExportar.Height := BTN_HEIGHT;
  FBtnExportar.Text := 'Exportar Excel';
  FBtnExportar.StyledSettings := [];
  FBtnExportar.TextSettings.Font.Size := FONT_INFO;
  FBtnExportar.TextSettings.FontColor := $FFFFFFFF;
  FBtnExportar.OnClick := BtnExportarClick;
  FBtnExportar.Margins.Top := 6;
  FBtnExportar.Margins.Left := SPACING;

  // Botao Importar Excel
  FBtnImportar := TButton.Create(Self);
  FBtnImportar.Parent := FLayoutToolbar;
  FBtnImportar.Align := TAlignLayout.Right;
  FBtnImportar.Width := 130;
  FBtnImportar.Height := BTN_HEIGHT;
  FBtnImportar.Text := 'Importar Excel';
  FBtnImportar.StyledSettings := [];
  FBtnImportar.TextSettings.Font.Size := FONT_INFO;
  FBtnImportar.TextSettings.FontColor := $FFFFFFFF;
  FBtnImportar.OnClick := BtnImportarClick;
  FBtnImportar.Margins.Top := 6;
  FBtnImportar.Margins.Left := SPACING;
end;

procedure TFrmProdutos.CriarGridHeader;
var
  LColunas: array[0..6] of record Nome: string; Largura: Single; end;
  I: Integer;
  LLbl: TLabel;
  LPosX: Single;
  LRectHeader: TRectangle;
begin
  LColunas[0].Nome := 'Nome'; LColunas[0].Largura := 200;
  LColunas[1].Nome := 'Cod. Barras'; LColunas[1].Largura := 130;
  LColunas[2].Nome := 'Categoria'; LColunas[2].Largura := 100;
  LColunas[3].Nome := 'Preco'; LColunas[3].Largura := 90;
  LColunas[4].Nome := 'Estoque'; LColunas[4].Largura := 70;
  LColunas[5].Nome := 'Status'; LColunas[5].Largura := 70;
  LColunas[6].Nome := 'Acoes'; LColunas[6].Largura := 180;

  FLayoutGridHeader := TLayout.Create(Self);
  FLayoutGridHeader.Parent := FLayoutPrincipal;
  FLayoutGridHeader.Align := TAlignLayout.Top;
  FLayoutGridHeader.Height := HEADER_HEIGHT;
  FLayoutGridHeader.Margins.Left := SPACING;
  FLayoutGridHeader.Margins.Right := SPACING;

  // Fundo header
  LRectHeader := TRectangle.Create(Self);
  LRectHeader.Parent := FLayoutGridHeader;
  LRectHeader.Align := TAlignLayout.Client;
  LRectHeader.Fill.Kind := TBrushKind.Solid;
  LRectHeader.Fill.Color := COR_HEADER;
  LRectHeader.Stroke.Kind := TBrushKind.None;
  LRectHeader.XRadius := 4;
  LRectHeader.YRadius := 4;
  LRectHeader.HitTest := False;

  LPosX := SPACING;
  for I := 0 to 6 do
  begin
    LLbl := TLabel.Create(Self);
    LLbl.Parent := FLayoutGridHeader;
    LLbl.Position.X := LPosX;
    LLbl.Position.Y := 0;
    LLbl.Width := LColunas[I].Largura;
    LLbl.Height := HEADER_HEIGHT;
    LLbl.Text := LColunas[I].Nome;
    LLbl.StyledSettings := [];
    LLbl.TextSettings.Font.Size := 12;
    LLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLbl.TextSettings.FontColor := $FF1565C0;
    LLbl.TextSettings.VertAlign := TTextAlign.Center;
    LLbl.HitTest := False;
    LPosX := LPosX + LColunas[I].Largura;
  end;
end;

procedure TFrmProdutos.CriarGridContent;
begin
  FScrollGrid := TVertScrollBox.Create(Self);
  FScrollGrid.Parent := FLayoutPrincipal;
  FScrollGrid.Align := TAlignLayout.Client;
  FScrollGrid.ShowScrollBars := True;
  FScrollGrid.Margins.Left := SPACING;
  FScrollGrid.Margins.Right := SPACING;
  FScrollGrid.Margins.Top := 4;
end;

procedure TFrmProdutos.CriarFormPanel;

  function CriarLabel(AParent: TFmxObject; const AText: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Align := TAlignLayout.Top;
    Result.Height := LABEL_HEIGHT;
    Result.Text := AText;
    Result.StyledSettings := [];
    Result.TextSettings.Font.Size := 12;
    Result.TextSettings.FontColor := $FF616161;
    Result.Margins.Top := 6;
  end;

  function CriarEdit(AParent: TFmxObject; const APrompt: string): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := AParent;
    Result.Align := TAlignLayout.Top;
    Result.Height := FIELD_HEIGHT;
    Result.TextPrompt := APrompt;
    Result.StyledSettings := [];
    Result.TextSettings.Font.Size := FONT_INFO;
    Result.Margins.Bottom := 2;
  end;

var
  LLayoutBotoes: TLayout;
  LLayoutSituacao: TLayout;
begin
  FLayoutFormPanel := TLayout.Create(Self);
  FLayoutFormPanel.Parent := FLayoutPrincipal;
  FLayoutFormPanel.Align := TAlignLayout.Right;
  FLayoutFormPanel.Width := FORM_PANEL_WIDTH;
  FLayoutFormPanel.Visible := False;

  FRectFormPanel := TRectangle.Create(Self);
  FRectFormPanel.Parent := FLayoutFormPanel;
  FRectFormPanel.Align := TAlignLayout.Client;
  FRectFormPanel.Fill.Kind := TBrushKind.Solid;
  FRectFormPanel.Fill.Color := COR_FORM_BG;
  FRectFormPanel.Stroke.Color := COR_SEPARADOR;
  FRectFormPanel.Stroke.Thickness := 1;
  FRectFormPanel.HitTest := False;

  // Titulo do formulario
  FLblFormTitulo := TLabel.Create(Self);
  FLblFormTitulo.Parent := FLayoutFormPanel;
  FLblFormTitulo.Align := TAlignLayout.Top;
  FLblFormTitulo.Height := 44;
  FLblFormTitulo.Text := 'Novo Produto';
  FLblFormTitulo.StyledSettings := [];
  FLblFormTitulo.TextSettings.Font.Size := 18;
  FLblFormTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFormTitulo.TextSettings.FontColor := $FF212121;
  FLblFormTitulo.TextSettings.HorzAlign := TTextAlign.Center;
  FLblFormTitulo.TextSettings.VertAlign := TTextAlign.Center;
  FLblFormTitulo.Margins.Top := 8;

  // Botoes no rodape
  LLayoutBotoes := TLayout.Create(Self);
  LLayoutBotoes.Parent := FLayoutFormPanel;
  LLayoutBotoes.Align := TAlignLayout.Bottom;
  LLayoutBotoes.Height := BTN_HEIGHT + 16;
  LLayoutBotoes.Padding.Left := SPACING;
  LLayoutBotoes.Padding.Right := SPACING;
  LLayoutBotoes.Padding.Bottom := SPACING;

  FBtnCancelarForm := TButton.Create(Self);
  FBtnCancelarForm.Parent := LLayoutBotoes;
  FBtnCancelarForm.Align := TAlignLayout.Left;
  FBtnCancelarForm.Width := 100;
  FBtnCancelarForm.Height := BTN_HEIGHT;
  FBtnCancelarForm.Text := 'Cancelar';
  FBtnCancelarForm.StyledSettings := [];
  FBtnCancelarForm.TextSettings.Font.Size := FONT_BTN;
  FBtnCancelarForm.OnClick := BtnCancelarFormClick;

  FBtnSalvar := TButton.Create(Self);
  FBtnSalvar.Parent := LLayoutBotoes;
  FBtnSalvar.Align := TAlignLayout.Client;
  FBtnSalvar.Height := BTN_HEIGHT;
  FBtnSalvar.Text := 'Salvar';
  FBtnSalvar.StyledSettings := [];
  FBtnSalvar.TextSettings.Font.Size := FONT_BTN;
  FBtnSalvar.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnSalvar.TextSettings.FontColor := $FFFFFFFF;
  FBtnSalvar.OnClick := BtnSalvarClick;
  FBtnSalvar.Margins.Left := SPACING;

  // Scroll para campos do formulario
  FScrollForm := TVertScrollBox.Create(Self);
  FScrollForm.Parent := FLayoutFormPanel;
  FScrollForm.Align := TAlignLayout.Client;
  FScrollForm.ShowScrollBars := True;
  FScrollForm.Padding.Left := 12;
  FScrollForm.Padding.Right := 12;
  FScrollForm.Padding.Top := 4;

  // Campos do formulario
  CriarLabel(FScrollForm, 'Nome *');
  FEdtNome := CriarEdit(FScrollForm, 'Nome do produto');

  CriarLabel(FScrollForm, 'Codigo de Barras *');
  FEdtCodigoBarras := CriarEdit(FScrollForm, 'EAN-8, EAN-13 ou interno');

  CriarLabel(FScrollForm, 'Categoria');
  FEdtCategoria := CriarEdit(FScrollForm, 'Categoria do produto');

  CriarLabel(FScrollForm, 'Preco Venda *');
  FEdtPrecoVenda := CriarEdit(FScrollForm, '0,00');
  FEdtPrecoVenda.FilterChar := '0123456789,';

  CriarLabel(FScrollForm, 'Preco Promocional');
  FEdtPrecoPromocional := CriarEdit(FScrollForm, '0,00');
  FEdtPrecoPromocional.FilterChar := '0123456789,';

  CriarLabel(FScrollForm, 'Estoque Atual');
  FEdtEstoqueAtual := CriarEdit(FScrollForm, '0');
  FEdtEstoqueAtual.FilterChar := '0123456789';

  CriarLabel(FScrollForm, 'Estoque Minimo');
  FEdtEstoqueMinimo := CriarEdit(FScrollForm, '0');
  FEdtEstoqueMinimo.FilterChar := '0123456789';

  CriarLabel(FScrollForm, 'Unidade');
  FEdtUnidade := CriarEdit(FScrollForm, 'UN, KG, LT...');

  CriarLabel(FScrollForm, 'Tipo');
  FCmbTipo := TComboBox.Create(Self);
  FCmbTipo.Parent := FScrollForm;
  FCmbTipo.Align := TAlignLayout.Top;
  FCmbTipo.Height := FIELD_HEIGHT;
  FCmbTipo.Items.Add('PRODUTO');
  FCmbTipo.Items.Add('SERVICO');
  FCmbTipo.Items.Add('INGRESSO');
  FCmbTipo.ItemIndex := 0;
  FCmbTipo.Margins.Bottom := 2;

  CriarLabel(FScrollForm, 'NCM (8 digitos) *');
  FEdtNCM := CriarEdit(FScrollForm, '00000000');
  FEdtNCM.FilterChar := '0123456789';
  FEdtNCM.MaxLength := 8;

  CriarLabel(FScrollForm, 'CFOP (4 digitos) *');
  FEdtCFOP := CriarEdit(FScrollForm, '0000');
  FEdtCFOP.FilterChar := '0123456789';
  FEdtCFOP.MaxLength := 4;

  CriarLabel(FScrollForm, 'CST/CSOSN');
  FEdtCSTCSOSN := CriarEdit(FScrollForm, 'CST ou CSOSN');

  CriarLabel(FScrollForm, 'Aliquota ICMS (%)');
  FEdtAliqICMS := CriarEdit(FScrollForm, '0,00');
  FEdtAliqICMS.FilterChar := '0123456789,';

  CriarLabel(FScrollForm, 'Aliquota PIS (%)');
  FEdtAliqPIS := CriarEdit(FScrollForm, '0,00');
  FEdtAliqPIS.FilterChar := '0123456789,';

  CriarLabel(FScrollForm, 'Aliquota COFINS (%)');
  FEdtAliqCOFINS := CriarEdit(FScrollForm, '0,00');
  FEdtAliqCOFINS.FilterChar := '0123456789,';

  // Situacao toggle
  LLayoutSituacao := TLayout.Create(Self);
  LLayoutSituacao.Parent := FScrollForm;
  LLayoutSituacao.Align := TAlignLayout.Top;
  LLayoutSituacao.Height := 40;
  LLayoutSituacao.Margins.Top := 8;

  FLblSituacao := TLabel.Create(Self);
  FLblSituacao.Parent := LLayoutSituacao;
  FLblSituacao.Align := TAlignLayout.Left;
  FLblSituacao.Width := 80;
  FLblSituacao.Text := 'Ativo';
  FLblSituacao.StyledSettings := [];
  FLblSituacao.TextSettings.Font.Size := FONT_INFO;
  FLblSituacao.TextSettings.FontColor := $FF212121;
  FLblSituacao.TextSettings.VertAlign := TTextAlign.Center;

  FSwitchSituacao := TSwitch.Create(Self);
  FSwitchSituacao.Parent := LLayoutSituacao;
  FSwitchSituacao.Align := TAlignLayout.Left;
  FSwitchSituacao.Width := 60;
  FSwitchSituacao.IsChecked := True;

  CriarLabel(FScrollForm, 'Fornecedor');
  FEdtFornecedor := CriarEdit(FScrollForm, 'Nome do fornecedor');

  CriarLabel(FScrollForm, 'Descricao');
  FEdtDescricao := CriarEdit(FScrollForm, 'Descricao do produto');

  CriarLabel(FScrollForm, 'Observacoes internas');
  FEdtObservacoes := CriarEdit(FScrollForm, 'Observacoes internas');
end;

procedure TFrmProdutos.PopularDadosMock;

  function CriarProduto(AId: Integer; const ANome, ACodigoBarras, ACategoria: string;
    APreco: Currency; AEstoque, AEstoqueMin: Integer;
    const ATipo: string; ASituacao: Integer): TProduto;
  begin
    Result := TProduto.Create;
    Result.Id := AId;
    Result.Nome := ANome;
    Result.Codigo_Barras := ACodigoBarras;
    Result.Categoria_Id := 1;
    Result.Preco_Venda := APreco;
    Result.Preco_Promocional := 0;
    Result.Estoque_Atual := AEstoque;
    Result.Estoque_Minimo := AEstoqueMin;
    Result.Unidade := 'UN';
    Result.Tipo := ATipo;
    Result.NCM := '22021000';
    Result.CFOP := '5102';
    Result.CST_CSOSN := '102';
    Result.Aliquota_ICMS := 18.00;
    Result.Aliquota_PIS := 1.65;
    Result.Aliquota_COFINS := 7.60;
    Result.Situacao := ASituacao;
  end;

begin

  FProdutos.Add(CriarProduto(1, 'Agua Mineral 500ml', '7891000100103', 'Bebidas',
    3.50, 50, 10, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(2, 'Refrigerante Lata 350ml', '7891000200206', 'Bebidas',
    6.00, 30, 10, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(3, 'Suco Natural Laranja', '7891000300309', 'Bebidas',
    8.00, 15, 5, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(4, 'Hot Dog Completo', '7891000400402', 'Lanches',
    12.00, 20, 5, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(5, 'Pizza Fatia Mussarela', '7891000500505', 'Lanches',
    10.00, 25, 8, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(6, 'Ticket 1 hora', 'INT0001', 'Ingressos',
    35.00, 100, 10, 'INGRESSO', 1));
  FProdutos.Add(CriarProduto(7, 'Ticket 2 horas', 'INT0002', 'Ingressos',
    55.00, 100, 10, 'INGRESSO', 1));
  FProdutos.Add(CriarProduto(8, 'Pipoca Doce Grande', '7891000800808', 'Doces',
    8.00, 40, 10, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(9, 'Algodao Doce', '7891000900901', 'Doces',
    10.00, 3, 5, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(10, 'Bola Colorida', '7891001000100', 'Brinquedos',
    15.00, 20, 5, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(11, 'Kit Colorir Infantil', '7891001100203', 'Papelaria',
    12.00, 2, 5, 'PRODUTO', 1));
  FProdutos.Add(CriarProduto(12, 'Servico Pintura Facial', 'SRV0001', 'Servicos',
    20.00, 0, 0, 'SERVICO', 0));
end;

procedure TFrmProdutos.RenderizarGrid;
var
  I: Integer;
  LLinha: TLayout;
  LFiltro: string;
begin
  // Limpar conteudo anterior
  FScrollGrid.Content.DeleteChildren;

  LFiltro := Trim(LowerCase(FEdtBusca.Text));

  for I := 0 to FProdutos.Count - 1 do
  begin
    if (LFiltro <> '') and (not ProdutoPassaFiltro(FProdutos[I], LFiltro)) then
      Continue;

    LLinha := CriarLinhaGrid(FProdutos[I], I);
    LLinha.Parent := FScrollGrid;
  end;
end;

function TFrmProdutos.CriarLinhaGrid(AProduto: TProduto; AIndex: Integer): TLayout;
var
  LRect: TRectangle;
  LLblNome, LLblCodBarras, LLblCategoria, LLblPreco: TLabel;
  LLblEstoque, LLblStatus: TLabel;
  LBtnEditar, LBtnDesativar: TButton;
  LPosX: Single;
  LAlertaEstoque: Boolean;
begin
  Result := TLayout.Create(Self);
  Result.Align := TAlignLayout.Top;
  Result.Height := ROW_HEIGHT;
  Result.Tag := AProduto.Id;

  // Fundo alternado
  LRect := TRectangle.Create(Self);
  LRect.Parent := Result;
  LRect.Align := TAlignLayout.Client;
  LRect.Fill.Kind := TBrushKind.Solid;
  if (AIndex mod 2) = 0 then
    LRect.Fill.Color := COR_LINHA_PAR
  else
    LRect.Fill.Color := COR_LINHA_IMPAR;
  LRect.Stroke.Kind := TBrushKind.None;
  LRect.HitTest := False;

  LPosX := SPACING;
  LAlertaEstoque := (AProduto.Estoque_Atual <= AProduto.Estoque_Minimo)
    and (AProduto.Estoque_Minimo > 0);

  // Nome
  LLblNome := TLabel.Create(Self);
  LLblNome.Parent := Result;
  LLblNome.Position.X := LPosX;
  LLblNome.Position.Y := 0;
  LLblNome.Width := 200;
  LLblNome.Height := ROW_HEIGHT;
  LLblNome.Text := AProduto.Nome;
  LLblNome.StyledSettings := [];
  LLblNome.TextSettings.Font.Size := FONT_INFO;
  LLblNome.TextSettings.FontColor := $FF212121;
  LLblNome.TextSettings.VertAlign := TTextAlign.Center;
  LLblNome.TextSettings.Trimming := TTextTrimming.Character;
  LLblNome.HitTest := False;
  LPosX := LPosX + 200;

  // Codigo Barras
  LLblCodBarras := TLabel.Create(Self);
  LLblCodBarras.Parent := Result;
  LLblCodBarras.Position.X := LPosX;
  LLblCodBarras.Position.Y := 0;
  LLblCodBarras.Width := 130;
  LLblCodBarras.Height := ROW_HEIGHT;
  LLblCodBarras.Text := AProduto.Codigo_Barras;
  LLblCodBarras.StyledSettings := [];
  LLblCodBarras.TextSettings.Font.Size := 12;
  LLblCodBarras.TextSettings.FontColor := $FF616161;
  LLblCodBarras.TextSettings.VertAlign := TTextAlign.Center;
  LLblCodBarras.HitTest := False;
  LPosX := LPosX + 130;

  // Categoria (texto baseado no Tipo do mock)
  LLblCategoria := TLabel.Create(Self);
  LLblCategoria.Parent := Result;
  LLblCategoria.Position.X := LPosX;
  LLblCategoria.Position.Y := 0;
  LLblCategoria.Width := 100;
  LLblCategoria.Height := ROW_HEIGHT;
  LLblCategoria.Text := AProduto.Tipo;
  LLblCategoria.StyledSettings := [];
  LLblCategoria.TextSettings.Font.Size := 12;
  LLblCategoria.TextSettings.FontColor := $FF616161;
  LLblCategoria.TextSettings.VertAlign := TTextAlign.Center;
  LLblCategoria.HitTest := False;
  LPosX := LPosX + 100;

  // Preco
  LLblPreco := TLabel.Create(Self);
  LLblPreco.Parent := Result;
  LLblPreco.Position.X := LPosX;
  LLblPreco.Position.Y := 0;
  LLblPreco.Width := 90;
  LLblPreco.Height := ROW_HEIGHT;
  LLblPreco.Text := FormatarMoeda(AProduto.Preco_Venda);
  LLblPreco.StyledSettings := [];
  LLblPreco.TextSettings.Font.Size := FONT_INFO;
  LLblPreco.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLblPreco.TextSettings.FontColor := $FF1565C0;
  LLblPreco.TextSettings.VertAlign := TTextAlign.Center;
  LLblPreco.HitTest := False;
  LPosX := LPosX + 90;

  // Estoque (com indicador de alerta)
  LLblEstoque := TLabel.Create(Self);
  LLblEstoque.Parent := Result;
  LLblEstoque.Position.X := LPosX;
  LLblEstoque.Position.Y := 0;
  LLblEstoque.Width := 70;
  LLblEstoque.Height := ROW_HEIGHT;
  if LAlertaEstoque then
    LLblEstoque.Text := IntToStr(AProduto.Estoque_Atual) + ' (!)'
  else
    LLblEstoque.Text := IntToStr(AProduto.Estoque_Atual);
  LLblEstoque.StyledSettings := [];
  LLblEstoque.TextSettings.Font.Size := FONT_INFO;
  if LAlertaEstoque then
    LLblEstoque.TextSettings.FontColor := COR_BADGE_ALERTA
  else
    LLblEstoque.TextSettings.FontColor := $FF212121;
  LLblEstoque.TextSettings.VertAlign := TTextAlign.Center;
  LLblEstoque.HitTest := False;
  LPosX := LPosX + 70;

  // Status
  LLblStatus := TLabel.Create(Self);
  LLblStatus.Parent := Result;
  LLblStatus.Position.X := LPosX;
  LLblStatus.Position.Y := 0;
  LLblStatus.Width := 70;
  LLblStatus.Height := ROW_HEIGHT;
  if AProduto.Situacao = 1 then
  begin
    LLblStatus.Text := 'Ativo';
    LLblStatus.TextSettings.FontColor := COR_ATIVO;
  end
  else
  begin
    LLblStatus.Text := 'Inativo';
    LLblStatus.TextSettings.FontColor := COR_INATIVO;
  end;
  LLblStatus.StyledSettings := [];
  LLblStatus.TextSettings.Font.Size := 12;
  LLblStatus.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLblStatus.TextSettings.VertAlign := TTextAlign.Center;
  LLblStatus.HitTest := False;
  LPosX := LPosX + 70;

  // Botao Editar
  LBtnEditar := TButton.Create(Self);
  LBtnEditar.Parent := Result;
  LBtnEditar.Position.X := LPosX;
  LBtnEditar.Position.Y := (ROW_HEIGHT - 32) / 2;
  LBtnEditar.Width := 70;
  LBtnEditar.Height := 32;
  LBtnEditar.Text := 'Editar';
  LBtnEditar.Tag := AProduto.Id;
  LBtnEditar.StyledSettings := [];
  LBtnEditar.TextSettings.Font.Size := 12;
  LBtnEditar.TextSettings.FontColor := $FFFFFFFF;
  LBtnEditar.OnClick := BtnEditarClick;
  LPosX := LPosX + 74;

  // Botao Desativar/Reativar
  LBtnDesativar := TButton.Create(Self);
  LBtnDesativar.Parent := Result;
  LBtnDesativar.Position.X := LPosX;
  LBtnDesativar.Position.Y := (ROW_HEIGHT - 32) / 2;
  LBtnDesativar.Width := 90;
  LBtnDesativar.Height := 32;
  LBtnDesativar.Tag := AProduto.Id;
  LBtnDesativar.StyledSettings := [];
  LBtnDesativar.TextSettings.Font.Size := 12;
  LBtnDesativar.TextSettings.FontColor := $FFFFFFFF;
  LBtnDesativar.OnClick := BtnDesativarClick;
  if AProduto.Situacao = 1 then
    LBtnDesativar.Text := 'Desativar'
  else
    LBtnDesativar.Text := 'Reativar';
end;

procedure TFrmProdutos.BtnNovoProdutoClick(Sender: TObject);
begin
  FEditandoId := 0;
  LimparForm;
  FLblFormTitulo.Text := 'Novo Produto';
  MostrarFormPanel(nil);
end;

procedure TFrmProdutos.BtnImportarClick(Sender: TObject);
begin
  TDialogService.ShowMessage(
    'Funcionalidade de importacao Excel sera implementada na proxima fase.');
end;

procedure TFrmProdutos.BtnExportarClick(Sender: TObject);
begin
  TDialogService.ShowMessage(
    'Funcionalidade de exportacao Excel sera implementada na proxima fase.');
end;

procedure TFrmProdutos.EdtBuscaChange(Sender: TObject);
begin
  RenderizarGrid;
end;

procedure TFrmProdutos.BtnEditarClick(Sender: TObject);
var
  LProduto: TProduto;
begin
  if not (Sender is TButton) then Exit;
  LProduto := GetProdutoPorId(TButton(Sender).Tag);
  if not Assigned(LProduto) then Exit;

  FEditandoId := LProduto.Id;
  FLblFormTitulo.Text := 'Editar Produto';
  PreencherForm(LProduto);
  MostrarFormPanel(LProduto);
end;

procedure TFrmProdutos.BtnDesativarClick(Sender: TObject);
var
  LProduto: TProduto;
begin
  if not (Sender is TButton) then Exit;
  LProduto := GetProdutoPorId(TButton(Sender).Tag);
  if not Assigned(LProduto) then Exit;

  if LProduto.Situacao = 1 then
  begin
    LProduto.Situacao := 0;
    TDialogService.ShowMessage('Produto "' + LProduto.Nome + '" desativado.');
  end
  else
  begin
    LProduto.Situacao := 1;
    TDialogService.ShowMessage('Produto "' + LProduto.Nome + '" reativado.');
  end;

  RenderizarGrid;
end;

procedure TFrmProdutos.MostrarFormPanel(AProduto: TProduto);
begin
  FLayoutFormPanel.Visible := True;
end;

procedure TFrmProdutos.OcultarFormPanel;
begin
  FLayoutFormPanel.Visible := False;
end;

procedure TFrmProdutos.PreencherForm(AProduto: TProduto);
begin
  if not Assigned(AProduto) then Exit;

  FEdtNome.Text := AProduto.Nome;
  FEdtCodigoBarras.Text := AProduto.Codigo_Barras;
  FEdtCategoria.Text := AProduto.Tipo; // Placeholder — usar Categoria real futuramente
  FEdtPrecoVenda.Text := StringReplace(Format('%.2f', [Double(AProduto.Preco_Venda)]), '.', ',', []);
  FEdtPrecoPromocional.Text := StringReplace(Format('%.2f', [Double(AProduto.Preco_Promocional)]), '.', ',', []);
  FEdtEstoqueAtual.Text := IntToStr(AProduto.Estoque_Atual);
  FEdtEstoqueMinimo.Text := IntToStr(AProduto.Estoque_Minimo);
  FEdtUnidade.Text := AProduto.Unidade;

  // Tipo combo
  if AProduto.Tipo = 'SERVICO' then
    FCmbTipo.ItemIndex := 1
  else if AProduto.Tipo = 'INGRESSO' then
    FCmbTipo.ItemIndex := 2
  else
    FCmbTipo.ItemIndex := 0;

  FEdtNCM.Text := AProduto.NCM;
  FEdtCFOP.Text := AProduto.CFOP;
  FEdtCSTCSOSN.Text := AProduto.CST_CSOSN;
  FEdtAliqICMS.Text := StringReplace(Format('%.2f', [Double(AProduto.Aliquota_ICMS)]), '.', ',', []);
  FEdtAliqPIS.Text := StringReplace(Format('%.2f', [Double(AProduto.Aliquota_PIS)]), '.', ',', []);
  FEdtAliqCOFINS.Text := StringReplace(Format('%.2f', [Double(AProduto.Aliquota_COFINS)]), '.', ',', []);
  FSwitchSituacao.IsChecked := (AProduto.Situacao = 1);
  FEdtFornecedor.Text := '';
  FEdtDescricao.Text := '';
  FEdtObservacoes.Text := '';
end;

procedure TFrmProdutos.LimparForm;
begin
  FEdtNome.Text := '';
  FEdtCodigoBarras.Text := '';
  FEdtCategoria.Text := '';
  FEdtPrecoVenda.Text := '';
  FEdtPrecoPromocional.Text := '';
  FEdtEstoqueAtual.Text := '0';
  FEdtEstoqueMinimo.Text := '0';
  FEdtUnidade.Text := 'UN';
  FCmbTipo.ItemIndex := 0;
  FEdtNCM.Text := '';
  FEdtCFOP.Text := '';
  FEdtCSTCSOSN.Text := '';
  FEdtAliqICMS.Text := '0,00';
  FEdtAliqPIS.Text := '0,00';
  FEdtAliqCOFINS.Text := '0,00';
  FSwitchSituacao.IsChecked := True;
  FEdtFornecedor.Text := '';
  FEdtDescricao.Text := '';
  FEdtObservacoes.Text := '';
end;

procedure TFrmProdutos.BtnSalvarClick(Sender: TObject);
var
  LProduto: TProduto;
  LPrecoStr: string;
begin
  // Validacao basica na tela
  if Trim(FEdtNome.Text) = '' then
  begin
    TDialogService.ShowMessage('Nome e obrigatorio.');
    Exit;
  end;
  if Trim(FEdtCodigoBarras.Text) = '' then
  begin
    TDialogService.ShowMessage('Codigo de barras e obrigatorio.');
    Exit;
  end;
  if Trim(FEdtNCM.Text) = '' then
  begin
    TDialogService.ShowMessage('NCM e obrigatorio.');
    Exit;
  end;
  if Length(Trim(FEdtNCM.Text)) <> 8 then
  begin
    TDialogService.ShowMessage('NCM deve conter 8 digitos.');
    Exit;
  end;
  if Trim(FEdtCFOP.Text) = '' then
  begin
    TDialogService.ShowMessage('CFOP e obrigatorio.');
    Exit;
  end;
  if Length(Trim(FEdtCFOP.Text)) <> 4 then
  begin
    TDialogService.ShowMessage('CFOP deve conter 4 digitos.');
    Exit;
  end;

  // Obter ou criar produto
  if FEditandoId > 0 then
    LProduto := GetProdutoPorId(FEditandoId)
  else
  begin
    LProduto := TProduto.Create;
    LProduto.Id := FProdutos.Count + 1;
    FProdutos.Add(LProduto);
  end;

  if not Assigned(LProduto) then Exit;

  // Preencher entidade
  LProduto.Nome := Trim(FEdtNome.Text);
  LProduto.Codigo_Barras := Trim(FEdtCodigoBarras.Text);
  LProduto.Categoria_Id := 1; // Mock: categoria fixa

  LPrecoStr := StringReplace(Trim(FEdtPrecoVenda.Text), ',', '.', [rfReplaceAll]);
  if LPrecoStr <> '' then
    LProduto.Preco_Venda := StrToCurrDef(LPrecoStr, 0)
  else
    LProduto.Preco_Venda := 0;

  LPrecoStr := StringReplace(Trim(FEdtPrecoPromocional.Text), ',', '.', [rfReplaceAll]);
  if LPrecoStr <> '' then
    LProduto.Preco_Promocional := StrToCurrDef(LPrecoStr, 0)
  else
    LProduto.Preco_Promocional := 0;

  LProduto.Estoque_Atual := StrToIntDef(Trim(FEdtEstoqueAtual.Text), 0);
  LProduto.Estoque_Minimo := StrToIntDef(Trim(FEdtEstoqueMinimo.Text), 0);
  LProduto.Unidade := Trim(FEdtUnidade.Text);

  if FCmbTipo.ItemIndex = 1 then
    LProduto.Tipo := 'SERVICO'
  else if FCmbTipo.ItemIndex = 2 then
    LProduto.Tipo := 'INGRESSO'
  else
    LProduto.Tipo := 'PRODUTO';

  LProduto.NCM := Trim(FEdtNCM.Text);
  LProduto.CFOP := Trim(FEdtCFOP.Text);
  LProduto.CST_CSOSN := Trim(FEdtCSTCSOSN.Text);

  LPrecoStr := StringReplace(Trim(FEdtAliqICMS.Text), ',', '.', [rfReplaceAll]);
  LProduto.Aliquota_ICMS := StrToCurrDef(LPrecoStr, 0);

  LPrecoStr := StringReplace(Trim(FEdtAliqPIS.Text), ',', '.', [rfReplaceAll]);
  LProduto.Aliquota_PIS := StrToCurrDef(LPrecoStr, 0);

  LPrecoStr := StringReplace(Trim(FEdtAliqCOFINS.Text), ',', '.', [rfReplaceAll]);
  LProduto.Aliquota_COFINS := StrToCurrDef(LPrecoStr, 0);

  if FSwitchSituacao.IsChecked then
    LProduto.Situacao := 1
  else
    LProduto.Situacao := 0;

  // Fechar painel e atualizar grid
  OcultarFormPanel;
  RenderizarGrid;

  if FEditandoId > 0 then
    TDialogService.ShowMessage('Produto atualizado com sucesso!')
  else
    TDialogService.ShowMessage('Produto cadastrado com sucesso!');

  FEditandoId := 0;
end;

procedure TFrmProdutos.BtnCancelarFormClick(Sender: TObject);
begin
  OcultarFormPanel;
  FEditandoId := 0;
end;

function TFrmProdutos.FormatarMoeda(AValor: Currency): string;
begin
  Result := Format('R$ %.2f', [AValor]);
  Result := StringReplace(Result, '.', ',', [rfReplaceAll]);
end;

function TFrmProdutos.GetProdutoPorId(AId: Integer): TProduto;
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

function TFrmProdutos.ProdutoPassaFiltro(AProduto: TProduto; const AFiltro: string): Boolean;
var
  LNome, LCodBarras, LTipo: string;
begin
  LNome := LowerCase(AProduto.Nome);
  LCodBarras := LowerCase(AProduto.Codigo_Barras);
  LTipo := LowerCase(AProduto.Tipo);

  Result := (Pos(AFiltro, LNome) > 0) or
            (Pos(AFiltro, LCodBarras) > 0) or
            (Pos(AFiltro, LTipo) > 0);
end;

end.
