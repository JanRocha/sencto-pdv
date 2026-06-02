unit FenixSQL;

interface

uses
  FenixRTTI,
  System.Generics.Collections;

type
  TFenixSQL<T: class> = class
  private
    FInstance: T;
    FFields: string;
    FWhere: string;
    FOrderBy: string;
    FGroupBy: string;
    FJoin: string;
    FSQL: string;
    FFirst: Integer;
    FSkip: Integer;
    FUsarFirst: Boolean;
    FUsarSkip: Boolean;
    FFenixRTTi: TFenixRTTI<T>;
  public
    constructor Create(pInstance: T);
    destructor Destroy; override;

    class function New(aInstance : T): TFenixSQL<T>;
    function Insert (): TSQLResult;
    function Update (): TSQLResult;
    function Delete (): TSQLResult;
    function Select (): TFenixSQL<T>;
    function SelectId(var pSQL: string): TFenixSQL<T>;
    function Fields (const pSQL: string): TFenixSQL<T>;
    function Where (const pSQL: string): TFenixSQL<T>;
    function OrderBy(const pSQL: string): TFenixSQL<T>;
    function GroupBy(const pSQL: string): TFenixSQL<T>;
    function Join (const pSQL: string): TFenixSQL<T>;
    function First(const AQuantidade: Integer): TFenixSQL<T>;
    function Skip(const AQuantidade: Integer): TFenixSQL<T>;
    function LastID(): string;
    function LastRecord(var aSQL: string): TFenixSQL<T>;
    function Generate(): string;
  end;

implementation

uses
  System.SysUtils;

{ TFenixSQL<T> }

constructor TFenixSQL<T>.Create(pInstance: T);
begin
  FInstance := pInstance;
  FFenixRTTi := TFenixRTTI<T>.Create(TObject(FInstance));
end;

function TFenixSQL<T>.Delete(): TSQLResult;
begin
  Result := FFenixRTTi.Delete();
end;

destructor TFenixSQL<T>.Destroy;
begin
  FFenixRTTi.Free();
  inherited;
end;

function TFenixSQL<T>.Fields(const pSQL: string): TFenixSQL<T>;
begin
  Result := Self;
  if Trim(pSQL) <> '' then
    FFields := pSQL;
end;

function TFenixSQL<T>.Generate: string;
begin
   var lFields: string;

  if Trim(FFields).IsEmpty then
  begin
    FFenixRTTi.Fields(lFields);
    Result := Format(FSQL, [lFields]);
  end
  else
    Result := Format(FSQL, [FFields]);

  if FUsarFirst then
  begin
    var lPaginacao: string;
    lPaginacao := 'FIRST ' + IntToStr(FFirst);
    if FUsarSkip then
      lPaginacao := lPaginacao + ' SKIP ' + IntToStr(FSkip);
    Result := StringReplace(Result, 'SELECT ', 'SELECT ' + lPaginacao + ' ', []);
  end;

  if Trim(FJoin) <> EmptyStr then
    Result := Result + ' ' + FJoin + ' ';

  if Trim(FWhere) <> EmptyStr then
    Result := Result + ' WHERE ' + FWhere;

  if Trim(FGroupBy) <> EmptyStr then
    Result := Result + ' GROUP BY ' + FGroupBy;

  if Trim(FOrderBy) <> EmptyStr then
    Result := Result + ' ORDER BY ' + FOrderBy;
end;

function TFenixSQL<T>.GroupBy(const pSQL: string): TFenixSQL<T>;
begin
  Result := Self;
  FGroupBy := FGroupBy + pSQL;
end;

function TFenixSQL<T>.Insert(): TSQLResult;
begin
  Result := FFenixRTTi.Insert();
end;

function TFenixSQL<T>.First(const AQuantidade: Integer): TFenixSQL<T>;
begin
  Result := Self;
  if AQuantidade > 0 then
  begin
    FFirst := AQuantidade;
    FUsarFirst := True;
  end;
end;

function TFenixSQL<T>.Skip(const AQuantidade: Integer): TFenixSQL<T>;
begin
  Result := Self;
  if AQuantidade > 0 then
  begin
    FSkip := AQuantidade;
    FUsarSkip := True;
  end;
end;

function TFenixSQL<T>.Join(const pSQL: string): TFenixSQL<T>;
begin
  Result := Self;
  FJoin := FJoin + ' ' + pSQL;
end;

function TFenixSQL<T>.LastID(): string;
const
  SQL = 'SELECT FIRST(1) %s FROM %s ORDER BY %s DESC';
begin
  var
    lClassName,
    lPK: String;

  FFenixRTTi.TableName(lClassName);
  FFenixRTTi.PrimaryKey(lPK);

  Result := Format(SQL, [lPK, lClassName, lPK]);
end;

function TFenixSQL<T>.LastRecord(var aSQL: string): TFenixSQL<T>;
const
  SQL_TEMPLATE = 'SELECT FIRST 1 * FROM %s ORDER BY %s DESC';
begin
  Result := Self;
  var lTableName: string;
  var lPK: string;
  FFenixRTTi.TableName(lTableName);
  FFenixRTTi.PrimaryKey(lPK);
  aSQL := Format(SQL_TEMPLATE, [lTableName, lPK]);
end;

class function TFenixSQL<T>.New(aInstance: T): TFenixSQL<T>;
begin
  Result := Self.Create(aInstance);
end;

function TFenixSQL<T>.OrderBy(const pSQL: string): TFenixSQL<T>;
begin
  Result := Self;
  FOrderBy := FOrderBy + pSQL;
end;

function TFenixSQL<T>.Select(): TFenixSQL<T>;
begin
  Result := Self;

  var lNomeTabela: string;
  FFenixRTTi.TableName(lNomeTabela);

  FSQL := 'SELECT %S FROM ' + lNomeTabela;

  {var lClassName, lFields: string;

  FFenixRTTi.Fields(lFields);
  FFenixRTTi.TableName(lClassName);


  if Trim(FFields) <> EmptyStr then
    pSQL := pSQL + ' SELECT ' + FFields
  else
    pSQL := pSQL + ' SELECT ' + lFields;
  pSQL := pSQL + ' FROM ' + lClassName;

  if Trim(FJoin) <> EmptyStr then
    pSQL := pSQL + ' ' + FJoin + ' ';

  if Trim(FWhere) <> EmptyStr then
    pSQL := pSQL + ' WHERE ' + FWhere;

  if Trim(FGroupBy) <> EmptyStr then
    pSQL := pSQL + ' GROUP BY ' + FGroupBy;

  if Trim(FOrderBy) <> EmptyStr then
    pSQL := pSQL + ' ORDER BY ' + FOrderBy;   }
end;

function TFenixSQL<T>.SelectId(var pSQL: string): TFenixSQL<T>;
begin
  Result := self;
  FWhere := ' ID = %d';
  pSQL := Select()
    .Fields('*')
    .Generate;
end;

function TFenixSQL<T>.Update(): TSQLResult;
begin
  Result := FFenixRTTi.Update();
end;

function TFenixSQL<T>.Where(const pSQL: string): TFenixSQL<T>;
begin
  Result := Self;
  FWhere := pSQL;
end;

end.
