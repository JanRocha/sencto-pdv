unit Model.Entidade.PacoteFesta;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('PACOTE_FESTA')]
  TPacoteFesta = class
  private
    FId: Integer;
    FNome: string;
    FMax_Convidados: Integer;
    FPreco_Semana: Currency;
    FPreco_FDS: Currency;
    FDescricao: string;
    FSituacao: Integer;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_PACOTE_FESTA_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Max_Convidados: Integer read FMax_Convidados write FMax_Convidados;
    property Preco_Semana: Currency read FPreco_Semana write FPreco_Semana;
    property Preco_FDS: Currency read FPreco_FDS write FPreco_FDS;
    property Descricao: string read FDescricao write FDescricao;
    property Situacao: Integer read FSituacao write FSituacao;
  end;

implementation

{ TPacoteFesta }

constructor TPacoteFesta.Create;
begin
  inherited Create;
  FSituacao := 1;
end;

end.
