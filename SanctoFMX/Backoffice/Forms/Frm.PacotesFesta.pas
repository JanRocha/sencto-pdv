unit Frm.PacotesFesta;

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
  FMX.ScrollBox,
  FMX.Memo,
  Controller.Festa,
  Model.Entidade.PacoteFesta,
  Mock.DAO;

type
  /// <summary>
  /// Tela de gestão de Pacotes de Festa no Backoffice.
  /// CRUD simples: listar, criar, editar e desativar pacotes.
  /// Validações: Nome ≤80, MaxConvidados 1-200, Preços 0.01-99999.99,
  /// Descrição ≤500. Usa Controller.Festa.DAOPacote para persistência Mock.
  /// </summary>
  TFrmPacotesFesta = class(TForm)
  private
    FController: TControllerFesta;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Header }
    FLayoutHeader: TLayout;
    FLblTitulo: TLabel;
    FBtnNovoPacote: TButton;

    { Lista de pacotes }
    FScrollLista: TVertScrollBox;
    FLayoutLista: TLayout;

    { Overlay do formulário }
    FLayoutOverlay: TLayout;
    FRectOverlayBg: TRectangle;
    FLayoutFormPanel: TLayout;
    FRectFormBg: TRectangle;
    FLblFormTitle: TLabel;
    FEdtNome: TEdit;
    FEdtMaxConvidados: TEdit;
    FEdtPrecoSemana: TEdit;
    FEdtPrecoFDS: TEdit;
    FMemoDescricao: TMemo;
    FSwitchAtivo: TSwitch;
    FLblAtivo: TLabel;
    FBtnSalvar: TButton;
    FBtnCancelarForm: TButton;
    FLblErro: TLabel;

    { Estado de edição }
    FEditandoId: Integer;

    { Inicialização }
    procedure CriarMockData;
    procedure CriarComponentes;
    procedure CriarHeader;
    procedure CriarLista;
    procedure CriarFormulario;

    { Eventos }
    procedure BtnNovoPacoteClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarFormClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnDesativarClick(Sender: TObject);

    { Lógica }
    procedure AtualizarLista;
    procedure MostrarFormulario(APacoteId: Integer = 0);
    procedure OcultarFormulario;
    function ValidarFormulario: Boolean;

    { Touch feedback }
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

const
  COR_BRANCO = $FFFFFFFF;
  COR_CINZA_CLARO = $FFF5F5F5;
  COR_CINZA_MEDIO = $FFE0E0E0;
  COR_CINZA_ESCURO = $FF616161;
  COR_AZUL_PRIMARIO = $FF1565C0;
  COR_VERDE = $FF4CAF50;
  COR_VERMELHO = $FFF44336;
  COR_TEXTO_ESCURO = $FF212121;
  COR_OVERLAY = $AA000000;

  BTN_MIN_SIZE = 48;
  ROW_HEIGHT = 52;

{ TFrmPacotesFesta }

constructor TFrmPacotesFesta.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);

  Caption := 'Backoffice - Pacotes de Festa';
  ClientWidth := 900;
  ClientHeight := 600;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := COR_CINZA_CLARO;

  FController := TControllerFesta.Create;
  FEditandoId := 0;

  CriarMockData;
  CriarComponentes;
  AtualizarLista;
end;

destructor TFrmPacotesFesta.Destroy;
begin
  FController.Free;
  inherited Destroy;
end;

procedure TFrmPacotesFesta.CriarMockData;
var
  LPacote: TPacoteFesta;
begin
  // Pacote 1: Aventura
  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Aventura';
  LPacote.Max_Convidados := 20;
  LPacote.Preco_Semana := 1500.00;
  LPacote.Preco_FDS := 2200.00;
  LPacote.Descricao := 'Inclui decoração temática, lanche e 2h de diversão';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);

  // Pacote 2: Fantasia
  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Fantasia';
  LPacote.Max_Convidados := 35;
  LPacote.Preco_Semana := 2500.00;
  LPacote.Preco_FDS := 3500.00;
  LPacote.Descricao := 'Pacote completo com buffet, DJ e personagens';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);

  // Pacote 3: Mini
  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Mini';
  LPacote.Max_Convidados := 10;
  LPacote.Preco_Semana := 800.00;
  LPacote.Preco_FDS := 1200.00;
  LPacote.Descricao := 'Festinha íntima com bolo e salgados';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);
