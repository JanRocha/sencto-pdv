unit Frm.Festas;

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
  FMX.Layouts,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.Graphics,
  FMX.Edit,
  FMX.ListBox,
  FMX.ScrollBox,
  Controller.Festa,
  Model.Entidade.Festa,
  Model.Entidade.PacoteFesta,
  Model.Entidade.Tutor,
  Mock.DAO;

type
  /// <summary>
  /// Status visual de um dia no calendário de festas.
  /// </summary>
  TDiaStatus = (dsLivre, dsParcial, dsOcupado);

  /// <summary>
  /// Tela de Festas com:
  ///   - Calendário mensal com indicação de disponibilidade (verde/amarelo/vermelho)
  ///   - Formulário de agendamento (modal via painel overlay)
  ///   - Lista de festas do mês com ações (ver, editar, cancelar)
  ///   - Cards de estatísticas (festas no mês, receita estimada, pacote top)
  /// Touch-friendly: botões 48px+, fontes 14pt+, feedback visual <100ms.
  /// Usa Controller.Festa com dados MOCK.
  /// </summary>
  TFrmFestas = class(TForm)
  private
    FController: TControllerFesta;
    FDAOTutor: IDAO<TTutor>;

    { Estado do calendário }
    FMesAtual: Word;
    FAnoAtual: Word;
    FDiaSelecionado: Word;

    { Mock data }
    FPacotesMock: TObjectList<TPacoteFesta>;
    FTutoresMock: TObjectList<TTutor>;

    { Layout principal }
    FLayoutPrincipal: TLayout;

    { Stats cards (top) }
    FLayoutStats: TLayout;
    FRectStatFestas: TRectangle;
    FLblStatFestasTitle: TLabel;
    FLblStatFestasValue: TLabel;
    FRectStatReceita: TRectangle;
    FLblStatReceitaTitle: TLabel;
    FLblStatReceitaValue: TLabel;
    FRectStatPacote: TRectangle;
    FLblStatPacoteTitle: TLabel;
    FLblStatPacoteValue: TLabel;

    { Calendar panel (left) }
    FLayoutCalendar: TLayout;
    FRectCalendarBg: TRectangle;
    FLayoutCalendarHeader: TLayout;
    FBtnMesAnterior: TButton;
    FLblMesAno: TLabel;
    FBtnMesProximo: TButton;
    FLayoutDiasSemana: TLayout;
    FLayoutGridDias: TLayout;
    FDiaCells: array[0..41] of TRectangle;
    FDiaLabels: array[0..41] of TLabel;

    { Party list (bottom-right) }
    FLayoutListArea: TLayout;
    FRectListBg: TRectangle;
    FLblListTitle: TLabel;
    FBtnNovaFesta: TButton;
    FLayoutListHeader: TLayout;
    FLayoutListContent: TLayout;
    FScrollListContent: TVertScrollBox;

    { Scheduling form (overlay panel) }
    FLayoutOverlay: TLayout;
    FRectOverlayBg: TRectangle;
    FLayoutFormPanel: TLayout;
    FRectFormBg: TRectangle;
    FLblFormTitle: TLabel;
    FEdtNomeAniversariante: TEdit;
    FEdtTutorNome: TEdit;
    FEdtTutorCPF: TEdit;
    FEdtTutorEmail: TEdit;
    FEdtTutorTelefone: TEdit;
    FEdtTutorEndereco: TEdit;
    FEdtDataFesta: TEdit;
    FCmbSlot: TComboBox;
    FCmbPacote: TComboBox;
    FLblValorCalculado: TLabel;
    FEdtValorPago: TEdit;
    FBtnSalvarReceber: TButton;
    FBtnCancelarForm: TButton;

    { Cancel reason modal }
    FLayoutCancelModal: TLayout;
    FRectCancelBg: TRectangle;
    FLayoutCancelPanel: TLayout;
    FRectCancelPanelBg: TRectangle;
    FLblCancelTitle: TLabel;
    FEdtCancelMotivo: TEdit;
    FBtnConfirmarCancel: TButton;
    FBtnFecharCancel: TButton;
    FFestaParaCancelar: Integer;

    { Editing state }
    FEditandoFestaId: Integer;

    { Initialization }
    procedure CriarMockData;
    procedure CriarComponentes;
    procedure CriarStats;
    procedure CriarCalendario;
    procedure CriarListaFestas;
    procedure CriarFormularioAgendamento;
    procedure CriarCancelModal;

    { Calendar logic }
    procedure AtualizarCalendario;
    function ObterStatusDia(ADia: Word): TDiaStatus;
    procedure DiaCellClick(Sender: TObject);
    procedure BtnMesAnteriorClick(Sender: TObject);
    procedure BtnMesProximoClick(Sender: TObject);

    { List logic }
    procedure AtualizarListaFestas;
    procedure AtualizarStats;

    { Form logic }
    procedure MostrarFormulario(AFestaId: Integer = 0);
    procedure OcultarFormulario;
    procedure BtnNovaFestaClick(Sender: TObject);
    procedure BtnSalvarReceberClick(Sender: TObject);
    procedure BtnCancelarFormClick(Sender: TObject);
    procedure AtualizarSlotsDisponiveis;
    procedure AtualizarValorCalculado;
    procedure CmbPacoteChange(Sender: TObject);
    procedure EdtDataFestaChange(Sender: TObject);

    { Cancel logic }
    procedure MostrarCancelModal(AFestaId: Integer);
    procedure OcultarCancelModal;
    procedure BtnConfirmarCancelClick(Sender: TObject);
    procedure BtnFecharCancelClick(Sender: TObject);

    { List row action handlers }
    procedure BtnVerFestaClick(Sender: TObject);
    procedure BtnCancelarFestaClick(Sender: TObject);

    { Touch feedback }
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    { Helpers }
    function NomeMes(AMes: Word): string;
    function ParseDataEdit(const ATexto: string): TDate;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

const
  COR_VERDE = $FF4CAF50;      // Livre
  COR_AMARELO = $FFFFC107;    // Parcial
  COR_VERMELHO = $FFF44336;   // Ocupado
  COR_BRANCO = $FFFFFFFF;
  COR_CINZA_CLARO = $FFF5F5F5;
  COR_CINZA_MEDIO = $FFE0E0E0;
  COR_CINZA_ESCURO = $FF616161;
  COR_AZUL_PRIMARIO = $FF1565C0;
  COR_AZUL_CLARO = $FF42A5F5;
  COR_TEXTO_ESCURO = $FF212121;
  COR_OVERLAY = $AA000000;
  COR_CARD_BG = $FFFFFFFF;

  STAT_CARD_HEIGHT = 80;
  CALENDAR_WIDTH = 340;
  CELL_SIZE = 44;
  BTN_MIN_SIZE = 48;

{ TFrmFestas }

constructor TFrmFestas.Create(AOwner: TComponent);
var
  LAno, LMes, LDia: Word;
begin
  inherited CreateNew(AOwner);

  Caption := 'Festas - Agendamento';
  ClientWidth := 1024;
  ClientHeight := 700;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := COR_CINZA_CLARO;

  FController := TControllerFesta.Create;
  FDAOTutor := TMockDAO<TTutor>.Create;
  FPacotesMock := TObjectList<TPacoteFesta>.Create(True);
  FTutoresMock := TObjectList<TTutor>.Create(True);

  DecodeDate(Date, LAno, LMes, LDia);
  FAnoAtual := LAno;
  FMesAtual := LMes;
  FDiaSelecionado := LDia;
  FEditandoFestaId := 0;
  FFestaParaCancelar := 0;

  CriarMockData;
  CriarComponentes;
  AtualizarCalendario;
  AtualizarListaFestas;
  AtualizarStats;
end;

destructor TFrmFestas.Destroy;
begin
  FPacotesMock.Free;
  FTutoresMock.Free;
  FController.Free;
  inherited Destroy;
end;

procedure TFrmFestas.CriarMockData;
var
  LPacote: TPacoteFesta;
  LTutor: TTutor;
  LFesta: TFesta;
  LDataBase: TDate;
  LDiaSemana: Word;
