unit Model.Entidade.Categoria;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('CATEGORIA')]
  TCategoria = class
  private
    FId: Integer;
    FNome: string;
    FSituacao: Integer;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_CATEGORIA_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Situacao: Integer read FSituacao write FSituacao;
  end;

implementation

{ TCategoria }

constructor TCategoria.Create;
begin
  inherited Create;
  FSituacao := 1;
end;

end.
