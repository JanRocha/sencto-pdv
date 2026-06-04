unit Model.Entidade.Festa;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('FESTA')]
  TFesta = class
  private
    FId: Integer;
    FNome_Aniversariante: string;
    FTutor_Id: Integer;
    FPacote_Id: Integer;
    FData_Festa: TDate;
    FHorario_Slot: string;
    FNum_Convidados: Integer;
    FValor_Total: Currency;
    FValor_Pago: Currency;
    FSaldo_Pendente: Currency;
    FStatus: string;
    FMotivo_Cancelamento: string;
    FData_Cancelamento: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_FESTA_ID')]
    property Id: Integer read FId write FId;
    property Nome_Aniversariante: string read FNome_Aniversariante write FNome_Aniversariante;
    [Fk]
    property Tutor_Id: Integer read FTutor_Id write FTutor_Id;
    [Fk]
    property Pacote_Id: Integer read FPacote_Id write FPacote_Id;
    property Data_Festa: TDate read FData_Festa write FData_Festa;
    property Horario_Slot: string read FHorario_Slot write FHorario_Slot;
    property Num_Convidados: Integer read FNum_Convidados write FNum_Convidados;
    property Valor_Total: Currency read FValor_Total write FValor_Total;
    property Valor_Pago: Currency read FValor_Pago write FValor_Pago;
    property Saldo_Pendente: Currency read FSaldo_Pendente write FSaldo_Pendente;
    property Status: string read FStatus write FStatus;
    property Motivo_Cancelamento: string read FMotivo_Cancelamento write FMotivo_Cancelamento;
    property Data_Cancelamento: TDateTime read FData_Cancelamento write FData_Cancelamento;
  end;

implementation

{ TFesta }

constructor TFesta.Create;
begin
  inherited Create;
  FStatus := 'CONFIRMADA';
end;

end.