end;

procedure TFrmPacotesFesta.CriarComponentes;
begin
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;
  FLayoutPrincipal.Padding.Left := 16;
  FLayoutPrincipal.Padding.Right := 16;
  FLayoutPrincipal.Padding.Top := 16;
  FLayoutPrincipal.Padding.Bottom := 16;

  CriarHeader;
  CriarLista;
  CriarFormulario;
end;

procedure TFrmPacotesFesta.CriarHeader;
begin
  FLayoutHeader := TLayout.Create(Self);
  FLayoutHeader.Parent := FLayoutPrincipal;
  FLayoutHeader.Align := TAlignLayout.Top;
  FLayoutHeader.Height := 56;
  FLayoutHeader.Margins.Bottom := 12;

  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := FLayoutHeader;
  FLblTitulo.Align := TAlignLayout.Left;
  FLblTitulo.Width := 300;
  FLblTitulo.Text := 'Pacotes de Festa';
  FLblTitulo.StyledSettings := [];
  FLblTitulo.TextSettings.Font.Size := 20;
  FLblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblTitulo.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblTitulo.TextSettings.VertAlign := TTextAlign.Center;

  FBtnNovoPacote := TButton.Create(Self);
  FBtnNovoPacote.Parent := FLayoutHeader;
  FBtnNovoPacote.Align := TAlignLayout.Right;
  FBtnNovoPacote.Width := 150;
  FBtnNovoPacote.Height := BTN_MIN_SIZE;
  FBtnNovoPacote.Text := '+ Novo Pacote';
  FBtnNovoPacote.StyledSettings := [];
  FBtnNovoPacote.TextSettings.Font.Size := 14;
  FBtnNovoPacote.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnNovoPacote.OnClick := BtnNovoPacoteClick;
  FBtnNovoPacote.OnMouseDown := BtnMouseDown;
  FBtnNovoPacote.OnMouseUp := BtnMouseUp;
end;

procedure TFrmPacotesFesta.CriarLista;
begin
  FScrollLista := TVertScrollBox.Create(Self);
  FScrollLista.Parent := FLayoutPrincipal;
  FScrollLista.Align := TAlignLayout.Client;

  FLayoutLista := TLayout.Create(Self);
  FLayoutLista.Parent := FScrollLista;
  FLayoutLista.Align := TAlignLayout.Top;
  FLayoutLista.Height := 600;
end;

procedure TFrmPacotesFesta.CriarFormulario;

  function CriarCampoEdit(AParent: TFmxObject; ATop: Single;
    const APrompt: string; AWidth: Single = 350): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := AParent;
    Result.Position.X := 16;
    Result.Position.Y := ATop;
    Result.Width := AWidth;
    Result.Height := 36;
    Result.StyledSettings := [];
    Result.TextSettings.Font.Size := 14;
    Result.TextPrompt := APrompt;
  end;

