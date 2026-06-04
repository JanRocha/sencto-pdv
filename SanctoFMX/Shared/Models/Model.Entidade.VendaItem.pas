unit Model.Entidade.VendaItem;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('VENDA_ITEM')]
  TVendaItem = class
  private
    FId: Integer;
    FVenda_Id: Integer;
    FProduto_Id: Integer;
    FQuantidade: Integer;
    FPreco_Unitario: Currency;
    FSubtotal: Currency;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_VENDA_ITEM_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Venda_Id: Integer read FVenda_Id write FVenda_Id;
    [Fk]
    property Produto_Id: Integer read FProduto_Id write FProduto_Id;
    property Quantidade: Integer read FQuantidade write FQuantidade;
    property Preco_Unitario: Currency read FPreco_Unitario write FPreco_Unitario;
    property Subtotal: Currency read FSubtotal write FSubtotal;
  end;

implementation

{ TVendaItem }

constructor TVendaItem.Create;
begin
  inherited Create;
  FQuantidade := 1;
end;

end.
