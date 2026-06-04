unit Frm.Visitantes;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  FMX.ListBox,
  FMX.Edit,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.DialogService,
  Controller.Visitante,
  Model.Entidade.Visita,
  Model.Entidade.Tutor,
  Model.Entidade.Visitante,
  Model.Entidade.Ticket,
  Model.Entidade.Produto,
  Model.Entidade.VisitaConsumo,
  Mock.DAO;

type
  /// <summary>
  /// Registro auxiliar para armazenar dados de uma visita ativa exibida no painel.
  /// </summary>
  TVisitaCard = record
    VisitaId: Integer;
    NomeCrianca: string;
    NomeTutor: string;
    HoraPrevistaSaida: TDateTime;
    ValorConsumo: Currency;
    TicketId: Integer;
    VisitanteId: Integer;
    Layout: TLayout;
    LblNomeCrianca: TLabel;
    LblNomeTutor: TLabel;
    LblTimer: TLabel;
    LblConsumo: TLabel;
    RectFundo: TRectangle;
  end;

  /// <summary>
  /// Tela de gestão de visitantes do parque.
  /// Exibe visitas ativas com countdown timer, permite registrar novas entradas,
  /// consumo de produtos e finalização com cobrança.
  /// Timer atualiza a cada 1 segundo com cores: verde (>10min), amarelo (5-10min), vermelho (<5min).
  /// Alerta visual/sonoro quando tempo <= minutos configurados.
  /// </summary>
  TFrmVisitantes = class(TForm)
  private
    { Controller }
    FController: TControllerVisitante;

    { Mock data DAOs }
    FDAOProduto: IDAO<TProduto>;

    { Timer principal - 1 segundo }
    FTimerCountdown: TTimer;

    { Configuracao de alerta (minutos) }
    FMinutosAlerta: Integer;

    { ID do caixa aberto }
    FCaixaId: Integer;

    { Lista de cards de visitas ativas }
    FVisitaCards: TList<TVisitaCard>;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Painel esquerdo - Visitas ativas }
    FLayoutVisitasAtivas: TLayout;
    FRectVisitasHeader: TRectangle;
    FLblVisitasTitle: TLabel;
    FScrollVisitas: TVertScrollBox;

    { Painel direito - Nova entrada }
    FLayoutNovaEntrada: TLayout;
    FRectNovaEntradaHeader: TRectangle;
    FLblNovaEntradaTitle: TLabel;
    FScrollNovaEntrada: TVertScrollBox;

    { Campos Nova Entrada }
    FEdtCPF: TEdit;
    FBtnBuscarCPF: TButton;
    FEdtTutorNome: TEdit;
    FEdtTutorTelefone: TEdit;
    FLblTutorId: TLabel;  // armazena ID do tutor encontrado
    FCmbCrianca: TComboBox;
    FCmbTicket: TComboBox;
    FBtnIniciarVisita: TButton;

    { Mock data }
    FMockTutores: TObjectList<TTutor>;
    FMockVisitantes: TObjectList<TVisitante>;
    FMockTickets: TObjectList<TTicket>;
    FMockProdutos: TObjectList<TProduto>;

    { Procedimentos de criacao da UI }
    procedure CriarComponentes;
    procedure CriarPainelVisitasAtivas;
    procedure CriarPainelNovaEntrada;
    procedure CriarTimer;
    procedure CriarMockData;

    { Atualizar timer de todas as visitas }
    procedure TimerCountdownTick(Sender: TObject);

    { Calcular cor baseada no tempo restante }
    function CorPorTempoRestante(AMinutosRestantes: Integer): TAlphaColor;

    { Formatar tempo restante em HH:MM:SS }
    function FormatarTempoRestante(ASegundosRestantes: Int64): string;

    { Handlers }
    procedure BtnBuscarCPFClick(Sender: TObject);
    procedure BtnIniciarVisitaClick(Sender: TObject);
    procedure BtnFinalizarClick(Sender: TObject);
    procedure BtnConsumoClick(Sender: TObject);

    { Dialogs }
    procedure MostrarDialogConsumo(AVisitaId: Integer);
    procedure MostrarDialogFinalizacao(AVisitaId: Integer);

    { Atualizar lista de visitas ativas }
    procedure AtualizarVisitasAtivas;
    procedure LimparCardsVisitas;
    procedure CriarCardVisita(AVisita: TVisita);

    { Preencher combos }
    procedure PreencherComboCriancas(ATutorId: Integer);
    procedure PreencherComboTickets;

    { Limpar campos nova entrada }
    procedure LimparCamposNovaEntrada;

  public
    constructor Create(AOwner: TComponent; ACaixaId: Integer); reintroduce;
    destructor Destroy; override;

    /// <summary>ID do caixa aberto para vincular visitas</summary>
    property CaixaId: Integer read FCaixaId write FCaixaId;
    /// <summary>Minutos antes do vencimento para alerta (padrao 5)</summary>
    property MinutosAlerta: Integer read FMinutosAlerta write FMinutosAlerta;
  end;

implementation

const
  COR_VERDE = $FF4CAF50;       // Green 500 (> 10 min)
  COR_AMARELO = $FFFFC107;     // Amber 500 (5-10 min)
  COR_VERMELHO = $FFF44336;    // Red 500 (< 5 min ou expirado)
  COR_HEADER_PANEL = $FF1565C0; // Blue 800
  COR_CARD_BG = $FFFFFFFF;      // White
  COR_CARD_BORDER = $FFE0E0E0;  // Grey 300
  COR_TEXTO_ESCURO = $FF212121; // Grey 900
  COR_TEXTO_MEDIO = $FF616161;  // Grey 700
  COR_TEXTO_BRANCO = $FFFFFFFF;
  COR_BG_PANEL = $FFF5F5F5;     // Grey 100
  COR_BTN_PRIMARIO = $FF1976D2; // Blue 700
  COR_BTN_PERIGO = $FFD32F2F;   // Red 700
  COR_BTN_SUCESSO = $FF388E3C;  // Green 700
  COR_BADGE_BG = $FFFF9800;     // Orange 500

  CARD_HEIGHT = 120;
  CARD_MARGIN = 8;

{ TFrmVisitantes }

constructor TFrmVisitantes.Create(AOwner: TComponent; ACaixaId: Integer);
begin
  inherited CreateNew(AOwner);

  FCaixaId := ACaixaId;
  FMinutosAlerta := 5;
  FVisitaCards := TList<TVisitaCard>.Create;

  FController := TControllerVisitante.Create;

  Caption := 'Visitantes';
  ClientWidth := 1024;
  ClientHeight := 700;

  CriarMockData;
  CriarComponentes;
  PreencherComboTickets;
  AtualizarVisitasAtivas;
  CriarTimer;
end;

destructor TFrmVisitantes.Destroy;
begin
  if Assigned(FTimerCountdown) then
    FTimerCountdown.Enabled := False;

  FVisitaCards.Free;
  FMockTutores.Free;
  FMockVisitantes.Free;
  FMockTickets.Free;
  FMockProdutos.Free;
  FController.Free;
  inherited Destroy;