begin
  // Overlay escuro
  FLayoutOverlay := TLayout.Create(Self);
  FLayoutOverlay.Parent := Self;
  FLayoutOverlay.Align := TAlignLayout.Client;
  FLayoutOverlay.Visible := False;

  FRectOverlayBg := TRectangle.Create(Self);
  FRectOverlayBg.Parent := FLayoutOverlay;
  FRectOverlayBg.Align := TAlignLayout.Client;
  FRectOverlayBg.Fill.Kind := TBrushKind.Solid;
  FRectOverlayBg.Fill.Color := COR_OVERLAY;
  FRectOverlayBg.Stroke.Kind := TBrushKind.None;
  FRectOverlayBg.HitTest := True;

  // Painel central do formulário
  FLayoutFormPanel := TLayout.Create(Self);
  FLayoutFormPanel.Parent := FLayoutOverlay;
  FLayoutFormPanel.Align := TAlignLayout.Center;
  FLayoutFormPanel.Width := 420;
  FLayoutFormPanel.Height := 480;

  FRectFormBg := TRectangle.Create(Self);
  FRectFormBg.Parent := FLayoutFormPanel;
  FRectFormBg.Align := TAlignLayout.Client;
  FRectFormBg.Fill.Kind := TBrushKind.Solid;
  FRectFormBg.Fill.Color := COR_BRANCO;
  FRectFormBg.Stroke.Color := COR_CINZA_MEDIO;
  FRectFormBg.XRadius := 12;
  FRectFormBg.YRadius := 12;
  FRectFormBg.HitTest := False;

  // Título
  FLblFormTitle := TLabel.Create(Self);
  FLblFormTitle.Parent := FLayoutFormPanel;
  FLblFormTitle.Position.X := 16;
  FLblFormTitle.Position.Y := 12;
  FLblFormTitle.Width := 380;
  FLblFormTitle.Height := 30;
  FLblFormTitle.Text := 'Novo Pacote';
  FLblFormTitle.StyledSettings := [];
  FLblFormTitle.TextSettings.Font.Size := 18;
  FLblFormTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFormTitle.TextSettings.FontColor := COR_AZUL_PRIMARIO;

  // Campos
  FEdtNome := CriarCampoEdit(FLayoutFormPanel, 50, 'Nome do pacote (máx 80 chars)');
  FEdtMaxConvidados := CriarCampoEdit(FLayoutFormPanel, 94, 'Máx. convidados (1-200)', 170);
  FEdtPrecoSemana := CriarCampoEdit(FLayoutFormPanel, 138, 'Preço semana (R$)', 170);
  FEdtPrecoFDS := CriarCampoEdit(FLayoutFormPanel, 182, 'Preço FDS (R$)', 170);

  // Preço FDS ao lado do Preço Semana
  FEdtPrecoFDS.Position.X := 196;
  FEdtPrecoFDS.Position.Y := 138;

  // Descrição (Memo)
  FMemoDescricao := TMemo.Create(Self);
  FMemoDescricao.Parent := FLayoutFormPanel;
  FMemoDescricao.Position.X := 16;
  FMemoDescricao.Position.Y := 226;
  FMemoDescricao.Width := 350;
  FMemoDescricao.Height := 80;
  FMemoDescricao.StyledSettings := [];
  FMemoDescricao.TextSettings.Font.Size := 13;

  // Switch Ativo
  FLblAtivo := TLabel.Create(Self);
  FLblAtivo.Parent := FLayoutFormPanel;
  FLblAtivo.Position.X := 16;
  FLblAtivo.Position.Y := 318;
  FLblAtivo.Width := 60;
  FLblAtivo.Height := 30;
  FLblAtivo.Text := 'Ativo:';
  FLblAtivo.StyledSettings := [];
  FLblAtivo.TextSettings.Font.Size := 14;
  FLblAtivo.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblAtivo.TextSettings.VertAlign := TTextAlign.Center;

  FSwitchAtivo := TSwitch.Create(Self);
  FSwitchAtivo.Parent := FLayoutFormPanel;
  FSwitchAtivo.Position.X := 80;
  FSwitchAtivo.Position.Y := 320;
  FSwitchAtivo.IsChecked := True;

  // Label de erro
  FLblErro := TLabel.Create(Self);
  FLblErro.Parent := FLayoutFormPanel;
  FLblErro.Position.X := 16;
  FLblErro.Position.Y := 355;
  FLblErro.Width := 380;
  FLblErro.Height := 24;
  FLblErro.Text := '';
  FLblErro.StyledSettings := [];
  FLblErro.TextSettings.Font.Size := 12;
  FLblErro.TextSettings.FontColor := COR_VERMELHO;
  FLblErro.Visible := False;

  // Botões
  FBtnSalvar := TButton.Create(Self);
  FBtnSalvar.Parent := FLayoutFormPanel;
  FBtnSalvar.Position.X := 16;
  FBtnSalvar.Position.Y := 390;
  FBtnSalvar.Width := 170;
  FBtnSalvar.Height := BTN_MIN_SIZE;
  FBtnSalvar.Text := 'Salvar';
  FBtnSalvar.StyledSettings := [];
  FBtnSalvar.TextSettings.Font.Size := 14;
  FBtnSalvar.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnSalvar.OnClick := BtnSalvarClick;
  FBtnSalvar.OnMouseDown := BtnMouseDown;
  FBtnSalvar.OnMouseUp := BtnMouseUp;

  FBtnCancelarForm := TButton.Create(Self);
  FBtnCancelarForm.Parent := FLayoutFormPanel;
  FBtnCancelarForm.Position.X := 196;
  FBtnCancelarForm.Position.Y := 390;
  FBtnCancelarForm.Width := 170;
  FBtnCancelarForm.Height := BTN_MIN_SIZE;
  FBtnCancelarForm.Text := 'Cancelar';
  FBtnCancelarForm.StyledSettings := [];
  FBtnCancelarForm.TextSettings.Font.Size := 14;
  FBtnCancelarForm.OnClick := BtnCancelarFormClick;
  FBtnCancelarForm.OnMouseDown := BtnMouseDown;
  FBtnCancelarForm.OnMouseUp := BtnMouseUp;
