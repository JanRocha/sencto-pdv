unit Rtti.Atributos;

interface

type
  /// <summary>
  /// Atributo que define o nome da tabela no banco de dados para a entidade.
  /// Exemplo: [Tabela('COLABORADOR')]
  /// </summary>
  Tabela = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  /// <summary>
  /// Atributo que marca a propriedade como chave primária.
  /// </summary>
  Pk = class(TCustomAttribute);

  /// <summary>
  /// Atributo que marca a propriedade como chave primária manual (sem auto-incremento).
  /// </summary>
  PkManual = class(TCustomAttribute);

  /// <summary>
  /// Atributo que define o generator (sequence) para auto-incremento.
  /// Exemplo: [AutoInc('GEN_COLABORADOR_ID')]
  /// </summary>
  AutoInc = class(TCustomAttribute)
  private
    FGeneratorName: string;
  public
    constructor Create(const AGeneratorName: string);
    property GeneratorName: string read FGeneratorName;
  end;

  /// <summary>
  /// Atributo que marca a propriedade como chave estrangeira.
  /// </summary>
  Fk = class(TCustomAttribute);

  /// <summary>
  /// Atributo que define um nome de coluna customizado no banco.
  /// Exemplo: [Campo('NOME_COMPLETO')]
  /// </summary>
  Campo = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  /// <summary>
  /// Atributo que marca a propriedade para ser ignorada pelo ORM (insert/update/select).
  /// </summary>
  Ignore = class(TCustomAttribute);

  /// <summary>
  /// Atributo que marca a propriedade para não ser serializada (somente leitura do banco).
  /// </summary>
  NoSerialize = class(TCustomAttribute);

implementation

{ Tabela }

constructor Tabela.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ AutoInc }

constructor AutoInc.Create(const AGeneratorName: string);
begin
  inherited Create;
  FGeneratorName := AGeneratorName;
end;

{ Campo }

constructor Campo.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
