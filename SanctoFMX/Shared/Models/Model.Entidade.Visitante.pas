unit Model.Entidade.Visitante;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('VISITANTE')]
  TVisitante = class
  private
    FId: Integer;
    FNome: string;
    FData_Nascimento: TDate;
    FTutor_Id: Integer;
    FLimite_Consumo: Currency;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_VISITANTE_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Data_Nascimento: TDate read FData_Nascimento write FData_Nascimento;
    [Fk]
    property Tutor_Id: Integer read FTutor_Id write FTutor_Id;
    property Limite_Consumo: Currency read FLimite_Consumo write FLimite_Consumo;
  end;

implementation

{ TVisitante }

constructor TVisitante.Create;
begin
  inherited Create;
end;

end.