end;

{ ===== Eventos ===== }

procedure TFrmPacotesFesta.BtnNovoPacoteClick(Sender: TObject);
begin
  MostrarFormulario(0);
end;

procedure TFrmPacotesFesta.BtnSalvarClick(Sender: TObject);
var
  LPacote: TPacoteFesta;
  LMaxConv: Integer;
  LPrecoSemana, LPrecoFDS: Currency;
begin
  if not ValidarFormulario then
    Exit;

  LMaxConv := StrToInt(Trim(FEdtMaxConvidados.Text));
  LPrecoSemana := StrToCurr(StringReplace(Trim(FEdtPrecoSemana.Text), ',', '.', []));
  LPrecoFDS := StrToCurr(StringReplace(Trim(FEdtPrecoFDS.Text), ',', '.', []));

  if FEditandoId > 0 then
  begin
    // Editar existente
    LPacote := FController.DAOPacote.Find(FEditandoId);
    if Assigned(LPacote) then
    begin
      LPacote.Nome := Trim(FEdtNome.Text);
      LPacote.Max_Convidados := LMaxConv;
      LPacote.Preco_Semana := LPrecoSemana;
      LPacote.Preco_FDS := LPrecoFDS;
      LPacote.Descricao := Trim(FMemoDescricao.Text);
      if FSwitchAtivo.IsChecked then
        LPacote.Situacao := 1
      else
        LPacote.Situacao := 0;
      FController.DAOPacote.Update(LPacote);
      LPacote.Free;
    end;
  end
  else
  begin
    // Novo pacote
    LPacote := TPacoteFesta.Create;
    LPacote.Nome := Trim(FEdtNome.Text);
    LPacote.Max_Convidados := LMaxConv;
    LPacote.Preco_Semana := LPrecoSemana;
    LPacote.Preco_FDS := LPrecoFDS;
    LPacote.Descricao := Trim(FMemoDescricao.Text);
    if FSwitchAtivo.IsChecked then
      LPacote.Situacao := 1
    else
      LPacote.Situacao := 0;
    FController.DAOPacote.Save(LPacote);
  end;

  OcultarFormulario;
  AtualizarLista;
end;

procedure TFrmPacotesFesta.BtnCancelarFormClick(Sender: TObject);
begin
  OcultarFormulario;
end;

procedure TFrmPacotesFesta.BtnEditarClick(Sender: TObject);
begin
  if Sender is TButton then
    MostrarFormulario(TButton(Sender).Tag);
end;

procedure TFrmPacotesFesta.BtnDesativarClick(Sender: TObject);
var
  LPacote: TPacoteFesta;
  LId: Integer;