end;

procedure TFrmVisitantes.CriarMockData;
var
  LTutor: TTutor;
  LVisitante: TVisitante;
  LTicket: TTicket;
  LProduto: TProduto;
begin
  // --- Mock Tutores ---
  FMockTutores := TObjectList<TTutor>.Create(True);

  LTutor := TTutor.Create;
  LTutor.Id := 1;
  LTutor.Nome := 'Maria Silva';
  LTutor.CPF := '12345678901';
  LTutor.Telefone := '11999990001';
  LTutor.Email := 'maria@email.com';
  FMockTutores.Add(LTutor);

  LTutor := TTutor.Create;
  LTutor.Id := 2;
  LTutor.Nome := 'Joao Santos';
  LTutor.CPF := '98765432100';
  LTutor.Telefone := '11999990002';
  LTutor.Email := 'joao@email.com';
  FMockTutores.Add(LTutor);

  LTutor := TTutor.Create;
  LTutor.Id := 3;
  LTutor.Nome := 'Ana Oliveira';
  LTutor.CPF := '45678912300';
  LTutor.Telefone := '11999990003';
  LTutor.Email := 'ana@email.com';
  FMockTutores.Add(LTutor);

  // --- Mock Visitantes (criancas) ---
  FMockVisitantes := TObjectList<TVisitante>.Create(True);

  LVisitante := TVisitante.Create;
  LVisitante.Id := 1;
  LVisitante.Nome := 'Pedro Silva';
  LVisitante.Data_Nascimento := EncodeDate(2018, 3, 15);
  LVisitante.Tutor_Id := 1;
  LVisitante.Limite_Consumo := 50.00;
  FMockVisitantes.Add(LVisitante);

  LVisitante := TVisitante.Create;
  LVisitante.Id := 2;
  LVisitante.Nome := 'Laura Silva';
  LVisitante.Data_Nascimento := EncodeDate(2020, 7, 22);
  LVisitante.Tutor_Id := 1;
  LVisitante.Limite_Consumo := 30.00;
  FMockVisitantes.Add(LVisitante);

  LVisitante := TVisitante.Create;
  LVisitante.Id := 3;
  LVisitante.Nome := 'Lucas Santos';
  LVisitante.Data_Nascimento := EncodeDate(2017, 11, 5);
  LVisitante.Tutor_Id := 2;
  LVisitante.Limite_Consumo := 80.00;
  FMockVisitantes.Add(LVisitante);

  LVisitante := TVisitante.Create;
  LVisitante.Id := 4;
  LVisitante.Nome := 'Sofia Oliveira';
  LVisitante.Data_Nascimento := EncodeDate(2019, 1, 30);
  LVisitante.Tutor_Id := 3;
  LVisitante.Limite_Consumo := 60.00;
  FMockVisitantes.Add(LVisitante);

  // --- Mock Tickets ---
  FMockTickets := TObjectList<TTicket>.Create(True);

  LTicket := TTicket.Create;
  LTicket.Id := 1;
  LTicket.Nome := '30 Minutos';
  LTicket.Duracao_Minutos := 30;
  LTicket.Tipo := 'TEMPO';
  LTicket.Preco := 25.00;
  FMockTickets.Add(LTicket);

  LTicket := TTicket.Create;
  LTicket.Id := 2;
  LTicket.Nome := '60 Minutos';
  LTicket.Duracao_Minutos := 60;
  LTicket.Tipo := 'TEMPO';
  LTicket.Preco := 40.00;
  FMockTickets.Add(LTicket);

  LTicket := TTicket.Create;
  LTicket.Id := 3;
  LTicket.Nome := '120 Minutos';
  LTicket.Duracao_Minutos := 120;
  LTicket.Tipo := 'TEMPO';
  LTicket.Preco := 65.00;
  FMockTickets.Add(LTicket);

  LTicket := TTicket.Create;
  LTicket.Id := 4;
  LTicket.Nome := 'Day Pass';
  LTicket.Duracao_Minutos := 0;
  LTicket.Tipo := 'DAY_PASS';
  LTicket.Preco := 90.00;
  FMockTickets.Add(LTicket);

  // --- Mock Produtos (consumo no parque) ---
  FMockProdutos := TObjectList<TProduto>.Create(True);

  LProduto := TProduto.Create;
  LProduto.Id := 1;
  LProduto.Nome := 'Agua Mineral 500ml';
  LProduto.Preco_Venda := 5.00;
  LProduto.Tipo := 'PRODUTO';
  FMockProdutos.Add(LProduto);

  LProduto := TProduto.Create;
  LProduto.Id := 2;
  LProduto.Nome := 'Suco Natural 300ml';
  LProduto.Preco_Venda := 8.00;
  LProduto.Tipo := 'PRODUTO';
  FMockProdutos.Add(LProduto);

  LProduto := TProduto.Create;
  LProduto.Id := 3;
  LProduto.Nome := 'Pipoca Grande';
  LProduto.Preco_Venda := 12.00;
  LProduto.Tipo := 'PRODUTO';
  FMockProdutos.Add(LProduto);

  LProduto := TProduto.Create;
  LProduto.Id := 4;
  LProduto.Nome := 'Hamburguer Kids';
  LProduto.Preco_Venda := 18.00;
  LProduto.Tipo := 'PRODUTO';
  FMockProdutos.Add(LProduto);

  LProduto := TProduto.Create;
  LProduto.Id := 5;
  LProduto.Nome := 'Sorvete 2 Bolas';
  LProduto.Preco_Venda := 15.00;
  LProduto.Tipo := 'PRODUTO';
  FMockProdutos.Add(LProduto);

  // --- Criar visitas mock ativas para demonstracao ---
  // Visita 1: Pedro Silva, 60min, entrada ha 45min (restam ~15min)
  FController.IniciarVisita(1, 1, 2, FCaixaId);

  // Visita 2: Lucas Santos, 30min, simular entrada ha 27min (restam ~3min - alerta!)
  FController.IniciarVisita(2, 3, 1, FCaixaId);
  // Ajustar hora de entrada para simular passagem de tempo
  FController.Entidade.Hora_Entrada := Now - (27 / (24 * 60));
  FController.Entidade.Hora_Prevista_Saida := FController.Entidade.Hora_Entrada + (30 / (24 * 60));

  // Visita 3: Sofia Oliveira, 120min, entrada ha 5min (restam ~115min)
  FController.IniciarVisita(3, 4, 3, FCaixaId);
end;

procedure TFrmVisitantes.CriarComponentes;
begin
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;
  FLayoutPrincipal.Padding.Left := 8;
  FLayoutPrincipal.Padding.Right := 8;
  FLayoutPrincipal.Padding.Top := 8;
  FLayoutPrincipal.Padding.Bottom := 8;

  CriarPainelNovaEntrada;
  CriarPainelVisitasAtivas;
end;

