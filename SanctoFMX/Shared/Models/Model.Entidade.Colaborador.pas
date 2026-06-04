unit Model.Entidade.Colaborador;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('COLABORADOR')]
  TColaborador = class
  private
    FId: Integer;
    FNome: string;
    FCPF: string;
    FEmail: string;
    FTelefone: string;
    FSenha_Hash: string;
    FPapel: string;
    FSituacao: Integer;
    FTentativas_Login: Integer;
    FData_Bloqueio: TDateTime;
    FUltimo_Acesso: TDateTime;
    FData_Cadastro: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_COLABORADOR_ID')]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Email: string read FEmail write FEmail;
    property Telefone: string read FTelefone write FTelefone;
    property Senha_Hash: string read FSenha_Hash write FSenha_Hash;
    property Papel: string read FPapel write FPapel;
    property Situacao: Integer read FSituacao write FSituacao;
    property Tentativas_Login: Integer read FTentativas_Login write FTentativas_Login;
    property Data_Bloqueio: TDateTime read FData_Bloqueio write FData_Bloqueio;
    property Ultimo_Acesso: TDateTime read FUltimo_Acesso write FUltimo_Acesso;
    property Data_Cadastro: TDateTime read FData_Cadastro write FData_Cadastro;
  end;

implementation

{ TColaborador }

constructor TColaborador.Create;
begin
  inherited Create;
  FSituacao := 1;
  FTentativas_Login := 0;
end;

end.