begin
  if not (Sender is TButton) then
    Exit;

  LId := TButton(Sender).Tag;
  LPacote := FController.DAOPacote.Find(LId);
  if Assigned(LPacote) then
  begin
    LPacote.Situacao := 0;
    FController.DAOPacote.Update(LPacote);
    LPacote.Free;
    AtualizarLista;
  end;
end;

{ ===== Lógica ===== }

procedure TFrmPacotesFesta.AtualizarLista;
var
  LPacotes: TObjectList<TPacoteFesta>;
  I: Integer;
  LPacote: TPacoteFesta;
  LRow: TRectangle;
  LLblNome, LLblConv, LLblSemana, LLblFDS, LLblDesc, LLblStatus: TLabel;
  LBtnEditar, LBtnDesativar: TButton;
  LTopY: Single;
begin
  // Limpar lista existente
  while FLayoutLista.ChildrenCount > 0 do
    FLayoutLista.Children[0].Free;

  LPacotes := FController.DAOPacote.FindAll;
  try
    FLayoutLista.Height := LPacotes.Count * (ROW_HEIGHT + 4) + 8;

    for I := 0 to LPacotes.Count - 1 do
    begin
      LPacote := LPacotes[I];
      LTopY := I * (ROW_HEIGHT + 4) + 4;

      // Row background
      LRow := TRectangle.Create(FLayoutLista);
      LRow.Parent := FLayoutLista;
      LRow.Position.X := 0;
      LRow.Position.Y := LTopY;
      LRow.Width := FScrollLista.Width - 20;
      LRow.Height := ROW_HEIGHT;
      LRow.Fill.Kind := TBrushKind.Solid;
      LRow.Fill.Color := COR_BRANCO;
      LRow.Stroke.Color := COR_CINZA_MEDIO;
      LRow.XRadius := 6;
      LRow.YRadius := 6;
      LRow.HitTest := False;

      // Nome
      LLblNome := TLabel.Create(LRow);
      LLblNome.Parent := LRow;
      LLblNome.Position.X := 12;
      LLblNome.Position.Y := 4;
      LLblNome.Width := 160;
      LLblNome.Height := 22;
      LLblNome.Text := LPacote.Nome;
      LLblNome.StyledSettings := [];
      LLblNome.TextSettings.Font.Size := 13;
      LLblNome.TextSettings.Font.Style := [TFontStyle.fsBold];
      LLblNome.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Max Convidados
      LLblConv := TLabel.Create(LRow);
      LLblConv.Parent := LRow;
      LLblConv.Position.X := 180;
      LLblConv.Position.Y := 4;
      LLblConv.Width := 80;
      LLblConv.Height := 22;
      LLblConv.Text := IntToStr(LPacote.Max_Convidados) + ' conv.';
      LLblConv.StyledSettings := [];
      LLblConv.TextSettings.Font.Size := 12;
      LLblConv.TextSettings.FontColor := COR_CINZA_ESCURO;

      // Preço Semana
      LLblSemana := TLabel.Create(LRow);
      LLblSemana.Parent := LRow;
      LLblSemana.Position.X := 270;
      LLblSemana.Position.Y := 4;
      LLblSemana.Width := 110;
      LLblSemana.Height := 22;
      LLblSemana.Text := 'Sem: R$ ' + FormatFloat('#,##0.00', LPacote.Preco_Semana);
      LLblSemana.StyledSettings := [];
      LLblSemana.TextSettings.Font.Size := 12;
      LLblSemana.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Preço FDS
      LLblFDS := TLabel.Create(LRow);
      LLblFDS.Parent := LRow;
      LLblFDS.Position.X := 390;
      LLblFDS.Position.Y := 4;
      LLblFDS.Width := 110;
      LLblFDS.Height := 22;
      LLblFDS.Text := 'FDS: R$ ' + FormatFloat('#,##0.00', LPacote.Preco_FDS);
      LLblFDS.StyledSettings := [];
      LLblFDS.TextSettings.Font.Size := 12;
      LLblFDS.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Descrição (segunda linha)
      LLblDesc := TLabel.Create(LRow);
      LLblDesc.Parent := LRow;
      LLblDesc.Position.X := 12;
      LLblDesc.Position.Y := 28;
      LLblDesc.Width := 480;
      LLblDesc.Height := 20;
      LLblDesc.Text := LPacote.Descricao;
      LLblDesc.StyledSettings := [];
      LLblDesc.TextSettings.Font.Size := 11;
      LLblDesc.TextSettings.FontColor := COR_CINZA_ESCURO;
      LLblDesc.Trimming := TTextTrimming.Character;

      // Status
      LLblStatus := TLabel.Create(LRow);
      LLblStatus.Parent := LRow;
      LLblStatus.Position.X := 510;
      LLblStatus.Position.Y := 4;
      LLblStatus.Width := 60;
      LLblStatus.Height := 22;
      if LPacote.Situacao = 1 then
      begin
        LLblStatus.Text := 'Ativo';
        LLblStatus.TextSettings.FontColor := COR_VERDE;
      end
      else
      begin
        LLblStatus.Text := 'Inativo';
        LLblStatus.TextSettings.FontColor := COR_VERMELHO;
      end;
      LLblStatus.StyledSettings := [];
      LLblStatus.TextSettings.Font.Size := 12;
      LLblStatus.TextSettings.Font.Style := [TFontStyle.fsBold];

      // Botão Editar
      LBtnEditar := TButton.Create(LRow);
      LBtnEditar.Parent := LRow;
      LBtnEditar.Position.X := 590;
      LBtnEditar.Position.Y := 4;
      LBtnEditar.Width := 70;
      LBtnEditar.Height := 36;
      LBtnEditar.Text := 'Editar';
      LBtnEditar.Tag := LPacote.Id;
      LBtnEditar.StyledSettings := [];
      LBtnEditar.TextSettings.Font.Size := 12;
      LBtnEditar.OnClick := BtnEditarClick;
      LBtnEditar.OnMouseDown := BtnMouseDown;
      LBtnEditar.OnMouseUp := BtnMouseUp;

      // Botão Desativar
      LBtnDesativar := TButton.Create(LRow);
      LBtnDesativar.Parent := LRow;
      LBtnDesativar.Position.X := 668;
      LBtnDesativar.Position.Y := 4;
      LBtnDesativar.Width := 86;
      LBtnDesativar.Height := 36;
      LBtnDesativar.Text := 'Desativar';
      LBtnDesativar.Tag := LPacote.Id;
      LBtnDesativar.StyledSettings := [];
      LBtnDesativar.TextSettings.Font.Size := 12;
      LBtnDesativar.OnClick := BtnDesativarClick;
      LBtnDesativar.OnMouseDown := BtnMouseDown;
      LBtnDesativar.OnMouseUp := BtnMouseUp;
      LBtnDesativar.Enabled := (LPacote.Situacao = 1);
    end;
  finally
    LPacotes.Free;
  end;
