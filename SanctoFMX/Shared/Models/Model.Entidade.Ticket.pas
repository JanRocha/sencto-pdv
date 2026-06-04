unit Model.Entidade.Ticket;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('TICKET')]
  TTicket = class
  private
    FId: Integer;
    FNome: string;
    FDuracao_Minutos: Integer;
    FTipo: string;
    FPreco: Currency;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_TICKET_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Duracao_Minutos: Integer read FDuracao_Minutos write FDuracao_Minutos;
    property Tipo: string read FTipo write FTipo;
    property Preco: Currency read FPreco write FPreco;
  end;

implementation

{ TTicket }

constructor TTicket.Create;
begin
  inherited Create;
end;

end.