procedure TFrmVisitantes.CriarPainelVisitasAtivas;
begin
  // Painel esquerdo - Visitas ativas (ocupa restante)
  FLayoutVisitasAtivas := TLayout.Create(Self);
  FLayoutVisitasAtivas.Parent := FLayoutPrincipal;
  FLayoutVisitasAtivas.Align := TAlignLayout.Client;
  FLayoutVisitasAtivas.Margins.Right := 8;

  // Header do painel
  FRectVisitasHeader := TRectangle.Create(Self);
  FRectVisitasHeader.Parent := FLayoutVisitasAtivas;
  FRectVisitasHeader.Align := TAlignLayout.Top;
  FRectVisitasHeader.Height := 44;
  FRectVisitasHeader.Fill.Kind := TBrushKind.Solid;
  FRectVisitasHeader.Fill.Color := COR_HEADER_PANEL;
  FRectVisitasHeader.Stroke.Kind := TBrushKind.None;
  FRectVisitasHeader.XRadius := 4;
  FRectVisitasHeader.YRadius := 4;

  FLblVisitasTitle := TLabel.Create(Self);
  FLblVisitasTitle.Parent := FRectVisitasHeader;
  FLblVisitasTitle.Align := TAlignLayout.Client;
  FLblVisitasTitle.Margins.Left := 12;
  FLblVisitasTitle.Text := 'Visitas Ativas';
  FLblVisitasTitle.StyledSettings := [];
  FLblVisitasTitle.TextSettings.Font.Size := 16;
  FLblVisitasTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblVisitasTitle.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblVisitasTitle.TextSettings.VertAlign := TTextAlign.Center;

  // ScrollBox para cards
  FScrollVisitas := TVertScrollBox.Create(Self);
  FScrollVisitas.Parent := FLayoutVisitasAtivas;
  FScrollVisitas.Align := TAlignLayout.Client;
  FScrollVisitas.Margins.Top := 4;
end;

procedure TFrmVisitantes.CriarPainelNovaEntrada;
var
  LPosY: Single;
  LLbl: TLabel;
begin
  // Painel direito - Nova entrada (largura fixa 320px)
  FLayoutNovaEntrada := TLayout.Create(Self);
  FLayoutNovaEntrada.Parent := FLayoutPrincipal;
  FLayoutNovaEntrada.Align := TAlignLayout.Right;
  FLayoutNovaEntrada.Width := 320;

  // Header do painel
  FRectNovaEntradaHeader := TRectangle.Create(Self);
  FRectNovaEntradaHeader.Parent := FLayoutNovaEntrada;
  FRectNovaEntradaHeader.Align := TAlignLayout.Top;
  FRectNovaEntradaHeader.Height := 44;
  FRectNovaEntradaHeader.Fill.Kind := TBrushKind.Solid;
  FRectNovaEntradaHeader.Fill.Color := COR_BTN_SUCESSO;
  FRectNovaEntradaHeader.Stroke.Kind := TBrushKind.None;
  FRectNovaEntradaHeader.XRadius := 4;
  FRectNovaEntradaHeader.YRadius := 4;

  FLblNovaEntradaTitle := TLabel.Create(Self);
  FLblNovaEntradaTitle.Parent := FRectNovaEntradaHeader;
  FLblNovaEntradaTitle.Align := TAlignLayout.Client;
  FLblNovaEntradaTitle.Margins.Left := 12;
  FLblNovaEntradaTitle.Text := 'Nova Entrada';
  FLblNovaEntradaTitle.StyledSettings := [];
  FLblNovaEntradaTitle.TextSettings.Font.Size := 16;
  FLblNovaEntradaTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblNovaEntradaTitle.TextSettings.FontColor := COR_TEXTO_BRANCO;
  FLblNovaEntradaTitle.TextSettings.VertAlign := TTextAlign.Center;

  // ScrollBox para campos
  FScrollNovaEntrada := TVertScrollBox.Create(Self);
  FScrollNovaEntrada.Parent := FLayoutNovaEntrada;
  FScrollNovaEntrada.Align := TAlignLayout.Client;
  FScrollNovaEntrada.Margins.Top := 4;

  LPosY := 8;

  // --- CPF Search ---
  LLbl := TLabel.Create(Self);
  LLbl.Parent := FScrollNovaEntrada;
  LLbl.Position.X := 8;
  LLbl.Position.Y := LPosY;
  LLbl.Width := 280;
  LLbl.Height := 20;
  LLbl.Text := 'CPF do Tutor:';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LPosY := LPosY + 22;

  FEdtCPF := TEdit.Create(Self);
  FEdtCPF.Parent := FScrollNovaEntrada;
  FEdtCPF.Position.X := 8;
  FEdtCPF.Position.Y := LPosY;
  FEdtCPF.Width := 200;
  FEdtCPF.Height := 32;
  FEdtCPF.TextPrompt := '000.000.000-00';
  FEdtCPF.StyledSettings := [];
  FEdtCPF.TextSettings.Font.Size := 14;
  LPosY := LPosY + 36;

  FBtnBuscarCPF := TButton.Create(Self);
  FBtnBuscarCPF.Parent := FScrollNovaEntrada;
  FBtnBuscarCPF.Position.X := 212;
  FBtnBuscarCPF.Position.Y := LPosY - 36;
  FBtnBuscarCPF.Width := 80;
  FBtnBuscarCPF.Height := 32;
  FBtnBuscarCPF.Text := 'Buscar';
  FBtnBuscarCPF.StyledSettings := [];
  FBtnBuscarCPF.TextSettings.Font.Size := 12;
  FBtnBuscarCPF.OnClick := BtnBuscarCPFClick;

  // --- Tutor Name ---
  LLbl := TLabel.Create(Self);
  LLbl.Parent := FScrollNovaEntrada;
  LLbl.Position.X := 8;
  LLbl.Position.Y := LPosY;
  LLbl.Width := 280;
  LLbl.Height := 20;
  LLbl.Text := 'Nome do Tutor:';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LPosY := LPosY + 22;

  FEdtTutorNome := TEdit.Create(Self);
  FEdtTutorNome.Parent := FScrollNovaEntrada;
  FEdtTutorNome.Position.X := 8;
  FEdtTutorNome.Position.Y := LPosY;
  FEdtTutorNome.Width := 284;
  FEdtTutorNome.Height := 32;
  FEdtTutorNome.TextPrompt := 'Nome completo';
  FEdtTutorNome.StyledSettings := [];
  FEdtTutorNome.TextSettings.Font.Size := 14;
  LPosY := LPosY + 36;

  // --- Tutor Telefone ---
  LLbl := TLabel.Create(Self);
  LLbl.Parent := FScrollNovaEntrada;
  LLbl.Position.X := 8;
  LLbl.Position.Y := LPosY;
  LLbl.Width := 280;
  LLbl.Height := 20;
  LLbl.Text := 'Telefone:';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LPosY := LPosY + 22;

  FEdtTutorTelefone := TEdit.Create(Self);
  FEdtTutorTelefone.Parent := FScrollNovaEntrada;
  FEdtTutorTelefone.Position.X := 8;
  FEdtTutorTelefone.Position.Y := LPosY;
  FEdtTutorTelefone.Width := 284;
  FEdtTutorTelefone.Height := 32;
  FEdtTutorTelefone.TextPrompt := '(11) 99999-0000';
  FEdtTutorTelefone.StyledSettings := [];
  FEdtTutorTelefone.TextSettings.Font.Size := 14;
  LPosY := LPosY + 36;

  // Hidden label for tutor ID
  FLblTutorId := TLabel.Create(Self);
  FLblTutorId.Parent := FScrollNovaEntrada;
  FLblTutorId.Visible := False;
  FLblTutorId.Text := '0';

  // --- Crianca select ---
  LLbl := TLabel.Create(Self);
  LLbl.Parent := FScrollNovaEntrada;
  LLbl.Position.X := 8;
  LLbl.Position.Y := LPosY;
  LLbl.Width := 280;
  LLbl.Height := 20;
  LLbl.Text := 'Crianca:';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LPosY := LPosY + 22;

  FCmbCrianca := TComboBox.Create(Self);
  FCmbCrianca.Parent := FScrollNovaEntrada;
  FCmbCrianca.Position.X := 8;
  FCmbCrianca.Position.Y := LPosY;
  FCmbCrianca.Width := 284;
  FCmbCrianca.Height := 32;
  LPosY := LPosY + 40;

  // --- Ticket select ---
  LLbl := TLabel.Create(Self);
  LLbl.Parent := FScrollNovaEntrada;
  LLbl.Position.X := 8;
  LLbl.Position.Y := LPosY;
  LLbl.Width := 280;
  LLbl.Height := 20;
  LLbl.Text := 'Ticket:';
  LLbl.StyledSettings := [];
  LLbl.TextSettings.Font.Size := 12;
  LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;
  LPosY := LPosY + 22;

  FCmbTicket := TComboBox.Create(Self);
  FCmbTicket.Parent := FScrollNovaEntrada;
  FCmbTicket.Position.X := 8;
  FCmbTicket.Position.Y := LPosY;
  FCmbTicket.Width := 284;
  FCmbTicket.Height := 32;
  LPosY := LPosY + 48;

  // --- Botao Iniciar Visita ---
  FBtnIniciarVisita := TButton.Create(Self);
  FBtnIniciarVisita.Parent := FScrollNovaEntrada;
  FBtnIniciarVisita.Position.X := 8;
  FBtnIniciarVisita.Position.Y := LPosY;
  FBtnIniciarVisita.Width := 284;
  FBtnIniciarVisita.Height := 48;
  FBtnIniciarVisita.Text := 'Iniciar Visita';
  FBtnIniciarVisita.StyledSettings := [];
  FBtnIniciarVisita.TextSettings.Font.Size := 16;
  FBtnIniciarVisita.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnIniciarVisita.OnClick := BtnIniciarVisitaClick;