begin
  // --- Pacotes Mock ---
  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Aventura';
  LPacote.Max_Convidados := 20;
  LPacote.Preco_Semana := 1500.00;
  LPacote.Preco_FDS := 2200.00;
  LPacote.Descricao := 'Inclui decoração temática, lanche e 2h de diversão';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);
  FPacotesMock.Add(LPacote);

  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Fantasia';
  LPacote.Max_Convidados := 35;
  LPacote.Preco_Semana := 2500.00;
  LPacote.Preco_FDS := 3500.00;
  LPacote.Descricao := 'Pacote completo com buffet, DJ e personagens';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);
  FPacotesMock.Add(LPacote);

  LPacote := TPacoteFesta.Create;
  LPacote.Nome := 'Pacote Mini';
  LPacote.Max_Convidados := 10;
  LPacote.Preco_Semana := 800.00;
  LPacote.Preco_FDS := 1200.00;
  LPacote.Descricao := 'Festinha íntima com bolo e salgados';
  LPacote.Situacao := 1;
  FController.DAOPacote.Save(LPacote);
  FPacotesMock.Add(LPacote);

  // --- Tutores Mock ---
  LTutor := TTutor.Create;
  LTutor.Nome := 'Maria Silva';
  LTutor.CPF := '12345678901';
  LTutor.Telefone := '11999887766';
  LTutor.Email := 'maria@email.com';
  LTutor.Endereco := 'Rua das Flores, 123';
  FDAOTutor.Save(LTutor);
  FTutoresMock.Add(LTutor);

  LTutor := TTutor.Create;
  LTutor.Nome := 'João Oliveira';
  LTutor.CPF := '98765432100';
  LTutor.Telefone := '11988776655';
  LTutor.Email := 'joao@email.com';
  LTutor.Endereco := 'Av. Brasil, 456';
  FDAOTutor.Save(LTutor);
  FTutoresMock.Add(LTutor);

  // --- Festas Mock (no mês atual) ---
  // Festa 1: próximo dia útil (terça a sábado), slot da tarde
  LDataBase := Date + 3;
  LDiaSemana := DayOfWeek(LDataBase);
  // Garantir que cai em dia útil (Seg-Sáb)
  if LDiaSemana = 1 then // domingo -> avança para segunda
    LDataBase := LDataBase + 1;

  FController.Entidade.Nome_Aniversariante := 'Pedro Silva';
  FController.Entidade.Tutor_Id := 1;
  FController.Entidade.Data_Festa := LDataBase;
  FController.Entidade.Horario_Slot := '14:00 às 16:30';
  FController.Entidade.Pacote_Id := 1;
  FController.Entidade.Num_Convidados := 15;
  FController.AgendarFesta;

  // Festa 2: fim de semana (sábado), slot noturno
  LDataBase := Date + 7;
  LDiaSemana := DayOfWeek(LDataBase);
  // Ajustar para sábado
  case LDiaSemana of
    1: LDataBase := LDataBase + 6; // Dom -> Sáb
    2: LDataBase := LDataBase + 5; // Seg -> Sáb
    3: LDataBase := LDataBase + 4; // Ter -> Sáb
    4: LDataBase := LDataBase + 3; // Qua -> Sáb
    5: LDataBase := LDataBase + 2; // Qui -> Sáb
    6: LDataBase := LDataBase + 1; // Sex -> Sáb
    7: ; // Já é sábado
  end;

  // Criar nova entidade para festa 2
  FController.Entidade.Free;
  FController.Entidade := TFesta.Create;
  FController.Entidade.Nome_Aniversariante := 'Ana Oliveira';
  FController.Entidade.Tutor_Id := 2;
  FController.Entidade.Data_Festa := LDataBase;
  FController.Entidade.Horario_Slot := '19:00 às 21:30';
  FController.Entidade.Pacote_Id := 2;
  FController.Entidade.Num_Convidados := 30;
  FController.AgendarFesta;

  // Reset entidade para novo uso
  FController.Entidade.Free;
  FController.Entidade := TFesta.Create;
end;

procedure TFrmFestas.CriarComponentes;
begin
  FLayoutPrincipal := TLayout.Create(Self);
  FLayoutPrincipal.Parent := Self;
  FLayoutPrincipal.Align := TAlignLayout.Client;
  FLayoutPrincipal.Padding.Left := 12;
  FLayoutPrincipal.Padding.Right := 12;
  FLayoutPrincipal.Padding.Top := 12;
  FLayoutPrincipal.Padding.Bottom := 12;

  CriarStats;
  CriarCalendario;
  CriarListaFestas;
  CriarFormularioAgendamento;
  CriarCancelModal;
end;

procedure TFrmFestas.CriarStats;
  function CriarStatCard(AParent: TFmxObject; ALeft: Single;
    const ATitle: string; out ALblTitle, ALblValue: TLabel): TRectangle;
  begin
    Result := TRectangle.Create(Self);
    Result.Parent := AParent;
    Result.Position.X := ALeft;
    Result.Position.Y := 4;
    Result.Width := 200;
    Result.Height := STAT_CARD_HEIGHT - 8;
    Result.Fill.Kind := TBrushKind.Solid;
    Result.Fill.Color := COR_CARD_BG;
    Result.Stroke.Color := COR_CINZA_MEDIO;
    Result.XRadius := 8;
    Result.YRadius := 8;

    ALblTitle := TLabel.Create(Self);
    ALblTitle.Parent := Result;
    ALblTitle.Align := TAlignLayout.Top;
    ALblTitle.Height := 28;
    ALblTitle.Margins.Left := 12;
    ALblTitle.Margins.Top := 8;
    ALblTitle.Text := ATitle;
    ALblTitle.StyledSettings := [];
    ALblTitle.TextSettings.Font.Size := 12;
    ALblTitle.TextSettings.FontColor := COR_CINZA_ESCURO;
    ALblTitle.TextSettings.HorzAlign := TTextAlign.Leading;

    ALblValue := TLabel.Create(Self);
    ALblValue.Parent := Result;
    ALblValue.Align := TAlignLayout.Client;
    ALblValue.Margins.Left := 12;
    ALblValue.Text := '0';
    ALblValue.StyledSettings := [];
    ALblValue.TextSettings.Font.Size := 22;
    ALblValue.TextSettings.Font.Style := [TFontStyle.fsBold];
    ALblValue.TextSettings.FontColor := COR_AZUL_PRIMARIO;
    ALblValue.TextSettings.HorzAlign := TTextAlign.Leading;
    ALblValue.TextSettings.VertAlign := TTextAlign.Center;
  end;

begin
  FLayoutStats := TLayout.Create(Self);
  FLayoutStats.Parent := FLayoutPrincipal;
  FLayoutStats.Align := TAlignLayout.Top;
  FLayoutStats.Height := STAT_CARD_HEIGHT;
  FLayoutStats.Margins.Bottom := 8;

  FRectStatFestas := CriarStatCard(FLayoutStats, 0,
    'Festas este mês', FLblStatFestasTitle, FLblStatFestasValue);
  FRectStatReceita := CriarStatCard(FLayoutStats, 210,
    'Receita estimada', FLblStatReceitaTitle, FLblStatReceitaValue);
  FRectStatPacote := CriarStatCard(FLayoutStats, 420,
    'Pacote mais reservado', FLblStatPacoteTitle, FLblStatPacoteValue);
end;

procedure TFrmFestas.CriarCalendario;
var
  I: Integer;
  LCol, LRow: Integer;
  LDiaSemanaLabel: TLabel;
  LNomesDias: array[0..6] of string;
