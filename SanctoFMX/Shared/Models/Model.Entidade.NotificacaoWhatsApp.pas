unit Model.Entidade.NotificacaoWhatsApp;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('NOTIFICACAO_WHATSAPP')]
  TNotificacaoWhatsApp = class
  private
    FId: Integer;
    FVisita_Id: Integer;
    FTelefone_Tutor: string;
    FStatus: string;
    FMessage_Id: string;
    FCodigo_Erro: string;
    FData_Envio: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_NOTIFICACAO_WHATSAPP_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Visita_Id: Integer read FVisita_Id write FVisita_Id;
    property Telefone_Tutor: string read FTelefone_Tutor write FTelefone_Tutor;
    property Status: string read FStatus write FStatus;
    property Message_Id: string read FMessage_Id write FMessage_Id;
    property Codigo_Erro: string read FCodigo_Erro write FCodigo_Erro;
    property Data_Envio: TDateTime read FData_Envio write FData_Envio;
  end;

implementation

{ TNotificacaoWhatsApp }

constructor TNotificacaoWhatsApp.Create;
begin
  inherited Create;
end;

end.