end;

procedure TFrmVisitantes.CriarTimer;
begin
  FTimerCountdown := TTimer.Create(Self);
  FTimerCountdown.Interval := 1000; // 1 segundo
  FTimerCountdown.OnTimer := TimerCountdownTick;
  FTimerCountdown.Enabled := True;
end;

procedure TFrmVisitantes.TimerCountdownTick(Sender: TObject);
var
  I: Integer;
  LCard: TVisitaCard;
  LSegundosRestantes: Int64;
  LMinutosRestantes: Integer;
  LCor: TAlphaColor;
begin
  for I := 0 to FVisitaCards.Count - 1 do
  begin
    LCard := FVisitaCards[I];

    // Calcular segundos restantes
    LSegundosRestantes := SecondsBetween(LCard.HoraPrevistaSaida, Now);
    if Now > LCard.HoraPrevistaSaida then
      LSegundosRestantes := -LSegundosRestantes;

    LMinutosRestantes := LSegundosRestantes div 60;

    // Atualizar label do timer
    if LSegundosRestantes < 0 then
      LCard.LblTimer.Text := '-' + FormatarTempoRestante(Abs(LSegundosRestantes)) + ' (EXPIRADO)'
    else
      LCard.LblTimer.Text := FormatarTempoRestante(LSegundosRestantes);

    // Atualizar cor do card baseado no tempo restante
    LCor := CorPorTempoRestante(LMinutosRestantes);
    LCard.RectFundo.Stroke.Color := LCor;
    LCard.RectFundo.Stroke.Thickness := 3;
    LCard.LblTimer.TextSettings.FontColor := LCor;

    // Alerta visual quando tempo <= minutos configurados
    if (LMinutosRestantes <= FMinutosAlerta) and (LMinutosRestantes >= 0) then
    begin
      // Efeito piscante a cada segundo (alterna opacidade)
      if Odd(SecondOf(Now)) then
        LCard.RectFundo.Opacity := 0.85
      else
        LCard.RectFundo.Opacity := 1.0;
    end
    else
      LCard.RectFundo.Opacity := 1.0;
  end;
end;

function TFrmVisitantes.CorPorTempoRestante(AMinutosRestantes: Integer): TAlphaColor;
begin
  if AMinutosRestantes > 10 then
    Result := COR_VERDE
  else if AMinutosRestantes >= 5 then
    Result := COR_AMARELO
  else
    Result := COR_VERMELHO;
end;

function TFrmVisitantes.FormatarTempoRestante(ASegundosRestantes: Int64): string;
var
  LH, LM, LS: Integer;
begin
  LH := ASegundosRestantes div 3600;
  LM := (ASegundosRestantes mod 3600) div 60;
  LS := ASegundosRestantes mod 60;
  Result := Format('%.2d:%.2d:%.2d', [LH, LM, LS]);
end;

procedure TFrmVisitantes.BtnBuscarCPFClick(Sender: TObject);
var
  LCPF: string;
  I: Integer;
  LTutor: TTutor;
begin
  LCPF := StringReplace(FEdtCPF.Text, '.', '', [rfReplaceAll]);
  LCPF := StringReplace(LCPF, '-', '', [rfReplaceAll]);
  LCPF := Trim(LCPF);

  if LCPF = '' then
  begin
    TDialogService.ShowMessage('Informe o CPF do tutor.');
    Exit;
  end;

  // Buscar tutor nos dados mock
  LTutor := nil;
  for I := 0 to FMockTutores.Count - 1 do
  begin
    if FMockTutores[I].CPF = LCPF then
    begin
      LTutor := FMockTutores[I];
      Break;
    end;
  end;

  if Assigned(LTutor) then
  begin
    // Auto-preencher campos do tutor
    FEdtTutorNome.Text := LTutor.Nome;
    FEdtTutorTelefone.Text := LTutor.Telefone;
    FLblTutorId.Text := IntToStr(LTutor.Id);
    // Preencher combo de criancas
    PreencherComboCriancas(LTutor.Id);
    TDialogService.ShowMessage('Tutor encontrado: ' + LTutor.Nome);
  end
  else
  begin
    // Limpar campos para cadastro manual
    FEdtTutorNome.Text := '';
    FEdtTutorTelefone.Text := '';
    FLblTutorId.Text := '0';
    FCmbCrianca.Clear;
    TDialogService.ShowMessage('Tutor nao encontrado. Preencha os dados manualmente.');
  end;
