unit Model.Entidade.Tutor;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('TUTOR')]
  TTutor = class
  private
    FId: Integer;
    FNome: string;
    FCPF: string;
    FTelefone: string;
    FEmail: string;
    FEndereco: string;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_TUTOR_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read FEmail write FEmail;
    property Endereco: string read FEndereco write FEndereco;
  end;

implementation

{ TTutor }

constructor TTutor.Create;
begin
  inherited Create;
end;

end.
