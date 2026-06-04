unit Model.Entidade.VisitaConsumo;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('VISITA_CONSUMO')]
  TVisitaConsumo = class
  private
    FId: Integer;
    FVisita_Id: Integer;
    FProduto_Id: Integer;
    FQuantidade: Integer;
    FPreco_Unitario: Currency;
    FSubtotal: Currency;
    FData_Hora: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_VISITA_CONSUMO_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Visita_Id: Integer read FVisita_Id write FVisita_Id;
    [Fk]
    property Produto_Id: Integer read FProduto_Id write FProduto_Id;
    property Quantidade: Integer read FQuantidade write FQuantidade;
    property Preco_Unitario: Currency read FPreco_Unitario write FPreco_Unitario;
    property Subtotal: Currency read FSubtotal write FSubtotal;
    property Data_Hora: TDateTime read FData_Hora write FData_Hora;
  end;

implementation

{ TVisitaConsumo }

constructor TVisitaConsumo.Create;
begin
  inherited Create;
  FQuantidade := 1;
end;

end.