end;

procedure TFrmVisitantes.BtnIniciarVisitaClick(Sender: TObject);
var
  LTutorId, LVisitanteId, LTicketId: Integer;
begin
  // Validar campos
  LTutorId := StrToIntDef(FLblTutorId.Text, 0);
  if LTutorId <= 0 then
  begin
    TDialogService.ShowMessage('Busque o tutor pelo CPF primeiro.');
    Exit;
  end;

  if FCmbCrianca.ItemIndex < 0 then
  begin
    TDialogService.ShowMessage('Selecione a crianca.');
    Exit;
  end;

  if FCmbTicket.ItemIndex < 0 then
  begin
    TDialogService.ShowMessage('Selecione o ticket.');
    Exit;
  end;

  // Obter IDs selecionados
  LVisitanteId := Integer(FCmbCrianca.ListItems[FCmbCrianca.ItemIndex].Tag);
  LTicketId := Integer(FCmbTicket.ListItems[FCmbTicket.ItemIndex].Tag);

  // Iniciar visita via controller
  try
    FController.IniciarVisita(LTutorId, LVisitanteId, LTicketId, FCaixaId);
    TDialogService.ShowMessage('Visita iniciada com sucesso!');
    LimparCamposNovaEntrada;
    AtualizarVisitasAtivas;
  except
    on E: Exception do
      TDialogService.ShowMessage('Erro ao iniciar visita: ' + E.Message);
  end;
end;

procedure TFrmVisitantes.BtnFinalizarClick(Sender: TObject);
var
  LVisitaId: Integer;
begin
  LVisitaId := TButton(Sender).Tag;
  MostrarDialogFinalizacao(LVisitaId);
end;

procedure TFrmVisitantes.BtnConsumoClick(Sender: TObject);
var
  LVisitaId: Integer;
begin
  LVisitaId := TButton(Sender).Tag;
  MostrarDialogConsumo(LVisitaId);
end;

procedure TFrmVisitantes.MostrarDialogConsumo(AVisitaId: Integer);
var
  LDialog: TForm;
  LLayout: TLayout;
  LLbl: TLabel;
  LCmbProduto: TComboBox;
  LEdtQtd: TEdit;
  LLblTotal: TLabel;
  LBtnRegistrar: TButton;
  LBtnCancelar: TButton;
  LItem: TListBoxItem;
  I: Integer;
  LVisitas: TObjectList<TVisita>;
  LVisita: TVisita;
  LVisitaEncontrada: Boolean;
begin
  // Encontrar a visita pelo ID
  LVisitaEncontrada := False;
  LVisitas := FController.VisitasAbertas;
  try
    for I := 0 to LVisitas.Count - 1 do
    begin
      if LVisitas[I].Id = AVisitaId then
      begin
        LVisita := LVisitas[I];
        LVisitaEncontrada := True;
        Break;
      end;
    end;

    if not LVisitaEncontrada then
    begin
      TDialogService.ShowMessage('Visita nao encontrada.');
      Exit;
    end;

    // Criar dialog de consumo
    LDialog := TForm.CreateNew(Self);
    try
      LDialog.Caption := 'Registrar Consumo';
      LDialog.ClientWidth := 400;
      LDialog.ClientHeight := 320;
      LDialog.Position := TFormPosition.MainFormCenter;
      LDialog.BorderStyle := TFmxFormBorderStyle.ToolWindow;

      LLayout := TLayout.Create(LDialog);
      LLayout.Parent := LDialog;
      LLayout.Align := TAlignLayout.Client;
      LLayout.Padding.Left := 16;
      LLayout.Padding.Right := 16;
      LLayout.Padding.Top := 16;
      LLayout.Padding.Bottom := 16;

      // Titulo
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 0;
      LLbl.Width := 360;
      LLbl.Height := 24;
      LLbl.Text := 'Consumo - Visita #' + IntToStr(AVisitaId);
      LLbl.StyledSettings := [];
      LLbl.TextSettings.Font.Size := 16;
      LLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
      LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Label consumo atual
      LLblTotal := TLabel.Create(LDialog);
      LLblTotal.Parent := LLayout;
      LLblTotal.Position.X := 0;
      LLblTotal.Position.Y := 30;
      LLblTotal.Width := 360;
      LLblTotal.Height := 24;
      LLblTotal.Text := Format('Consumo atual: R$ %.2f', [LVisita.Valor_Consumo]);
      LLblTotal.StyledSettings := [];
      LLblTotal.TextSettings.Font.Size := 14;
      LLblTotal.TextSettings.FontColor := COR_TEXTO_MEDIO;

      // Label produto
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 64;
      LLbl.Width := 360;
      LLbl.Height := 20;
      LLbl.Text := 'Produto:';
      LLbl.StyledSettings := [];
      LLbl.TextSettings.Font.Size := 12;

      // Combo produto
      LCmbProduto := TComboBox.Create(LDialog);
      LCmbProduto.Parent := LLayout;
      LCmbProduto.Position.X := 0;
      LCmbProduto.Position.Y := 86;
      LCmbProduto.Width := 360;
      LCmbProduto.Height := 32;

      for I := 0 to FMockProdutos.Count - 1 do
      begin
        LItem := TListBoxItem.Create(LCmbProduto);
        LItem.Text := FMockProdutos[I].Nome + ' - R$ ' +
          FormatFloat('0.00', FMockProdutos[I].Preco_Venda);
        LItem.Tag := FMockProdutos[I].Id;
        LCmbProduto.AddObject(LItem);
      end;

      // Label quantidade
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 128;
      LLbl.Width := 360;
      LLbl.Height := 20;
      LLbl.Text := 'Quantidade:';
      LLbl.StyledSettings := [];
      LLbl.TextSettings.Font.Size := 12;

      // Edit quantidade
      LEdtQtd := TEdit.Create(LDialog);
      LEdtQtd.Parent := LLayout;
      LEdtQtd.Position.X := 0;
      LEdtQtd.Position.Y := 150;
      LEdtQtd.Width := 100;
      LEdtQtd.Height := 32;
      LEdtQtd.Text := '1';
      LEdtQtd.StyledSettings := [];
      LEdtQtd.TextSettings.Font.Size := 14;

      // Botao Registrar Consumo
      LBtnRegistrar := TButton.Create(LDialog);
      LBtnRegistrar.Parent := LLayout;
      LBtnRegistrar.Position.X := 0;
      LBtnRegistrar.Position.Y := 210;
      LBtnRegistrar.Width := 170;
      LBtnRegistrar.Height := 48;
      LBtnRegistrar.Text := 'Registrar Consumo';
      LBtnRegistrar.StyledSettings := [];
      LBtnRegistrar.TextSettings.Font.Size := 14;
      LBtnRegistrar.TextSettings.Font.Style := [TFontStyle.fsBold];
      LBtnRegistrar.ModalResult := mrOk;

      // Botao Cancelar
      LBtnCancelar := TButton.Create(LDialog);
      LBtnCancelar.Parent := LLayout;
      LBtnCancelar.Position.X := 190;
      LBtnCancelar.Position.Y := 210;
      LBtnCancelar.Width := 170;
      LBtnCancelar.Height := 48;
      LBtnCancelar.Text := 'Cancelar';
      LBtnCancelar.StyledSettings := [];
      LBtnCancelar.TextSettings.Font.Size := 14;
      LBtnCancelar.ModalResult := mrCancel;

      // Mostrar dialog modal
      if LDialog.ShowModal = mrOk then
      begin
        if (LCmbProduto.ItemIndex >= 0) and (StrToIntDef(LEdtQtd.Text, 0) > 0) then
        begin
          try
            // Setar a entidade do controller para a visita correta
            FController.Entidade.Id := AVisitaId;
            FController.Entidade.Valor_Consumo := LVisita.Valor_Consumo;
            FController.Entidade.Visitante_Id := LVisita.Visitante_Id;

            FController.RegistrarConsumo(
              Integer(LCmbProduto.ListItems[LCmbProduto.ItemIndex].Tag),
              StrToInt(LEdtQtd.Text),
              FMockProdutos[LCmbProduto.ItemIndex].Preco_Venda
            );
            TDialogService.ShowMessage('Consumo registrado!');
            AtualizarVisitasAtivas;
          except
            on E: Exception do
              TDialogService.ShowMessage('Erro: ' + E.Message);
          end;
        end;
      end;
    finally
      LDialog.Free;
    end;
  finally
    LVisitas.Free;
  end;
