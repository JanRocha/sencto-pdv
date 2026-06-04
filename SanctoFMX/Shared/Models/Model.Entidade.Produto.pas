unit Model.Entidade.Produto;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('PRODUTO')]
  TProduto = class
  private
    FId: Integer;
    FNome: string;
    FCodigo_Barras: string;
    FCategoria_Id: Integer;
    FPreco_Venda: Currency;
    FPreco_Promocional: Currency;
    FUnidade: string;
    FTipo: string;
    FEstoque_Atual: Integer;
    FEstoque_Minimo: Integer;
    FNCM: string;
    FCFOP: string;
    FCST_CSOSN: string;
    FAliquota_ICMS: Currency;
    FAliquota_PIS: Currency;
    FAliquota_COFINS: Currency;
    FSituacao: Integer;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_PRODUTO_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Codigo_Barras: string read FCodigo_Barras write FCodigo_Barras;
    [Fk]
    property Categoria_Id: Integer read FCategoria_Id write FCategoria_Id;
    property Preco_Venda: Currency read FPreco_Venda write FPreco_Venda;
    property Preco_Promocional: Currency read FPreco_Promocional write FPreco_Promocional;
    property Unidade: string read FUnidade write FUnidade;
    property Tipo: string read FTipo write FTipo;
    property Estoque_Atual: Integer read FEstoque_Atual write FEstoque_Atual;
    property Estoque_Minimo: Integer read FEstoque_Minimo write FEstoque_Minimo;
    property NCM: string read FNCM write FNCM;
    property CFOP: string read FCFOP write FCFOP;
    property CST_CSOSN: string read FCST_CSOSN write FCST_CSOSN;
    property Aliquota_ICMS: Currency read FAliquota_ICMS write FAliquota_ICMS;
    property Aliquota_PIS: Currency read FAliquota_PIS write FAliquota_PIS;
    property Aliquota_COFINS: Currency read FAliquota_COFINS write FAliquota_COFINS;
    property Situacao: Integer read FSituacao write FSituacao;
  end;

implementation

{ TProduto }

constructor TProduto.Create;
begin
  inherited Create;
  FSituacao := 1;
  FEstoque_Atual := 0;
  FEstoque_Minimo := 0;
end;

end.