begin
  LNomesDias[0] := 'Dom';
  LNomesDias[1] := 'Seg';
  LNomesDias[2] := 'Ter';
  LNomesDias[3] := 'Qua';
  LNomesDias[4] := 'Qui';
  LNomesDias[5] := 'Sex';
  LNomesDias[6] := 'Sáb';

  FLayoutCalendar := TLayout.Create(Self);
  FLayoutCalendar.Parent := FLayoutPrincipal;
  FLayoutCalendar.Align := TAlignLayout.Left;
  FLayoutCalendar.Width := CALENDAR_WIDTH;
  FLayoutCalendar.Margins.Right := 8;

  FRectCalendarBg := TRectangle.Create(Self);
  FRectCalendarBg.Parent := FLayoutCalendar;
  FRectCalendarBg.Align := TAlignLayout.Client;
  FRectCalendarBg.Fill.Kind := TBrushKind.Solid;
  FRectCalendarBg.Fill.Color := COR_CARD_BG;
  FRectCalendarBg.Stroke.Color := COR_CINZA_MEDIO;
  FRectCalendarBg.XRadius := 8;
  FRectCalendarBg.YRadius := 8;
  FRectCalendarBg.HitTest := False;

  // Header: < MesAno >
  FLayoutCalendarHeader := TLayout.Create(Self);
  FLayoutCalendarHeader.Parent := FLayoutCalendar;
  FLayoutCalendarHeader.Align := TAlignLayout.Top;
  FLayoutCalendarHeader.Height := 48;
  FLayoutCalendarHeader.Margins.Left := 8;
  FLayoutCalendarHeader.Margins.Right := 8;

  FBtnMesAnterior := TButton.Create(Self);
  FBtnMesAnterior.Parent := FLayoutCalendarHeader;
  FBtnMesAnterior.Align := TAlignLayout.Left;
  FBtnMesAnterior.Width := BTN_MIN_SIZE;
  FBtnMesAnterior.Text := '<';
  FBtnMesAnterior.StyledSettings := [];
  FBtnMesAnterior.TextSettings.Font.Size := 18;
  FBtnMesAnterior.OnClick := BtnMesAnteriorClick;
  FBtnMesAnterior.OnMouseDown := BtnMouseDown;
  FBtnMesAnterior.OnMouseUp := BtnMouseUp;

  FBtnMesProximo := TButton.Create(Self);
  FBtnMesProximo.Parent := FLayoutCalendarHeader;
  FBtnMesProximo.Align := TAlignLayout.Right;
  FBtnMesProximo.Width := BTN_MIN_SIZE;
  FBtnMesProximo.Text := '>';
  FBtnMesProximo.StyledSettings := [];
  FBtnMesProximo.TextSettings.Font.Size := 18;
  FBtnMesProximo.OnClick := BtnMesProximoClick;
  FBtnMesProximo.OnMouseDown := BtnMouseDown;
  FBtnMesProximo.OnMouseUp := BtnMouseUp;

  FLblMesAno := TLabel.Create(Self);
  FLblMesAno.Parent := FLayoutCalendarHeader;
  FLblMesAno.Align := TAlignLayout.Client;
  FLblMesAno.Text := '';
  FLblMesAno.StyledSettings := [];
  FLblMesAno.TextSettings.Font.Size := 16;
  FLblMesAno.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblMesAno.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblMesAno.TextSettings.HorzAlign := TTextAlign.Center;
  FLblMesAno.TextSettings.VertAlign := TTextAlign.Center;

  // Dias da semana labels
  FLayoutDiasSemana := TLayout.Create(Self);
  FLayoutDiasSemana.Parent := FLayoutCalendar;
  FLayoutDiasSemana.Align := TAlignLayout.Top;
  FLayoutDiasSemana.Height := 28;
  FLayoutDiasSemana.Margins.Left := 8;
  FLayoutDiasSemana.Margins.Right := 8;

  for I := 0 to 6 do
  begin
    LDiaSemanaLabel := TLabel.Create(Self);
    LDiaSemanaLabel.Parent := FLayoutDiasSemana;
    LDiaSemanaLabel.Position.X := I * CELL_SIZE;
    LDiaSemanaLabel.Position.Y := 0;
    LDiaSemanaLabel.Width := CELL_SIZE;
    LDiaSemanaLabel.Height := 28;
    LDiaSemanaLabel.Text := LNomesDias[I];
    LDiaSemanaLabel.StyledSettings := [];
    LDiaSemanaLabel.TextSettings.Font.Size := 11;
    LDiaSemanaLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
    LDiaSemanaLabel.TextSettings.FontColor := COR_CINZA_ESCURO;
    LDiaSemanaLabel.TextSettings.HorzAlign := TTextAlign.Center;
    LDiaSemanaLabel.TextSettings.VertAlign := TTextAlign.Center;
  end;

  // Grid de dias (7 colunas x 6 linhas = 42 cells)
  FLayoutGridDias := TLayout.Create(Self);
  FLayoutGridDias.Parent := FLayoutCalendar;
  FLayoutGridDias.Align := TAlignLayout.Top;
  FLayoutGridDias.Height := 6 * CELL_SIZE;
  FLayoutGridDias.Margins.Left := 8;
  FLayoutGridDias.Margins.Right := 8;

  for I := 0 to 41 do
  begin
    LCol := I mod 7;
    LRow := I div 7;

    FDiaCells[I] := TRectangle.Create(Self);
    FDiaCells[I].Parent := FLayoutGridDias;
    FDiaCells[I].Position.X := LCol * CELL_SIZE;
    FDiaCells[I].Position.Y := LRow * CELL_SIZE;
    FDiaCells[I].Width := CELL_SIZE - 2;
    FDiaCells[I].Height := CELL_SIZE - 2;
    FDiaCells[I].Fill.Kind := TBrushKind.Solid;
    FDiaCells[I].Fill.Color := COR_CINZA_CLARO;
    FDiaCells[I].Stroke.Kind := TBrushKind.None;
    FDiaCells[I].XRadius := 6;
    FDiaCells[I].YRadius := 6;
    FDiaCells[I].Tag := I;
    FDiaCells[I].HitTest := True;
    FDiaCells[I].OnClick := DiaCellClick;

    FDiaLabels[I] := TLabel.Create(Self);
    FDiaLabels[I].Parent := FDiaCells[I];
    FDiaLabels[I].Align := TAlignLayout.Client;
    FDiaLabels[I].Text := '';
    FDiaLabels[I].StyledSettings := [];
    FDiaLabels[I].TextSettings.Font.Size := 13;
    FDiaLabels[I].TextSettings.FontColor := COR_TEXTO_ESCURO;
    FDiaLabels[I].TextSettings.HorzAlign := TTextAlign.Center;
    FDiaLabels[I].TextSettings.VertAlign := TTextAlign.Center;
    FDiaLabels[I].HitTest := False;
  end;
end;

procedure TFrmFestas.CriarListaFestas;
begin
  FLayoutListArea := TLayout.Create(Self);
  FLayoutListArea.Parent := FLayoutPrincipal;
  FLayoutListArea.Align := TAlignLayout.Client;

  FRectListBg := TRectangle.Create(Self);
  FRectListBg.Parent := FLayoutListArea;
  FRectListBg.Align := TAlignLayout.Client;
  FRectListBg.Fill.Kind := TBrushKind.Solid;
  FRectListBg.Fill.Color := COR_CARD_BG;
  FRectListBg.Stroke.Color := COR_CINZA_MEDIO;
  FRectListBg.XRadius := 8;
  FRectListBg.YRadius := 8;
  FRectListBg.HitTest := False;

  // Header da lista (título + botão nova festa)
  FLayoutListHeader := TLayout.Create(Self);
  FLayoutListHeader.Parent := FLayoutListArea;
  FLayoutListHeader.Align := TAlignLayout.Top;
  FLayoutListHeader.Height := 52;
  FLayoutListHeader.Margins.Left := 12;
  FLayoutListHeader.Margins.Right := 12;

  FLblListTitle := TLabel.Create(Self);
  FLblListTitle.Parent := FLayoutListHeader;
  FLblListTitle.Align := TAlignLayout.Left;
  FLblListTitle.Width := 250;
  FLblListTitle.Text := 'Festas do Mês';
  FLblListTitle.StyledSettings := [];
  FLblListTitle.TextSettings.Font.Size := 16;
  FLblListTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblListTitle.TextSettings.FontColor := COR_TEXTO_ESCURO;
  FLblListTitle.TextSettings.VertAlign := TTextAlign.Center;

  FBtnNovaFesta := TButton.Create(Self);
  FBtnNovaFesta.Parent := FLayoutListHeader;
  FBtnNovaFesta.Align := TAlignLayout.Right;
  FBtnNovaFesta.Width := 140;
  FBtnNovaFesta.Height := BTN_MIN_SIZE;
  FBtnNovaFesta.Margins.Top := 2;
  FBtnNovaFesta.Margins.Bottom := 2;
  FBtnNovaFesta.Text := '+ Nova Festa';
  FBtnNovaFesta.StyledSettings := [];
  FBtnNovaFesta.TextSettings.Font.Size := 14;
  FBtnNovaFesta.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnNovaFesta.OnClick := BtnNovaFestaClick;
  FBtnNovaFesta.OnMouseDown := BtnMouseDown;
  FBtnNovaFesta.OnMouseUp := BtnMouseUp;

  // Scroll para conteúdo da lista
  FScrollListContent := TVertScrollBox.Create(Self);
  FScrollListContent.Parent := FLayoutListArea;
  FScrollListContent.Align := TAlignLayout.Client;
  FScrollListContent.Margins.Left := 12;
  FScrollListContent.Margins.Right := 12;
  FScrollListContent.Margins.Bottom := 8;

  FLayoutListContent := TLayout.Create(Self);
  FLayoutListContent.Parent := FScrollListContent;
  FLayoutListContent.Align := TAlignLayout.Top;
  FLayoutListContent.Height := 400;