end;

procedure TFrmVisitantes.MostrarDialogFinalizacao(AVisitaId: Integer);
var
  LDialog: TForm;
  LLayout: TLayout;
  LLbl: TLabel;
  LLblTicket, LLblConsumo, LLblExtra, LLblTotal: TLabel;
  LCmbPagamento: TComboBox;
  LBtnConfirmar: TButton;
  LBtnCancelar: TButton;
  LItem: TListBoxItem;
  LVisitas: TObjectList<TVisita>;
  LVisita: TVisita;
  I: Integer;
  LVisitaEncontrada: Boolean;
  LValorExtra, LValorTotal: Currency;
  LTicket: TTicket;
  LMinutosExtra: Integer;
begin
  // Encontrar a visita pelo ID
  LVisitaEncontrada := False;
  LVisitas := FController.VisitasAbertas;
  try
    for I := 0 to LVisitas.Count - 1 do
    begin
      if LVisitas[I].Id = AVisitaId then
      begin
        LVisita := LVisitas[I];
        LVisitaEncontrada := True;
        Break;
      end;
    end;

    if not LVisitaEncontrada then
    begin
      TDialogService.ShowMessage('Visita nao encontrada.');
      Exit;
    end;

    // Calcular tempo extra
    LValorExtra := 0;
    if Now > LVisita.Hora_Prevista_Saida then
    begin
      // Buscar ticket para calcular
      LTicket := nil;
      for I := 0 to FMockTickets.Count - 1 do
      begin
        if FMockTickets[I].Id = LVisita.Ticket_Id then
        begin
          LTicket := FMockTickets[I];
          Break;
        end;
      end;

      if Assigned(LTicket) and (not SameText(LTicket.Tipo, 'DAY_PASS')) then
      begin
        LMinutosExtra := MinutesBetween(Now, LVisita.Hora_Prevista_Saida);
        if LTicket.Duracao_Minutos > 0 then
          LValorExtra := LMinutosExtra * (LVisita.Valor_Ticket / LTicket.Duracao_Minutos);
      end;
    end;

    LValorTotal := LVisita.Valor_Ticket + LVisita.Valor_Consumo + LValorExtra;

    // Criar dialog de finalizacao
    LDialog := TForm.CreateNew(Self);
    try
      LDialog.Caption := 'Finalizar Visita';
      LDialog.ClientWidth := 420;
      LDialog.ClientHeight := 380;
      LDialog.Position := TFormPosition.MainFormCenter;
      LDialog.BorderStyle := TFmxFormBorderStyle.ToolWindow;

      LLayout := TLayout.Create(LDialog);
      LLayout.Parent := LDialog;
      LLayout.Align := TAlignLayout.Client;
      LLayout.Padding.Left := 16;
      LLayout.Padding.Right := 16;
      LLayout.Padding.Top := 16;
      LLayout.Padding.Bottom := 16;

      // Titulo
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 0;
      LLbl.Width := 380;
      LLbl.Height := 28;
      LLbl.Text := 'Finalizar Visita #' + IntToStr(AVisitaId);
      LLbl.StyledSettings := [];
      LLbl.TextSettings.Font.Size := 18;
      LLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
      LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Valor Ticket
      LLblTicket := TLabel.Create(LDialog);
      LLblTicket.Parent := LLayout;
      LLblTicket.Position.X := 0;
      LLblTicket.Position.Y := 40;
      LLblTicket.Width := 380;
      LLblTicket.Height := 24;
      LLblTicket.Text := Format('Ticket: R$ %.2f', [LVisita.Valor_Ticket]);
      LLblTicket.StyledSettings := [];
      LLblTicket.TextSettings.Font.Size := 14;
      LLblTicket.TextSettings.FontColor := COR_TEXTO_MEDIO;

      // Valor Consumo
      LLblConsumo := TLabel.Create(LDialog);
      LLblConsumo.Parent := LLayout;
      LLblConsumo.Position.X := 0;
      LLblConsumo.Position.Y := 68;
      LLblConsumo.Width := 380;
      LLblConsumo.Height := 24;
      LLblConsumo.Text := Format('Consumo: R$ %.2f', [LVisita.Valor_Consumo]);
      LLblConsumo.StyledSettings := [];
      LLblConsumo.TextSettings.Font.Size := 14;
      LLblConsumo.TextSettings.FontColor := COR_TEXTO_MEDIO;

      // Valor Tempo Extra
      LLblExtra := TLabel.Create(LDialog);
      LLblExtra.Parent := LLayout;
      LLblExtra.Position.X := 0;
      LLblExtra.Position.Y := 96;
      LLblExtra.Width := 380;
      LLblExtra.Height := 24;
      LLblExtra.Text := Format('Tempo Extra: R$ %.2f', [LValorExtra]);
      LLblExtra.StyledSettings := [];
      LLblExtra.TextSettings.Font.Size := 14;
      LLblExtra.TextSettings.FontColor := COR_VERMELHO;

      // Separador
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 124;
      LLbl.Width := 380;
      LLbl.Height := 2;
      LLbl.Text := '________________________________________';
      LLbl.StyledSettings := [];
      LLbl.TextSettings.FontColor := COR_CARD_BORDER;

      // Valor Total
      LLblTotal := TLabel.Create(LDialog);
      LLblTotal.Parent := LLayout;
      LLblTotal.Position.X := 0;
      LLblTotal.Position.Y := 140;
      LLblTotal.Width := 380;
      LLblTotal.Height := 30;
      LLblTotal.Text := Format('TOTAL: R$ %.2f', [LValorTotal]);
      LLblTotal.StyledSettings := [];
      LLblTotal.TextSettings.Font.Size := 20;
      LLblTotal.TextSettings.Font.Style := [TFontStyle.fsBold];
      LLblTotal.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Label forma pagamento
      LLbl := TLabel.Create(LDialog);
      LLbl.Parent := LLayout;
      LLbl.Position.X := 0;
      LLbl.Position.Y := 185;
      LLbl.Width := 380;
      LLbl.Height := 20;
      LLbl.Text := 'Forma de Pagamento:';
      LLbl.StyledSettings := [];
      LLbl.TextSettings.Font.Size := 12;
      LLbl.TextSettings.FontColor := COR_TEXTO_ESCURO;

      // Combo forma pagamento
      LCmbPagamento := TComboBox.Create(LDialog);
      LCmbPagamento.Parent := LLayout;
      LCmbPagamento.Position.X := 0;
      LCmbPagamento.Position.Y := 208;
      LCmbPagamento.Width := 380;
      LCmbPagamento.Height := 32;

      LItem := TListBoxItem.Create(LCmbPagamento);
      LItem.Text := 'DINHEIRO';
      LCmbPagamento.AddObject(LItem);

      LItem := TListBoxItem.Create(LCmbPagamento);
      LItem.Text := 'DEBITO';
      LCmbPagamento.AddObject(LItem);

      LItem := TListBoxItem.Create(LCmbPagamento);
      LItem.Text := 'CREDITO';
      LCmbPagamento.AddObject(LItem);

      LItem := TListBoxItem.Create(LCmbPagamento);
      LItem.Text := 'PIX';
      LCmbPagamento.AddObject(LItem);

      LCmbPagamento.ItemIndex := 0;

      // Botao Confirmar Pagamento
      LBtnConfirmar := TButton.Create(LDialog);
      LBtnConfirmar.Parent := LLayout;
      LBtnConfirmar.Position.X := 0;
      LBtnConfirmar.Position.Y := 270;
      LBtnConfirmar.Width := 185;
      LBtnConfirmar.Height := 48;
      LBtnConfirmar.Text := 'Confirmar Pagamento';
      LBtnConfirmar.StyledSettings := [];
      LBtnConfirmar.TextSettings.Font.Size := 14;
      LBtnConfirmar.TextSettings.Font.Style := [TFontStyle.fsBold];
      LBtnConfirmar.ModalResult := mrOk;

      // Botao Cancelar
      LBtnCancelar := TButton.Create(LDialog);
      LBtnCancelar.Parent := LLayout;
      LBtnCancelar.Position.X := 195;
      LBtnCancelar.Position.Y := 270;
      LBtnCancelar.Width := 185;
      LBtnCancelar.Height := 48;
      LBtnCancelar.Text := 'Cancelar';
      LBtnCancelar.StyledSettings := [];
      LBtnCancelar.TextSettings.Font.Size := 14;
      LBtnCancelar.ModalResult := mrCancel;

      // Mostrar dialog modal
      if LDialog.ShowModal = mrOk then
      begin
        if LCmbPagamento.ItemIndex >= 0 then
        begin
          try
            // Setar a entidade do controller para a visita correta
            FController.Entidade.Id := AVisitaId;
            FController.Entidade.Tutor_Id := LVisita.Tutor_Id;
            FController.Entidade.Visitante_Id := LVisita.Visitante_Id;
            FController.Entidade.Ticket_Id := LVisita.Ticket_Id;
            FController.Entidade.Caixa_Id := LVisita.Caixa_Id;
            FController.Entidade.Hora_Entrada := LVisita.Hora_Entrada;
            FController.Entidade.Hora_Prevista_Saida := LVisita.Hora_Prevista_Saida;
            FController.Entidade.Valor_Ticket := LVisita.Valor_Ticket;
            FController.Entidade.Valor_Consumo := LVisita.Valor_Consumo;
            FController.Entidade.Status := LVisita.Status;
            FController.Entidade.Status_Pagamento := LVisita.Status_Pagamento;

            FController.FinalizarVisita(
              LCmbPagamento.ListItems[LCmbPagamento.ItemIndex].Text
            );
            TDialogService.ShowMessage(
              Format('Visita finalizada! Total cobrado: R$ %.2f', [LValorTotal]));
            AtualizarVisitasAtivas;
          except
            on E: Exception do
              TDialogService.ShowMessage('Erro: ' + E.Message);
          end;
        end;
      end;
    finally
      LDialog.Free;
    end;
  finally
    LVisitas.Free;
  end;
