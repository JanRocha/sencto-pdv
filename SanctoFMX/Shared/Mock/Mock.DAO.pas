unit Mock.DAO;

interface

uses
  System.SysUtils,
  System.RTTI,
  System.Generics.Collections,
  Rtti.Atributos;

type
  /// <summary>
  /// Interface genérica de acesso a dados (DAO).
  /// Abstrai operações CRUD, consultas e transações, permitindo
  /// substituição transparente entre MockDAO (TObjectList em memória)
  /// e DAO real (FenixORM + Firebird).
  /// </summary>
  IDAO<T: class> = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Insert(AEntity: T): Boolean;
    function Update(AEntity: T): Boolean;
    function Delete(AEntity: T): Boolean;
    function Save(AEntity: T): Boolean;
    function Find(const AId: Integer): T;
    function FindAll(const AFiltro: string = ''): TObjectList<T>;
    function Count(const AFiltro: string = ''): Integer;
    function Where(const ACampo: string; const AValor: TValue): IDAO<T>;
    function LastId: Integer;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
  end;

  /// <summary>
  /// Implementação Mock do DAO usando TObjectList em memória.
  /// Simula o comportamento do FenixORM para validação de fluxos de UI
  /// sem dependência de banco de dados real.
  /// - Auto-incremento de Id via RTTI (detecta propriedade com atributo [Pk])
  /// - Transações com snapshot para rollback
  /// - Filtro Where por campo/valor via RTTI
  /// </summary>
  TMockDAO<T: class, constructor> = class(TInterfacedObject, IDAO<T>)
  private
    FLista: TObjectList<T>;
    FNextId: Integer;
    FInTransaction: Boolean;
    FSnapshot: TObjectList<T>;
    FSnapshotNextId: Integer;
    FWhereCampo: string;
    FWhereValor: TValue;
    FUsarWhere: Boolean;

    /// <summary>Localiza a propriedade com atributo [Pk] via RTTI.</summary>
    function GetPkProperty(ATipo: TRttiType): TRttiProperty;
    /// <summary>Obtém o valor da PK de uma entidade.</summary>
    function GetEntityId(AEntity: T): Integer;
    /// <summary>Define o valor da PK de uma entidade.</summary>
    procedure SetEntityId(AEntity: T; AId: Integer);
    /// <summary>Cria cópia profunda copiando published properties via RTTI.</summary>
    function CloneEntity(AEntity: T): T;
    /// <summary>Copia todos os itens de ASource para ADest (deep copy).</summary>
    procedure CopyListTo(ASource, ADest: TObjectList<T>);
    /// <summary>Verifica se a entidade atende ao filtro Where configurado.</summary>
    function MatchesWhere(AEntity: T): Boolean;
    /// <summary>Limpa o filtro Where após uso.</summary>
    procedure LimparWhere;
  public
    constructor Create;
    destructor Destroy; override;

    function Insert(AEntity: T): Boolean;
    function Update(AEntity: T): Boolean;
    function Delete(AEntity: T): Boolean;
    function Save(AEntity: T): Boolean;
    function Find(const AId: Integer): T;
    function FindAll(const AFiltro: string = ''): TObjectList<T>;
    function Count(const AFiltro: string = ''): Integer;
    function Where(const ACampo: string; const AValor: TValue): IDAO<T>;
    function LastId: Integer;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
  end;

implementation


{ TMockDAO<T> }

constructor TMockDAO<T>.Create;
begin
  inherited Create;
  FLista := TObjectList<T>.Create(True);
  FNextId := 1;
  FInTransaction := False;
  FSnapshot := nil;
  FSnapshotNextId := 0;
  FUsarWhere := False;
  FWhereCampo := '';
end;

destructor TMockDAO<T>.Destroy;
begin
  FLista.Free;
  if Assigned(FSnapshot) then
    FSnapshot.Free;
  inherited Destroy;
end;