end;

procedure TFrmFestas.CriarFormularioAgendamento;
var
  LPacotes: TObjectList<TPacoteFesta>;
  LI: Integer;

  function CriarCampo(AParent: TFmxObject; ATop: Single;
    const APlaceholder: string): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := AParent;
    Result.Position.X := 16;
    Result.Position.Y := ATop;
    Result.Width := 350;
    Result.Height := 36;
    Result.StyledSettings := [];
    Result.TextSettings.Font.Size := 14;
    Result.TextPrompt := APlaceholder;
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
  FLayoutFormPanel.Width := 400;
  FLayoutFormPanel.Height := 620;

  FRectFormBg := TRectangle.Create(Self);
  FRectFormBg.Parent := FLayoutFormPanel;
  FRectFormBg.Align := TAlignLayout.Client;
  FRectFormBg.Fill.Kind := TBrushKind.Solid;
  FRectFormBg.Fill.Color := COR_BRANCO;
  FRectFormBg.Stroke.Color := COR_CINZA_MEDIO;
  FRectFormBg.XRadius := 12;
  FRectFormBg.YRadius := 12;
  FRectFormBg.HitTest := False;

  // Título do formulário
  FLblFormTitle := TLabel.Create(Self);
  FLblFormTitle.Parent := FLayoutFormPanel;
  FLblFormTitle.Position.X := 16;
  FLblFormTitle.Position.Y := 12;
  FLblFormTitle.Width := 360;
  FLblFormTitle.Height := 30;
  FLblFormTitle.Text := 'Nova Festa';
  FLblFormTitle.StyledSettings := [];
  FLblFormTitle.TextSettings.Font.Size := 18;
  FLblFormTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFormTitle.TextSettings.FontColor := COR_AZUL_PRIMARIO;
  FLblFormTitle.TextSettings.HorzAlign := TTextAlign.Leading;

  // Campos do formulário
  FEdtNomeAniversariante := CriarCampo(FLayoutFormPanel, 50, 'Nome do aniversariante');
  FEdtTutorNome := CriarCampo(FLayoutFormPanel, 92, 'Nome do responsável');
  FEdtTutorCPF := CriarCampo(FLayoutFormPanel, 134, 'CPF do responsável');
  FEdtTutorEmail := CriarCampo(FLayoutFormPanel, 176, 'Email');
  FEdtTutorTelefone := CriarCampo(FLayoutFormPanel, 218, 'Telefone');
  FEdtTutorEndereco := CriarCampo(FLayoutFormPanel, 260, 'Endereço');

  // Data
  FEdtDataFesta := CriarCampo(FLayoutFormPanel, 302, 'Data (dd/mm/aaaa)');
  FEdtDataFesta.OnChange := EdtDataFestaChange;

  // Combo Slot
  FCmbSlot := TComboBox.Create(Self);
  FCmbSlot.Parent := FLayoutFormPanel;
  FCmbSlot.Position.X := 16;
  FCmbSlot.Position.Y := 344;
  FCmbSlot.Width := 350;
  FCmbSlot.Height := 36;
  FCmbSlot.ItemIndex := -1;

  // Combo Pacote
  FCmbPacote := TComboBox.Create(Self);
  FCmbPacote.Parent := FLayoutFormPanel;
  FCmbPacote.Position.X := 16;
  FCmbPacote.Position.Y := 386;
  FCmbPacote.Width := 350;
  FCmbPacote.Height := 36;
  FCmbPacote.OnChange := CmbPacoteChange;

  // Carregar pacotes no combo
  LPacotes := FController.DAOPacote.FindAll;
  try
    for LI := 0 to LPacotes.Count - 1 do
      FCmbPacote.Items.Add(LPacotes[LI].Nome + ' (até ' +
        IntToStr(LPacotes[LI].Max_Convidados) + ' conv.)');
  finally
    LPacotes.Free;
  end;

  // Valor calculado
  FLblValorCalculado := TLabel.Create(Self);
  FLblValorCalculado.Parent := FLayoutFormPanel;
  FLblValorCalculado.Position.X := 16;
  FLblValorCalculado.Position.Y := 430;
  FLblValorCalculado.Width := 350;
  FLblValorCalculado.Height := 30;
  FLblValorCalculado.Text := 'Valor: R$ 0,00';
  FLblValorCalculado.StyledSettings := [];
  FLblValorCalculado.TextSettings.Font.Size := 16;
  FLblValorCalculado.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblValorCalculado.TextSettings.FontColor := COR_VERDE;

  // Valor pago (input)
  FEdtValorPago := CriarCampo(FLayoutFormPanel, 466, 'Valor pago (R$)');

  // Botões
  FBtnSalvarReceber := TButton.Create(Self);
  FBtnSalvarReceber.Parent := FLayoutFormPanel;
  FBtnSalvarReceber.Position.X := 16;
  FBtnSalvarReceber.Position.Y := 520;
  FBtnSalvarReceber.Width := 170;
  FBtnSalvarReceber.Height := BTN_MIN_SIZE;
  FBtnSalvarReceber.Text := 'Salvar e Receber';
  FBtnSalvarReceber.StyledSettings := [];
  FBtnSalvarReceber.TextSettings.Font.Size := 14;
  FBtnSalvarReceber.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBtnSalvarReceber.OnClick := BtnSalvarReceberClick;
  FBtnSalvarReceber.OnMouseDown := BtnMouseDown;
  FBtnSalvarReceber.OnMouseUp := BtnMouseUp;

  FBtnCancelarForm := TButton.Create(Self);
  FBtnCancelarForm.Parent := FLayoutFormPanel;
  FBtnCancelarForm.Position.X := 196;
  FBtnCancelarForm.Position.Y := 520;
  FBtnCancelarForm.Width := 170;
  FBtnCancelarForm.Height := BTN_MIN_SIZE;
  FBtnCancelarForm.Text := 'Cancelar';
  FBtnCancelarForm.StyledSettings := [];
  FBtnCancelarForm.TextSettings.Font.Size := 14;
  FBtnCancelarForm.OnClick := BtnCancelarFormClick;
  FBtnCancelarForm.OnMouseDown := BtnMouseDown;
  FBtnCancelarForm.OnMouseUp := BtnMouseUp;
end;

