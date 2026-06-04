unit Model.Entidade.MovimentacaoCaixa;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('MOVIMENTACAO_CAIXA')]
  TMovimentacaoCaixa = class
  private
    FId: Integer;
    FCaixa_Id: Integer;
    FTipo: string;
    FValor: Currency;
    FMotivo: string;
    FData_Hora: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_MOVIMENTACAO_CAIXA_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Caixa_Id: Integer read FCaixa_Id write FCaixa_Id;
    property Tipo: string read FTipo write FTipo;
    property Valor: Currency read FValor write FValor;
    property Motivo: string read FMotivo write FMotivo;
    property Data_Hora: TDateTime read FData_Hora write FData_Hora;
  end;

implementation

{ TMovimentacaoCaixa }

constructor TMovimentacaoCaixa.Create;
begin
  inherited Create;
end;

end.
