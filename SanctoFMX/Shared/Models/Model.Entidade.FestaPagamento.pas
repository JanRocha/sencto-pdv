unit Model.Entidade.FestaPagamento;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('FESTA_PAGAMENTO')]
  TFestaPagamento = class
  private
    FId: Integer;
    FFesta_Id: Integer;
    FValor: Currency;
    FForma_Pagamento: string;
    FData_Hora: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_FESTA_PAGAMENTO_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Festa_Id: Integer read FFesta_Id write FFesta_Id;
    property Valor: Currency read FValor write FValor;
    property Forma_Pagamento: string read FForma_Pagamento write FForma_Pagamento;
    property Data_Hora: TDateTime read FData_Hora write FData_Hora;
  end;

implementation

{ TFestaPagamento }

constructor TFestaPagamento.Create;
begin
  inherited Create;
end;

end.
