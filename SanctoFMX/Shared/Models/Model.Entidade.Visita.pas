unit Model.Entidade.Visita;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('VISITA')]
  TVisita = class
  private
    FId: Integer;
    FVisitante_Id: Integer;
    FTutor_Id: Integer;
    FTicket_Id: Integer;
    FCaixa_Id: Integer;
    FHora_Entrada: TDateTime;
    FHora_Prevista_Saida: TDateTime;
    FHora_Saida_Real: TDateTime;
    FValor_Ticket: Currency;
    FValor_Consumo: Currency;
    FValor_Tempo_Extra: Currency;
    FValor_Total: Currency;
    FStatus: string;
    FStatus_Pagamento: string;
    FForma_Pagamento: string;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_VISITA_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Visitante_Id: Integer read FVisitante_Id write FVisitante_Id;
    [Fk]
    property Tutor_Id: Integer read FTutor_Id write FTutor_Id;
    [Fk]
    property Ticket_Id: Integer read FTicket_Id write FTicket_Id;
    [Fk]
    property Caixa_Id: Integer read FCaixa_Id write FCaixa_Id;
    property Hora_Entrada: TDateTime read FHora_Entrada write FHora_Entrada;
    property Hora_Prevista_Saida: TDateTime read FHora_Prevista_Saida write FHora_Prevista_Saida;
    property Hora_Saida_Real: TDateTime read FHora_Saida_Real write FHora_Saida_Real;
    property Valor_Ticket: Currency read FValor_Ticket write FValor_Ticket;
    property Valor_Consumo: Currency read FValor_Consumo write FValor_Consumo;
    property Valor_Tempo_Extra: Currency read FValor_Tempo_Extra write FValor_Tempo_Extra;
    property Valor_Total: Currency read FValor_Total write FValor_Total;
    property Status: string read FStatus write FStatus;
    property Status_Pagamento: string read FStatus_Pagamento write FStatus_Pagamento;
    property Forma_Pagamento: string read FForma_Pagamento write FForma_Pagamento;
  end;

implementation

{ TVisita }

constructor TVisita.Create;
begin
  inherited Create;
  FStatus := 'ABERTA';
  FStatus_Pagamento := 'PENDENTE';
end;

end.