function TMockDAO<T>.GetPkProperty(ATipo: TRttiType): TRttiProperty;
var
  lProp: TRttiProperty;
  lAtributo: TCustomAttribute;
begin
  Result := nil;
  for lProp in ATipo.GetProperties do
  begin
    for lAtributo in lProp.GetAttributes do
    begin
      if lAtributo is Pk then
      begin
        Result := lProp;
        Exit;
      end;
    end;
  end;
end;

function TMockDAO<T>.GetEntityId(AEntity: T): Integer;
var
  lContexto: TRttiContext;
  lTipo: TRttiType;
  lPkProp: TRttiProperty;
begin
  Result := 0;
  lTipo := lContexto.GetType(TObject(AEntity).ClassInfo);
  lPkProp := GetPkProperty(lTipo);
  if Assigned(lPkProp) then
    Result := lPkProp.GetValue(TObject(AEntity)).AsInteger;
end;

procedure TMockDAO<T>.SetEntityId(AEntity: T; AId: Integer);
var
  lContexto: TRttiContext;
  lTipo: TRttiType;
  lPkProp: TRttiProperty;
begin
  lTipo := lContexto.GetType(TObject(AEntity).ClassInfo);
  lPkProp := GetPkProperty(lTipo);
  if Assigned(lPkProp) then
    lPkProp.SetValue(TObject(AEntity), AId);
end;

function TMockDAO<T>.CloneEntity(AEntity: T): T;
var
  lContexto: TRttiContext;
  lTipo: TRttiType;
  lProp: TRttiProperty;
begin
  Result := T.Create;
  lTipo := lContexto.GetType(TObject(AEntity).ClassInfo);
  for lProp in lTipo.GetProperties do
  begin
    if lProp.IsReadable and lProp.IsWritable then
      lProp.SetValue(TObject(Result), lProp.GetValue(TObject(AEntity)));
  end;
end;

procedure TMockDAO<T>.CopyListTo(ASource, ADest: TObjectList<T>);
var
  I: Integer;
begin
  ADest.Clear;
  for I := 0 to ASource.Count - 1 do
    ADest.Add(CloneEntity(ASource[I]));
end;

function TMockDAO<T>.MatchesWhere(AEntity: T): Boolean;
var
  lContexto: TRttiContext;
  lTipo: TRttiType;
  lProp: TRttiProperty;
begin
  Result := True;
  if not FUsarWhere then
    Exit;

  Result := False;
  lTipo := lContexto.GetType(TObject(AEntity).ClassInfo);
  lProp := lTipo.GetProperty(FWhereCampo);
  if not Assigned(lProp) then
    Exit;

  case FWhereValor.Kind of
    tkInteger:
      Result := lProp.GetValue(TObject(AEntity)).AsInteger = FWhereValor.AsInteger;
    tkInt64:
      Result := lProp.GetValue(TObject(AEntity)).AsInt64 = FWhereValor.AsInt64;
    tkUString, tkLString, tkString, tkWString:
      Result := SameText(lProp.GetValue(TObject(AEntity)).AsString, FWhereValor.AsString);
  else
    Result := lProp.GetValue(TObject(AEntity)).ToString = FWhereValor.ToString;
  end;
end;

procedure TMockDAO<T>.LimparWhere;
begin
  FUsarWhere := False;
  FWhereCampo := '';
  FWhereValor := TValue.Empty;
end;

function TMockDAO<T>.Insert(AEntity: T): Boolean;
begin
  Result := False;
  if not Assigned(TObject(AEntity)) then
    Exit;

  // Auto-incremento: atribui próximo Id à entidade
  SetEntityId(AEntity, FNextId);
  Inc(FNextId);

  // Armazena clone na lista interna (entidade original permanece com o chamador)
  FLista.Add(CloneEntity(AEntity));
  Result := True;
end;

function TMockDAO<T>.Update(AEntity: T): Boolean;
var
  I: Integer;
  lId: Integer;