end;

procedure TFrmPacotesFesta.MostrarFormulario(APacoteId: Integer);
var
  LPacote: TPacoteFesta;
begin
  FEditandoId := APacoteId;
  FLblErro.Visible := False;
  FLblErro.Text := '';

  if APacoteId > 0 then
  begin
    FLblFormTitle.Text := 'Editar Pacote';
    LPacote := FController.DAOPacote.Find(APacoteId);
    if Assigned(LPacote) then
    begin
      FEdtNome.Text := LPacote.Nome;
      FEdtMaxConvidados.Text := IntToStr(LPacote.Max_Convidados);
      FEdtPrecoSemana.Text := FormatFloat('0.00', LPacote.Preco_Semana);
      FEdtPrecoFDS.Text := FormatFloat('0.00', LPacote.Preco_FDS);
      FMemoDescricao.Text := LPacote.Descricao;
      FSwitchAtivo.IsChecked := (LPacote.Situacao = 1);
      LPacote.Free;
    end;
  end
  else
  begin
    FLblFormTitle.Text := 'Novo Pacote';
    FEdtNome.Text := '';
    FEdtMaxConvidados.Text := '';
    FEdtPrecoSemana.Text := '';
    FEdtPrecoFDS.Text := '';
    FMemoDescricao.Text := '';
    FSwitchAtivo.IsChecked := True;
  end;

  FLayoutOverlay.Visible := True;
  FLayoutOverlay.BringToFront;
  FEdtNome.SetFocus;
