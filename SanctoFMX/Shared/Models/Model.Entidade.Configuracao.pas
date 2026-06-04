unit Model.Entidade.Configuracao;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('CONFIGURACAO')]
  TConfiguracao = class
  private
    FId: Integer;
    FChave: string;
    FValor: string;
    FTipo_Dado: string;
    FDescricao: string;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_CONFIGURACAO_ID')]
    property Id: Integer read FId write FId;
    property Chave: string read FChave write FChave;
    property Valor: string read FValor write FValor;
    property Tipo_Dado: string read FTipo_Dado write FTipo_Dado;
    property Descricao: string read FDescricao write FDescricao;
  end;

implementation

{ TConfiguracao }

constructor TConfiguracao.Create;
begin
  inherited Create;
end;

end.