end;

procedure TFrmVisitantes.AtualizarVisitasAtivas;
var
  LVisitas: TObjectList<TVisita>;
  I: Integer;
begin
  LimparCardsVisitas;

  LVisitas := FController.VisitasAbertas;
  try
    // Atualizar titulo com contagem
    FLblVisitasTitle.Text := Format('Visitas Ativas (%d)', [LVisitas.Count]);

    for I := 0 to LVisitas.Count - 1 do
      CriarCardVisita(LVisitas[I]);
  finally
    LVisitas.Free;
  end;
end;

procedure TFrmVisitantes.LimparCardsVisitas;
var
  I: Integer;
begin
  // Remover cards antigos do scroll
  for I := FVisitaCards.Count - 1 downto 0 do
  begin
    if Assigned(FVisitaCards[I].Layout) then
      FVisitaCards[I].Layout.Free;
  end;
  FVisitaCards.Clear;
end;

procedure TFrmVisitantes.CriarCardVisita(AVisita: TVisita);
var
  LCard: TVisitaCard;
  LLayout: TLayout;
  LRect: TRectangle;
  LLblNomeCrianca, LLblNomeTutor, LLblTimer, LLblConsumo: TLabel;
  LBtnFinalizar, LBtnConsumo: TButton;
  LNomeCrianca, LNomeTutor: string;
  I: Integer;
  LCardIndex: Integer;
