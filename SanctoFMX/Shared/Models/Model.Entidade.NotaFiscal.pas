unit Model.Entidade.NotaFiscal;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('NOTA_FISCAL')]
  TNotaFiscal = class
  private
    FId: Integer;
    FVenda_Id: Integer;
    FTipo: string;
    FChave: string;
    FNumero: Integer;
    FSerie: Integer;
    FXML_Autorizado: string;
    FStatus: string;
    FProtocolo: string;
    FData_Emissao: TDateTime;
    FData_Cancelamento: TDateTime;
    FJustificativa_Cancelamento: string;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_NOTA_FISCAL_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Venda_Id: Integer read FVenda_Id write FVenda_Id;
    property Tipo: string read FTipo write FTipo;
    property Chave: string read FChave write FChave;
    property Numero: Integer read FNumero write FNumero;
    property Serie: Integer read FSerie write FSerie;
    property XML_Autorizado: string read FXML_Autorizado write FXML_Autorizado;
    property Status: string read FStatus write FStatus;
    property Protocolo: string read FProtocolo write FProtocolo;
    property Data_Emissao: TDateTime read FData_Emissao write FData_Emissao;
    property Data_Cancelamento: TDateTime read FData_Cancelamento write FData_Cancelamento;
    property Justificativa_Cancelamento: string read FJustificativa_Cancelamento write FJustificativa_Cancelamento;
  end;

implementation

{ TNotaFiscal }

constructor TNotaFiscal.Create;
begin
  inherited Create;
end;

end.