end;

procedure TFrmPacotesFesta.OcultarFormulario;
begin
  FLayoutOverlay.Visible := False;
  FEditandoId := 0;
end;

function TFrmPacotesFesta.ValidarFormulario: Boolean;
var
  LNome: string;
  LMaxConv: Integer;
  LPrecoSemana, LPrecoFDS: Currency;
  LDescricao: string;
begin
  Result := False;
  FLblErro.Visible := False;

  // Validar Nome (obrigatório, máx 80 chars)
  LNome := Trim(FEdtNome.Text);
  if LNome = '' then
  begin
    FLblErro.Text := 'Nome do pacote é obrigatório.';
    FLblErro.Visible := True;
    FEdtNome.SetFocus;
    Exit;
  end;
  if Length(LNome) > 80 then
  begin
    FLblErro.Text := 'Nome deve ter no máximo 80 caracteres.';
    FLblErro.Visible := True;
    FEdtNome.SetFocus;
    Exit;
  end;

  // Validar Max Convidados (1-200)
  if not TryStrToInt(Trim(FEdtMaxConvidados.Text), LMaxConv) then
  begin
    FLblErro.Text := 'Máx. convidados deve ser um número inteiro.';
    FLblErro.Visible := True;
    FEdtMaxConvidados.SetFocus;
    Exit;
  end;
  if (LMaxConv < 1) or (LMaxConv > 200) then
  begin
    FLblErro.Text := 'Máx. convidados deve ser entre 1 e 200.';
    FLblErro.Visible := True;
    FEdtMaxConvidados.SetFocus;
    Exit;
  end;

  // Validar Preço Semana (0.01 - 99999.99)
  try
    LPrecoSemana := StrToCurr(
      StringReplace(Trim(FEdtPrecoSemana.Text), ',', '.', []));
  except
    FLblErro.Text := 'Preço semana inválido.';
    FLblErro.Visible := True;
    FEdtPrecoSemana.SetFocus;
    Exit;
  end;
  if (LPrecoSemana < 0.01) or (LPrecoSemana > 99999.99) then
  begin
    FLblErro.Text := 'Preço semana deve ser entre R$ 0,01 e R$ 99.999,99.';
    FLblErro.Visible := True;
    FEdtPrecoSemana.SetFocus;
    Exit;
  end;

  // Validar Preço FDS (0.01 - 99999.99)
  try
    LPrecoFDS := StrToCurr(
      StringReplace(Trim(FEdtPrecoFDS.Text), ',', '.', []));
  except
    FLblErro.Text := 'Preço FDS inválido.';
    FLblErro.Visible := True;
    FEdtPrecoFDS.SetFocus;
    Exit;
  end;
  if (LPrecoFDS < 0.01) or (LPrecoFDS > 99999.99) then
  begin
    FLblErro.Text := 'Preço FDS deve ser entre R$ 0,01 e R$ 99.999,99.';
    FLblErro.Visible := True;
    FEdtPrecoFDS.SetFocus;
    Exit;
  end;

  // Validar Descrição (máx 500 chars)
  LDescricao := Trim(FMemoDescricao.Text);
  if Length(LDescricao) > 500 then
  begin
    FLblErro.Text := 'Descrição deve ter no máximo 500 caracteres.';
    FLblErro.Visible := True;
    FMemoDescricao.SetFocus;
    Exit;
  end;

  Result := True;
end;

{ ===== Touch Feedback ===== }

procedure TFrmPacotesFesta.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TControl then
    TControl(Sender).Opacity := 0.7;
end;

procedure TFrmPacotesFesta.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TControl then
    TControl(Sender).Opacity := 1.0;
end;

end.