procedure TFrmFestas.CriarCancelModal;
begin
  FLayoutCancelModal := TLayout.Create(Self);
  FLayoutCancelModal.Parent := Self;
  FLayoutCancelModal.Align := TAlignLayout.Client;
  FLayoutCancelModal.Visible := False;

  FRectCancelBg := TRectangle.Create(Self);
  FRectCancelBg.Parent := FLayoutCancelModal;
  FRectCancelBg.Align := TAlignLayout.Client;
  FRectCancelBg.Fill.Kind := TBrushKind.Solid;
  FRectCancelBg.Fill.Color := COR_OVERLAY;
  FRectCancelBg.Stroke.Kind := TBrushKind.None;
  FRectCancelBg.HitTest := True;

  FLayoutCancelPanel := TLayout.Create(Self);
  FLayoutCancelPanel.Parent := FLayoutCancelModal;
  FLayoutCancelPanel.Align := TAlignLayout.Center;
  FLayoutCancelPanel.Width := 380;
  FLayoutCancelPanel.Height := 200;

  FRectCancelPanelBg := TRectangle.Create(Self);
  FRectCancelPanelBg.Parent := FLayoutCancelPanel;
  FRectCancelPanelBg.Align := TAlignLayout.Client;
  FRectCancelPanelBg.Fill.Kind := TBrushKind.Solid;
  FRectCancelPanelBg.Fill.Color := COR_BRANCO;
  FRectCancelPanelBg.Stroke.Color := COR_CINZA_MEDIO;
  FRectCancelPanelBg.XRadius := 12;
  FRectCancelPanelBg.YRadius := 12;
  FRectCancelPanelBg.HitTest := False;

  FLblCancelTitle := TLabel.Create(Self);
  FLblCancelTitle.Parent := FLayoutCancelPanel;
  FLblCancelTitle.Position.X := 16;
  FLblCancelTitle.Position.Y := 16;
  FLblCancelTitle.Width := 340;
  FLblCancelTitle.Height := 30;
  FLblCancelTitle.Text := 'Motivo do cancelamento (mín. 10 caracteres):';
  FLblCancelTitle.StyledSettings := [];
  FLblCancelTitle.TextSettings.Font.Size := 14;
  FLblCancelTitle.TextSettings.FontColor := COR_TEXTO_ESCURO;

  FEdtCancelMotivo := TEdit.Create(Self);
  FEdtCancelMotivo.Parent := FLayoutCancelPanel;
  FEdtCancelMotivo.Position.X := 16;
  FEdtCancelMotivo.Position.Y := 56;
  FEdtCancelMotivo.Width := 348;
  FEdtCancelMotivo.Height := 36;
  FEdtCancelMotivo.StyledSettings := [];
  FEdtCancelMotivo.TextSettings.Font.Size := 14;
  FEdtCancelMotivo.TextPrompt := 'Ex: Cliente solicitou cancelamento...';

  FBtnConfirmarCancel := TButton.Create(Self);
  FBtnConfirmarCancel.Parent := FLayoutCancelPanel;
  FBtnConfirmarCancel.Position.X := 16;
  FBtnConfirmarCancel.Position.Y := 110;
  FBtnConfirmarCancel.Width := 160;
  FBtnConfirmarCancel.Height := BTN_MIN_SIZE;
  FBtnConfirmarCancel.Text := 'Confirmar';
  FBtnConfirmarCancel.StyledSettings := [];
  FBtnConfirmarCancel.TextSettings.Font.Size := 14;
  FBtnConfirmarCancel.OnClick := BtnConfirmarCancelClick;
  FBtnConfirmarCancel.OnMouseDown := BtnMouseDown;
  FBtnConfirmarCancel.OnMouseUp := BtnMouseUp;

  FBtnFecharCancel := TButton.Create(Self);
  FBtnFecharCancel.Parent := FLayoutCancelPanel;
  FBtnFecharCancel.Position.X := 196;
  FBtnFecharCancel.Position.Y := 110;
  FBtnFecharCancel.Width := 160;
  FBtnFecharCancel.Height := BTN_MIN_SIZE;
  FBtnFecharCancel.Text := 'Voltar';
  FBtnFecharCancel.StyledSettings := [];
  FBtnFecharCancel.TextSettings.Font.Size := 14;
  FBtnFecharCancel.OnClick := BtnFecharCancelClick;
  FBtnFecharCancel.OnMouseDown := BtnMouseDown;
  FBtnFecharCancel.OnMouseUp := BtnMouseUp;
end;

{ ===== Calendar Logic ===== }

procedure TFrmFestas.AtualizarCalendario;
var
  LPrimeiroDia: TDate;
  LDiaSemanaInicio: Word;
  LDiasNoMes: Word;
  I: Integer;
  LDia: Integer;
  LStatus: TDiaStatus;
begin
  FLblMesAno.Text := NomeMes(FMesAtual) + ' ' + IntToStr(FAnoAtual);

  LPrimeiroDia := EncodeDate(FAnoAtual, FMesAtual, 1);
  LDiaSemanaInicio := DayOfWeek(LPrimeiroDia) - 1; // 0=Dom, 1=Seg, ..., 6=Sáb
  LDiasNoMes := DaysInAMonth(FAnoAtual, FMesAtual);

  for I := 0 to 41 do
  begin
    LDia := I - Integer(LDiaSemanaInicio) + 1;

    if (LDia >= 1) and (LDia <= Integer(LDiasNoMes)) then
    begin
      FDiaLabels[I].Text := IntToStr(LDia);
      FDiaCells[I].Visible := True;

      LStatus := ObterStatusDia(LDia);
      case LStatus of
        dsLivre:   FDiaCells[I].Fill.Color := COR_VERDE;
        dsParcial: FDiaCells[I].Fill.Color := COR_AMARELO;
        dsOcupado: FDiaCells[I].Fill.Color := COR_VERMELHO;
      end;

      // Destaque para dia selecionado
      if (LDia = FDiaSelecionado) then
      begin
        FDiaCells[I].Stroke.Kind := TBrushKind.Solid;
        FDiaCells[I].Stroke.Color := COR_AZUL_PRIMARIO;
        FDiaCells[I].Stroke.Thickness := 3;
      end
      else
      begin
        FDiaCells[I].Stroke.Kind := TBrushKind.None;
      end;
    end
    else
    begin
      FDiaLabels[I].Text := '';
      FDiaCells[I].Visible := False;
    end;
  end;
end;

function TFrmFestas.ObterStatusDia(ADia: Word): TDiaStatus;
var
  LData: TDate;
  LSlots: TArray<string>;
  LDiaSemana: Word;
  LTotalSlots: Integer;
  LDisponiveis: Integer;
begin
  Result := dsLivre;
  LData := EncodeDate(FAnoAtual, FMesAtual, ADia);
  LSlots := FController.SlotsDisponiveisData(LData);
  LDisponiveis := Length(LSlots);

  // Determinar total de slots possíveis para o dia
  LDiaSemana := DayOfWeek(LData);
  if LDiaSemana = 1 then // Domingo
    LTotalSlots := 1
  else
    LTotalSlots := 2;

  if LDisponiveis = 0 then
    Result := dsOcupado
  else if LDisponiveis < LTotalSlots then
    Result := dsParcial
  else
    Result := dsLivre;
end;

procedure TFrmFestas.DiaCellClick(Sender: TObject);
var
  LIdx: Integer;
  LPrimeiroDia: TDate;
  LDiaSemanaInicio: Word;
  LDia: Integer;
begin
  if not (Sender is TRectangle) then
    Exit;

  LIdx := TRectangle(Sender).Tag;
  LPrimeiroDia := EncodeDate(FAnoAtual, FMesAtual, 1);
  LDiaSemanaInicio := DayOfWeek(LPrimeiroDia) - 1;
  LDia := LIdx - Integer(LDiaSemanaInicio) + 1;

  if (LDia >= 1) and (LDia <= DaysInAMonth(FAnoAtual, FMesAtual)) then
  begin
    FDiaSelecionado := LDia;
    AtualizarCalendario;
    AtualizarListaFestas;
  end;
end;

procedure TFrmFestas.BtnMesAnteriorClick(Sender: TObject);
begin
  if FMesAtual = 1 then
  begin
    FMesAtual := 12;
    Dec(FAnoAtual);
  end
  else
    Dec(FMesAtual);

  FDiaSelecionado := 1;
  AtualizarCalendario;
  AtualizarListaFestas;
  AtualizarStats;
end;