begin
  // Buscar nome da crianca e tutor
  LNomeCrianca := 'Crianca #' + IntToStr(AVisita.Visitante_Id);
  LNomeTutor := 'Tutor #' + IntToStr(AVisita.Tutor_Id);

  for I := 0 to FMockVisitantes.Count - 1 do
  begin
    if FMockVisitantes[I].Id = AVisita.Visitante_Id then
    begin
      LNomeCrianca := FMockVisitantes[I].Nome;
      Break;
    end;
  end;

  for I := 0 to FMockTutores.Count - 1 do
  begin
    if FMockTutores[I].Id = AVisita.Tutor_Id then
    begin
      LNomeTutor := FMockTutores[I].Nome;
      Break;
    end;
  end;

  LCardIndex := FVisitaCards.Count;

  // Layout do card
  LLayout := TLayout.Create(Self);
  LLayout.Parent := FScrollVisitas;
  LLayout.Align := TAlignLayout.Top;
  LLayout.Height := CARD_HEIGHT;
  LLayout.Margins.Left := CARD_MARGIN;
  LLayout.Margins.Right := CARD_MARGIN;
  LLayout.Margins.Top := CARD_MARGIN;
  LLayout.Position.Y := LCardIndex * (CARD_HEIGHT + CARD_MARGIN);

  // Fundo do card com borda colorida
  LRect := TRectangle.Create(Self);
  LRect.Parent := LLayout;
  LRect.Align := TAlignLayout.Client;
  LRect.Fill.Kind := TBrushKind.Solid;
  LRect.Fill.Color := COR_CARD_BG;
  LRect.Stroke.Kind := TBrushKind.Solid;
  LRect.Stroke.Color := COR_VERDE;
  LRect.Stroke.Thickness := 3;
  LRect.XRadius := 8;
  LRect.YRadius := 8;
  LRect.HitTest := False;

  // Nome da crianca
  LLblNomeCrianca := TLabel.Create(Self);
  LLblNomeCrianca.Parent := LLayout;
  LLblNomeCrianca.Position.X := 12;
  LLblNomeCrianca.Position.Y := 8;
  LLblNomeCrianca.Width := 250;
  LLblNomeCrianca.Height := 24;
  LLblNomeCrianca.Text := LNomeCrianca;
  LLblNomeCrianca.StyledSettings := [];
  LLblNomeCrianca.TextSettings.Font.Size := 16;
  LLblNomeCrianca.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLblNomeCrianca.TextSettings.FontColor := COR_TEXTO_ESCURO;

  // Nome do tutor
  LLblNomeTutor := TLabel.Create(Self);
  LLblNomeTutor.Parent := LLayout;
  LLblNomeTutor.Position.X := 12;
  LLblNomeTutor.Position.Y := 32;
  LLblNomeTutor.Width := 250;
  LLblNomeTutor.Height := 20;
  LLblNomeTutor.Text := 'Tutor: ' + LNomeTutor;
  LLblNomeTutor.StyledSettings := [];
  LLblNomeTutor.TextSettings.Font.Size := 12;
  LLblNomeTutor.TextSettings.FontColor := COR_TEXTO_MEDIO;

  // Timer countdown
  LLblTimer := TLabel.Create(Self);
  LLblTimer.Parent := LLayout;
  LLblTimer.Position.X := 12;
  LLblTimer.Position.Y := 58;
  LLblTimer.Width := 200;
  LLblTimer.Height := 28;
  LLblTimer.Text := '00:00:00';
  LLblTimer.StyledSettings := [];
  LLblTimer.TextSettings.Font.Size := 22;
  LLblTimer.TextSettings.Font.Style := [TFontStyle.fsBold];
  LLblTimer.TextSettings.FontColor := COR_VERDE;

  // Badge consumo
  LLblConsumo := TLabel.Create(Self);
  LLblConsumo.Parent := LLayout;
  LLblConsumo.Position.X := 12;
  LLblConsumo.Position.Y := 90;
  LLblConsumo.Width := 200;
  LLblConsumo.Height := 20;
  LLblConsumo.Text := Format('Consumo: R$ %.2f', [AVisita.Valor_Consumo]);
  LLblConsumo.StyledSettings := [];
  LLblConsumo.TextSettings.Font.Size := 12;
  LLblConsumo.TextSettings.FontColor := COR_BADGE_BG;

  // Botao Consumo (direita superior)
  LBtnConsumo := TButton.Create(Self);
  LBtnConsumo.Parent := LLayout;
  LBtnConsumo.Position.X := LLayout.Width - 220;
  LBtnConsumo.Position.Y := 12;
  LBtnConsumo.Width := 96;
  LBtnConsumo.Height := 40;
  LBtnConsumo.Text := 'Consumo';
  LBtnConsumo.Tag := AVisita.Id;
  LBtnConsumo.StyledSettings := [];
  LBtnConsumo.TextSettings.Font.Size := 12;
  LBtnConsumo.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  LBtnConsumo.OnClick := BtnConsumoClick;

  // Botao Finalizar (direita inferior)
  LBtnFinalizar := TButton.Create(Self);
  LBtnFinalizar.Parent := LLayout;
  LBtnFinalizar.Position.X := LLayout.Width - 116;
  LBtnFinalizar.Position.Y := 12;
  LBtnFinalizar.Width := 96;
  LBtnFinalizar.Height := 40;
  LBtnFinalizar.Text := 'Finalizar';
  LBtnFinalizar.Tag := AVisita.Id;
  LBtnFinalizar.StyledSettings := [];
  LBtnFinalizar.TextSettings.Font.Size := 12;
  LBtnFinalizar.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  LBtnFinalizar.OnClick := BtnFinalizarClick;

  // Montar registro do card
  LCard.VisitaId := AVisita.Id;
  LCard.NomeCrianca := LNomeCrianca;
  LCard.NomeTutor := LNomeTutor;
  LCard.HoraPrevistaSaida := AVisita.Hora_Prevista_Saida;
  LCard.ValorConsumo := AVisita.Valor_Consumo;
  LCard.TicketId := AVisita.Ticket_Id;
  LCard.VisitanteId := AVisita.Visitante_Id;
  LCard.Layout := LLayout;
  LCard.LblNomeCrianca := LLblNomeCrianca;
  LCard.LblNomeTutor := LLblNomeTutor;
  LCard.LblTimer := LLblTimer;
  LCard.LblConsumo := LLblConsumo;
  LCard.RectFundo := LRect;

  FVisitaCards.Add(LCard);
end;

procedure TFrmVisitantes.PreencherComboCriancas(ATutorId: Integer);
var
  I: Integer;
  LItem: TListBoxItem;
begin
  FCmbCrianca.Clear;

  for I := 0 to FMockVisitantes.Count - 1 do
  begin
    if FMockVisitantes[I].Tutor_Id = ATutorId then
    begin
      LItem := TListBoxItem.Create(FCmbCrianca);
      LItem.Text := FMockVisitantes[I].Nome;
      LItem.Tag := FMockVisitantes[I].Id;
      FCmbCrianca.AddObject(LItem);
    end;
  end;

  if FCmbCrianca.Count > 0 then
    FCmbCrianca.ItemIndex := 0;
end;

procedure TFrmVisitantes.PreencherComboTickets;
var
  I: Integer;
  LItem: TListBoxItem;
begin
  FCmbTicket.Clear;

  for I := 0 to FMockTickets.Count - 1 do
  begin
    LItem := TListBoxItem.Create(FCmbTicket);
    LItem.Text := FMockTickets[I].Nome + ' - R$ ' +
      FormatFloat('0.00', FMockTickets[I].Preco);
    LItem.Tag := FMockTickets[I].Id;
    FCmbTicket.AddObject(LItem);
  end;
end;

procedure TFrmVisitantes.LimparCamposNovaEntrada;
begin
  FEdtCPF.Text := '';
  FEdtTutorNome.Text := '';
  FEdtTutorTelefone.Text := '';
  FLblTutorId.Text := '0';
  FCmbCrianca.Clear;
  FCmbTicket.ItemIndex := -1;
end;

end.
