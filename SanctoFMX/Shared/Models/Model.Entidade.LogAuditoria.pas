unit Model.Entidade.LogAuditoria;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('LOG_AUDITORIA')]
  TLogAuditoria = class
  private
    FId: Integer;
    FColaborador_Id: Integer;
    FTipo_Acao: string;
    FEntidade: string;
    FEntidade_Id: Integer;
    FDetalhes: string;
    FValores_Anteriores: string;
    FValores_Novos: string;
    FData_Hora: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_LOG_AUDITORIA_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Colaborador_Id: Integer read FColaborador_Id write FColaborador_Id;
    property Tipo_Acao: string read FTipo_Acao write FTipo_Acao;
    property Entidade: string read FEntidade write FEntidade;
    property Entidade_Id: Integer read FEntidade_Id write FEntidade_Id;
    property Detalhes: string read FDetalhes write FDetalhes;
    property Valores_Anteriores: string read FValores_Anteriores write FValores_Anteriores;
    property Valores_Novos: string read FValores_Novos write FValores_Novos;
    property Data_Hora: TDateTime read FData_Hora write FData_Hora;
  end;

implementation

{ TLogAuditoria }

constructor TLogAuditoria.Create;
begin
  inherited Create;
end;

end.