procedure TFrmFestas.BtnMesProximoClick(Sender: TObject);
begin
  if FMesAtual = 12 then
  begin
    FMesAtual := 1;
    Inc(FAnoAtual);
  end
  else
    Inc(FMesAtual);

  FDiaSelecionado := 1;
  AtualizarCalendario;
  AtualizarListaFestas;
  AtualizarStats;
end;

{ ===== List Logic ===== }

procedure TFrmFestas.AtualizarListaFestas;
var
  LFestas: TObjectList<TFesta>;
  I: Integer;
  LRow: TLayout;
  LLblData, LLblSlot, LLblAniv, LLblPacote, LLblValor, LLblStatus: TLabel;
  LLblMotivo: TLabel;
  LBtnVer, LBtnCancelar: TButton;
  LPosY: Single;
  LIsCancelled: Boolean;
  LCorTexto: TAlphaColor;
begin
  // Limpar lista existente
  while FLayoutListContent.ChildrenCount > 0 do
    FLayoutListContent.Children[0].Free;

  LFestas := FController.FestasDoMes(FMesAtual, FAnoAtual);
  try
    FLayoutListContent.Height := Max(400, (LFestas.Count + 1) * 48);
    LPosY := 0;

    // Header row
    LRow := TLayout.Create(FLayoutListContent);
    LRow.Parent := FLayoutListContent;
    LRow.Position.X := 0;
    LRow.Position.Y := LPosY;
    LRow.Width := FLayoutListContent.Width;
    LRow.Height := 36;

    LLblData := TLabel.Create(LRow);
    LLblData.Parent := LRow;
    LLblData.Position.X := 0;
    LLblData.Width := 80;
    LLblData.Height := 36;
    LLblData.Text := 'Data';
    LLblData.StyledSettings := [];
    LLblData.TextSettings.Font.Size := 12;
    LLblData.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblData.TextSettings.FontColor := COR_CINZA_ESCURO;

    LLblSlot := TLabel.Create(LRow);
    LLblSlot.Parent := LRow;
    LLblSlot.Position.X := 80;
    LLblSlot.Width := 110;
    LLblSlot.Height := 36;
    LLblSlot.Text := 'Horário';
    LLblSlot.StyledSettings := [];
    LLblSlot.TextSettings.Font.Size := 12;
    LLblSlot.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblSlot.TextSettings.FontColor := COR_CINZA_ESCURO;

    LLblAniv := TLabel.Create(LRow);
    LLblAniv.Parent := LRow;
    LLblAniv.Position.X := 190;
    LLblAniv.Width := 120;
    LLblAniv.Height := 36;
    LLblAniv.Text := 'Aniversariante';
    LLblAniv.StyledSettings := [];
    LLblAniv.TextSettings.Font.Size := 12;
    LLblAniv.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblAniv.TextSettings.FontColor := COR_CINZA_ESCURO;

    LLblValor := TLabel.Create(LRow);
    LLblValor.Parent := LRow;
    LLblValor.Position.X := 310;
    LLblValor.Width := 90;
    LLblValor.Height := 36;
    LLblValor.Text := 'Valor';
    LLblValor.StyledSettings := [];
    LLblValor.TextSettings.Font.Size := 12;
    LLblValor.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblValor.TextSettings.FontColor := COR_CINZA_ESCURO;

    LLblStatus := TLabel.Create(LRow);
    LLblStatus.Parent := LRow;
    LLblStatus.Position.X := 400;
    LLblStatus.Width := 90;
    LLblStatus.Height := 36;
    LLblStatus.Text := 'Status';
    LLblStatus.StyledSettings := [];
    LLblStatus.TextSettings.Font.Size := 12;
    LLblStatus.TextSettings.Font.Style := [TFontStyle.fsBold];
    LLblStatus.TextSettings.FontColor := COR_CINZA_ESCURO;

    LPosY := LPosY + 40;

    // Data rows
    for I := 0 to LFestas.Count - 1 do
    begin
      LIsCancelled := SameText(LFestas[I].Status, 'CANCELADA');
      if LIsCancelled then
        LCorTexto := $FF9E9E9E  // cinza para canceladas
      else
        LCorTexto := COR_TEXTO_ESCURO;

      LRow := TLayout.Create(FLayoutListContent);
      LRow.Parent := FLayoutListContent;
      LRow.Position.X := 0;
      LRow.Position.Y := LPosY;
      LRow.Width := FLayoutListContent.Width;
      LRow.Height := 44;
      LRow.Tag := LFestas[I].Id;

      LLblData := TLabel.Create(LRow);
      LLblData.Parent := LRow;
      LLblData.Position.X := 0;
      LLblData.Width := 80;
      LLblData.Height := 44;
      LLblData.Text := FormatDateTime('dd/mm', LFestas[I].Data_Festa);
      LLblData.StyledSettings := [];
      LLblData.TextSettings.Font.Size := 13;
      LLblData.TextSettings.FontColor := LCorTexto;
      LLblData.TextSettings.VertAlign := TTextAlign.Center;

      LLblSlot := TLabel.Create(LRow);
      LLblSlot.Parent := LRow;
      LLblSlot.Position.X := 80;
      LLblSlot.Width := 110;
      LLblSlot.Height := 44;
      LLblSlot.Text := LFestas[I].Horario_Slot;
      LLblSlot.StyledSettings := [];
      LLblSlot.TextSettings.Font.Size := 13;
      LLblSlot.TextSettings.FontColor := LCorTexto;
      LLblSlot.TextSettings.VertAlign := TTextAlign.Center;

      LLblAniv := TLabel.Create(LRow);
      LLblAniv.Parent := LRow;
      LLblAniv.Position.X := 190;
      LLblAniv.Width := 120;
      LLblAniv.Height := 44;
      if LIsCancelled then
        LLblAniv.Text := '~~' + LFestas[I].Nome_Aniversariante + '~~'
      else
        LLblAniv.Text := LFestas[I].Nome_Aniversariante;
      LLblAniv.StyledSettings := [];
      LLblAniv.TextSettings.Font.Size := 13;
      LLblAniv.TextSettings.FontColor := LCorTexto;
      LLblAniv.TextSettings.VertAlign := TTextAlign.Center;
      if LIsCancelled then
        LLblAniv.TextSettings.Font.Style := [TFontStyle.fsStrikeOut];

      LLblValor := TLabel.Create(LRow);
      LLblValor.Parent := LRow;
      LLblValor.Position.X := 310;
      LLblValor.Width := 90;
      LLblValor.Height := 44;
      LLblValor.Text := Format('R$ %.2f', [LFestas[I].Valor_Total]);
      LLblValor.StyledSettings := [];
      LLblValor.TextSettings.Font.Size := 13;
      LLblValor.TextSettings.FontColor := LCorTexto;
      LLblValor.TextSettings.VertAlign := TTextAlign.Center;

      LLblStatus := TLabel.Create(LRow);
      LLblStatus.Parent := LRow;
      LLblStatus.Position.X := 400;
      LLblStatus.Width := 90;
      LLblStatus.Height := 44;
      LLblStatus.Text := LFestas[I].Status;
      LLblStatus.StyledSettings := [];
      LLblStatus.TextSettings.Font.Size := 12;
      LLblStatus.TextSettings.VertAlign := TTextAlign.Center;
      if LIsCancelled then
        LLblStatus.TextSettings.FontColor := COR_VERMELHO
      else
        LLblStatus.TextSettings.FontColor := COR_VERDE;

      // Botão Ver/Editar
      LBtnVer := TButton.Create(LRow);
      LBtnVer.Parent := LRow;
      LBtnVer.Position.X := 500;
      LBtnVer.Position.Y := 2;
      LBtnVer.Width := 50;
      LBtnVer.Height := 40;
      LBtnVer.Tag := LFestas[I].Id;
      LBtnVer.Text := 'Ver';
      LBtnVer.StyledSettings := [];
      LBtnVer.TextSettings.Font.Size := 12;
      LBtnVer.OnMouseDown := BtnMouseDown;
      LBtnVer.OnMouseUp := BtnMouseUp;
      LBtnVer.OnClick := BtnVerFestaClick;

      // Botão Cancelar (só para confirmadas)
      if not LIsCancelled then
      begin
        LBtnCancelar := TButton.Create(LRow);
        LBtnCancelar.Parent := LRow;
        LBtnCancelar.Position.X := 556;
        LBtnCancelar.Position.Y := 2;
        LBtnCancelar.Width := 70;
        LBtnCancelar.Height := 40;
        LBtnCancelar.Tag := LFestas[I].Id;
        LBtnCancelar.Text := 'Cancelar';
        LBtnCancelar.StyledSettings := [];
        LBtnCancelar.TextSettings.Font.Size := 11;
        LBtnCancelar.OnMouseDown := BtnMouseDown;
        LBtnCancelar.OnMouseUp := BtnMouseUp;
        LBtnCancelar.OnClick := BtnCancelarFestaClick;
      end
      else
      begin
        // Show cancel reason for cancelled parties
        LLblMotivo := TLabel.Create(LRow);
        LLblMotivo.Parent := LRow;
        LLblMotivo.Position.X := 500;
        LLblMotivo.Width := 150;
        LLblMotivo.Height := 44;
        LLblMotivo.Text := LFestas[I].Motivo_Cancelamento;
        LLblMotivo.StyledSettings := [];
        LLblMotivo.TextSettings.Font.Size := 10;
        LLblMotivo.TextSettings.FontColor := COR_VERMELHO;
        LLblMotivo.TextSettings.VertAlign := TTextAlign.Center;
      end;

      LPosY := LPosY + 48;
    end;
  finally
    LFestas.Free;
  end;