begin
  Result := False;
  if not Assigned(TObject(AEntity)) then
    Exit;

  lId := GetEntityId(AEntity);
  for I := 0 to FLista.Count - 1 do
  begin
    if GetEntityId(FLista[I]) = lId then
    begin
      // Substitui o item na lista por um clone atualizado
      FLista[I] := CloneEntity(AEntity);
      Result := True;
      Exit;
    end;
  end;
end;

function TMockDAO<T>.Delete(AEntity: T): Boolean;
var
  I: Integer;
  lId: Integer;
begin
  Result := False;
  if not Assigned(TObject(AEntity)) then
    Exit;

  lId := GetEntityId(AEntity);
  for I := FLista.Count - 1 downto 0 do
  begin
    if GetEntityId(FLista[I]) = lId then
    begin
      FLista.Delete(I);
      Result := True;
      Exit;
    end;
  end;
end;

function TMockDAO<T>.Save(AEntity: T): Boolean;
var
  lId: Integer;
begin
  // Upsert compatível com FenixORM.Save:
  // Se Id=0, insere (auto-incrementa); caso contrário, atualiza.
  lId := GetEntityId(AEntity);
  if lId = 0 then
    Result := Insert(AEntity)
  else
    Result := Update(AEntity);
end;

function TMockDAO<T>.Find(const AId: Integer): T;
var
  I: Integer;
begin
  Result := nil;

  if FUsarWhere then
  begin
    try
      for I := 0 to FLista.Count - 1 do
      begin
        if (GetEntityId(FLista[I]) = AId) and MatchesWhere(FLista[I]) then
        begin
          Result := CloneEntity(FLista[I]);
          Exit;
        end;
      end;
    finally
      LimparWhere;
    end;
    Exit;
  end;

  for I := 0 to FLista.Count - 1 do
  begin
    if GetEntityId(FLista[I]) = AId then
    begin
      Result := CloneEntity(FLista[I]);
      Exit;
    end;
  end;
end;

function TMockDAO<T>.FindAll(const AFiltro: string): TObjectList<T>;
var
  I: Integer;
begin
  Result := TObjectList<T>.Create(True);
  try
    for I := 0 to FLista.Count - 1 do
    begin
      if MatchesWhere(FLista[I]) then
        Result.Add(CloneEntity(FLista[I]));
    end;
  finally
    if FUsarWhere then
      LimparWhere;
  end;
end;

function TMockDAO<T>.Count(const AFiltro: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FLista.Count - 1 do
  begin
    if MatchesWhere(FLista[I]) then
      Inc(Result);
  end;
  if FUsarWhere then
    LimparWhere;
end;

function TMockDAO<T>.Where(const ACampo: string; const AValor: TValue): IDAO<T>;
begin
  FWhereCampo := ACampo;
  FWhereValor := AValor;
  FUsarWhere := True;
  Result := Self;
end;

function TMockDAO<T>.LastId: Integer;
begin
  Result := FNextId - 1;
end;

procedure TMockDAO<T>.BeginTransaction;
begin
  if FInTransaction then
    Exit;

  FInTransaction := True;
  FSnapshotNextId := FNextId;

  if Assigned(FSnapshot) then
    FreeAndNil(FSnapshot);

  FSnapshot := TObjectList<T>.Create(True);
  CopyListTo(FLista, FSnapshot);
end;

procedure TMockDAO<T>.Commit;
begin
  if not FInTransaction then
    Exit;

  FInTransaction := False;
  if Assigned(FSnapshot) then
    FreeAndNil(FSnapshot);
end;

procedure TMockDAO<T>.Rollback;
begin
  if not FInTransaction then
    Exit;

  FInTransaction := False;
  if Assigned(FSnapshot) then
  begin
    CopyListTo(FSnapshot, FLista);
    FNextId := FSnapshotNextId;
    FreeAndNil(FSnapshot);
  end;
end;

end.
