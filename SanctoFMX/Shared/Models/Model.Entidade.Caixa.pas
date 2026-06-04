unit Model.Entidade.Caixa;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('CAIXA')]
  TCaixa = class
  private
    FId: Integer;
    FColaborador_Id: Integer;
    FValor_Inicial: Currency;
    FSaldo_Esperado: Currency;
    FContagem_Fisica: Currency;
    FDiferenca: Currency;
    FJustificativa_Diferenca: string;
    FStatus: string;
    FData_Abertura: TDateTime;
    FData_Fechamento: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_CAIXA_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Colaborador_Id: Integer read FColaborador_Id write FColaborador_Id;
    property Valor_Inicial: Currency read FValor_Inicial write FValor_Inicial;
    property Saldo_Esperado: Currency read FSaldo_Esperado write FSaldo_Esperado;
    property Contagem_Fisica: Currency read FContagem_Fisica write FContagem_Fisica;
    property Diferenca: Currency read FDiferenca write FDiferenca;
    property Justificativa_Diferenca: string read FJustificativa_Diferenca write FJustificativa_Diferenca;
    property Status: string read FStatus write FStatus;
    property Data_Abertura: TDateTime read FData_Abertura write FData_Abertura;
    property Data_Fechamento: TDateTime read FData_Fechamento write FData_Fechamento;
  end;

implementation

{ TCaixa }

constructor TCaixa.Create;
begin
  inherited Create;
  FStatus := 'ABERTO';
end;

end.