end;

procedure TFrmFestas.AtualizarStats;
var
  LFestas: TObjectList<TFesta>;
  I: Integer;
  LCount: Integer;
  LReceita: Currency;
  LPacoteCount: TDictionary<Integer, Integer>;
  LMaxPacoteId: Integer;
  LMaxCount: Integer;
  LPacote: TPacoteFesta;
  LPair: TPair<Integer, Integer>;
begin
  LFestas := FController.FestasDoMes(FMesAtual, FAnoAtual);
  LPacoteCount := TDictionary<Integer, Integer>.Create;
  try
    LCount := 0;
    LReceita := 0;
    LMaxPacoteId := 0;
    LMaxCount := 0;

    for I := 0 to LFestas.Count - 1 do
    begin
      if SameText(LFestas[I].Status, 'CONFIRMADA') then
      begin
        Inc(LCount);
        LReceita := LReceita + LFestas[I].Valor_Total;

        // Contar pacotes
        if LPacoteCount.ContainsKey(LFestas[I].Pacote_Id) then
          LPacoteCount[LFestas[I].Pacote_Id] := LPacoteCount[LFestas[I].Pacote_Id] + 1
        else
          LPacoteCount.Add(LFestas[I].Pacote_Id, 1);
      end;
    end;

    FLblStatFestasValue.Text := IntToStr(LCount);
    FLblStatReceitaValue.Text := Format('R$ %.2f', [LReceita]);

    // Encontrar pacote mais reservado
    for LPair in LPacoteCount do
    begin
      if LPair.Value > LMaxCount then
      begin
        LMaxCount := LPair.Value;
        LMaxPacoteId := LPair.Key;
      end;
    end;

    if LMaxPacoteId > 0 then
    begin
      LPacote := FController.DAOPacote.Find(LMaxPacoteId);
      try
        if Assigned(LPacote) then
          FLblStatPacoteValue.Text := LPacote.Nome
        else
          FLblStatPacoteValue.Text := '--';
      finally
        LPacote.Free;
      end;
    end
    else
      FLblStatPacoteValue.Text := '--';
  finally
    LPacoteCount.Free;
    LFestas.Free;
  end;
end;

{ ===== Form Logic ===== }

procedure TFrmFestas.MostrarFormulario(AFestaId: Integer);
var
  LFesta: TFesta;
  LTutor: TTutor;
  LPacotes: TObjectList<TPacoteFesta>;
  I: Integer;
begin
  FEditandoFestaId := AFestaId;

  if AFestaId > 0 then
  begin
    // Carregar dados da festa existente
    FLblFormTitle.Text := 'Editar Festa #' + IntToStr(AFestaId);
    LFesta := FController.DAOFesta.Find(AFestaId);
    try
      if Assigned(LFesta) then
      begin
        FEdtNomeAniversariante.Text := LFesta.Nome_Aniversariante;
        FEdtDataFesta.Text := FormatDateTime('dd/mm/yyyy', LFesta.Data_Festa);

        // Carregar tutor
        LTutor := FDAOTutor.Find(LFesta.Tutor_Id);
        try
          if Assigned(LTutor) then
          begin
            FEdtTutorNome.Text := LTutor.Nome;
            FEdtTutorCPF.Text := LTutor.CPF;
            FEdtTutorEmail.Text := LTutor.Email;
            FEdtTutorTelefone.Text := LTutor.Telefone;
            FEdtTutorEndereco.Text := LTutor.Endereco;
          end;
        finally
          LTutor.Free;
        end;

        // Selecionar pacote
        LPacotes := FController.DAOPacote.FindAll;
        try
          for I := 0 to LPacotes.Count - 1 do
          begin
            if LPacotes[I].Id = LFesta.Pacote_Id then
            begin
              FCmbPacote.ItemIndex := I;
              Break;
            end;
          end;
        finally
          LPacotes.Free;
        end;

        // Atualizar slots e selecionar o atual
        AtualizarSlotsDisponiveis;
        for I := 0 to FCmbSlot.Items.Count - 1 do
        begin
          if SameText(FCmbSlot.Items[I], LFesta.Horario_Slot) then
          begin
            FCmbSlot.ItemIndex := I;
            Break;
          end;
        end;

        FLblValorCalculado.Text := Format('Valor: R$ %.2f', [LFesta.Valor_Total]);
        FEdtValorPago.Text := Format('%.2f', [LFesta.Valor_Pago]);
      end;
    finally
      LFesta.Free;
    end;
  end
  else
  begin
    // Nova festa
    FLblFormTitle.Text := 'Nova Festa';
    FEdtNomeAniversariante.Text := '';
    FEdtTutorNome.Text := '';
    FEdtTutorCPF.Text := '';
    FEdtTutorEmail.Text := '';
    FEdtTutorTelefone.Text := '';
    FEdtTutorEndereco.Text := '';
    FEdtDataFesta.Text := FormatDateTime('dd/mm/yyyy',
      EncodeDate(FAnoAtual, FMesAtual, FDiaSelecionado));
    FCmbSlot.ItemIndex := -1;
    FCmbPacote.ItemIndex := -1;
    FLblValorCalculado.Text := 'Valor: R$ 0,00';
    FEdtValorPago.Text := '';
    AtualizarSlotsDisponiveis;
  end;

  FLayoutOverlay.Visible := True;
  FLayoutOverlay.BringToFront;
end;

procedure TFrmFestas.OcultarFormulario;
begin
  FLayoutOverlay.Visible := False;
  FEditandoFestaId := 0;
end;

procedure TFrmFestas.BtnNovaFestaClick(Sender: TObject);
begin
  MostrarFormulario(0);
end;

procedure TFrmFestas.BtnSalvarReceberClick(Sender: TObject);
var
  LTutor: TTutor;
  LTutorId: Integer;
  LData: TDate;
  LSlot: string;
  LPacoteIdx: Integer;
  LPacotes: TObjectList<TPacoteFesta>;
  LPacoteId: Integer;
  LValorPago: Currency;
begin
  // Validar campos obrigatórios
  if Trim(FEdtNomeAniversariante.Text) = '' then
  begin
    FEdtNomeAniversariante.SetFocus;
    Exit;
  end;

  if Trim(FEdtTutorNome.Text) = '' then
  begin
    FEdtTutorNome.SetFocus;
    Exit;
  end;

  // Data
  LData := ParseDataEdit(FEdtDataFesta.Text);
  if LData = 0 then
  begin
    FEdtDataFesta.SetFocus;
    Exit;
  end;

  // Slot
  if FCmbSlot.ItemIndex < 0 then
    Exit;
  LSlot := FCmbSlot.Items[FCmbSlot.ItemIndex];

  // Pacote
  LPacoteIdx := FCmbPacote.ItemIndex;
  if LPacoteIdx < 0 then
    Exit;

  LPacotes := FController.DAOPacote.FindAll;
  try
    if LPacoteIdx >= LPacotes.Count then
      Exit;
    LPacoteId := LPacotes[LPacoteIdx].Id;
  finally
    LPacotes.Free;
  end;

  // Criar ou localizar tutor
  LTutor := TTutor.Create;
  try
    LTutor.Nome := FEdtTutorNome.Text;
    LTutor.CPF := FEdtTutorCPF.Text;
    LTutor.Email := FEdtTutorEmail.Text;
    LTutor.Telefone := FEdtTutorTelefone.Text;
    LTutor.Endereco := FEdtTutorEndereco.Text;
    FDAOTutor.Save(LTutor);
    LTutorId := FDAOTutor.LastId;
  finally
    LTutor.Free;
  end;

  // Valor pago
  LValorPago := 0;
  if Trim(FEdtValorPago.Text) <> '' then
  begin
    try
      LValorPago := StrToCurr(StringReplace(FEdtValorPago.Text, '.', ',', [rfReplaceAll]));
    except
      LValorPago := 0;
    end;
  end;

  // Montar entidade e agendar
  FController.Entidade.Free;
  FController.Entidade := TFesta.Create;
  FController.Entidade.Nome_Aniversariante := Trim(FEdtNomeAniversariante.Text);
  FController.Entidade.Tutor_Id := LTutorId;
  FController.Entidade.Data_Festa := LData;
  FController.Entidade.Horario_Slot := LSlot;
  FController.Entidade.Pacote_Id := LPacoteId;
  FController.Entidade.Num_Convidados := 10; // Padrão (poderia ter campo)

  try
    if FController.AgendarFesta then
    begin
      // Registrar pagamento se informado
      if LValorPago > 0 then
        FController.RegistrarPagamento(LValorPago, 'DINHEIRO');

      OcultarFormulario;
      AtualizarCalendario;
      AtualizarListaFestas;
      AtualizarStats;
    end;
  except
    on E: Exception do
    begin
      // Exibir erro no label de valor como feedback simples
      FLblValorCalculado.Text := 'Erro: ' + E.Message;
      FLblValorCalculado.TextSettings.FontColor := COR_VERMELHO;
    end;
  end;
end;

procedure TFrmFestas.BtnCancelarFormClick(Sender: TObject);
begin
  OcultarFormulario;
end;

procedure TFrmFestas.AtualizarSlotsDisponiveis;
var
  LData: TDate;
  LSlots: TArray<string>;
  I: Integer;
begin
  FCmbSlot.Items.Clear;
  FCmbSlot.ItemIndex := -1;

  LData := ParseDataEdit(FEdtDataFesta.Text);
  if LData = 0 then
    Exit;

  LSlots := FController.SlotsDisponiveisData(LData);
  for I := Low(LSlots) to High(LSlots) do
    FCmbSlot.Items.Add(LSlots[I]);

  if FCmbSlot.Items.Count > 0 then
    FCmbSlot.ItemIndex := 0;
end;

procedure TFrmFestas.AtualizarValorCalculado;
var
  LData: TDate;
  LPacoteIdx: Integer;
  LPacotes: TObjectList<TPacoteFesta>;
  LPreco: Currency;
begin
  FLblValorCalculado.TextSettings.FontColor := COR_VERDE;

  LData := ParseDataEdit(FEdtDataFesta.Text);
  LPacoteIdx := FCmbPacote.ItemIndex;

  if (LData = 0) or (LPacoteIdx < 0) then
  begin
    FLblValorCalculado.Text := 'Valor: R$ 0,00';
    Exit;
  end;

  LPacotes := FController.DAOPacote.FindAll;
  try
    if LPacoteIdx >= LPacotes.Count then
    begin
      FLblValorCalculado.Text := 'Valor: R$ 0,00';
      Exit;
    end;

    try
      LPreco := FController.CalcularPrecoFesta(LPacotes[LPacoteIdx].Id, LData);
      FLblValorCalculado.Text := Format('Valor: R$ %.2f', [LPreco]);
    except
      FLblValorCalculado.Text := 'Valor: R$ 0,00';
    end;
  finally
    LPacotes.Free;
  end;
end;

procedure TFrmFestas.CmbPacoteChange(Sender: TObject);
begin
  AtualizarValorCalculado;
end;

procedure TFrmFestas.EdtDataFestaChange(Sender: TObject);
begin
  AtualizarSlotsDisponiveis;
  AtualizarValorCalculado;
end;

{ ===== List Row Action Handlers ===== }

procedure TFrmFestas.BtnVerFestaClick(Sender: TObject);
begin
  if Sender is TButton then
    MostrarFormulario(TButton(Sender).Tag);
end;

procedure TFrmFestas.BtnCancelarFestaClick(Sender: TObject);
begin
  if Sender is TButton then
    MostrarCancelModal(TButton(Sender).Tag);
end;

{ ===== Cancel Logic ===== }

procedure TFrmFestas.MostrarCancelModal(AFestaId: Integer);
begin
  FFestaParaCancelar := AFestaId;
  FEdtCancelMotivo.Text := '';
  FLayoutCancelModal.Visible := True;
  FLayoutCancelModal.BringToFront;
end;

procedure TFrmFestas.OcultarCancelModal;
begin
  FLayoutCancelModal.Visible := False;
  FFestaParaCancelar := 0;
end;

procedure TFrmFestas.BtnConfirmarCancelClick(Sender: TObject);
var
  LFesta: TFesta;
begin
  if Length(Trim(FEdtCancelMotivo.Text)) < 10 then
  begin
    FEdtCancelMotivo.SetFocus;
    Exit;
  end;

  if FFestaParaCancelar <= 0 then
    Exit;

  // Carregar a festa no controller
  LFesta := FController.DAOFesta.Find(FFestaParaCancelar);
  if not Assigned(LFesta) then
    Exit;

  FController.Entidade.Free;
  FController.Entidade := LFesta;

  try
    FController.CancelarFesta(Trim(FEdtCancelMotivo.Text));
    OcultarCancelModal;
    AtualizarCalendario;
    AtualizarListaFestas;
    AtualizarStats;
  except
    on E: Exception do
    begin
      FLblCancelTitle.Text := 'Erro: ' + E.Message;
    end;
  end;
end;

procedure TFrmFestas.BtnFecharCancelClick(Sender: TObject);
begin
  OcultarCancelModal;
end;

{ ===== Touch Feedback ===== }

procedure TFrmFestas.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 0.93;
    TButton(Sender).Scale.Y := 0.93;
  end;
end;

procedure TFrmFestas.BtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender is TButton then
  begin
    TButton(Sender).Scale.X := 1.0;
    TButton(Sender).Scale.Y := 1.0;
  end;
end;

{ ===== Helpers ===== }

function TFrmFestas.NomeMes(AMes: Word): string;
begin
  case AMes of
    1:  Result := 'Janeiro';
    2:  Result := 'Fevereiro';
    3:  Result := 'Março';
    4:  Result := 'Abril';
    5:  Result := 'Maio';
    6:  Result := 'Junho';
    7:  Result := 'Julho';
    8:  Result := 'Agosto';
    9:  Result := 'Setembro';
    10: Result := 'Outubro';
    11: Result := 'Novembro';
    12: Result := 'Dezembro';
  else
    Result := '';
  end;
end;

function TFrmFestas.ParseDataEdit(const ATexto: string): TDate;
var
  LDia, LMes, LAno: Word;
begin
  Result := 0;
  if Length(ATexto) < 10 then
    Exit;
  try
    LDia := StrToInt(Copy(ATexto, 1, 2));
    LMes := StrToInt(Copy(ATexto, 4, 2));
    LAno := StrToInt(Copy(ATexto, 7, 4));
    Result := EncodeDate(LAno, LMes, LDia);
  except
    Result := 0;
  end;
end;

end.
