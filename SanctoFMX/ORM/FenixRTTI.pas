unit FenixRTTI;

interface

uses
  System.Generics.Collections,
  Controller.Funcao,
  RTTI.Atributos,
  System.RTTI,
  System.SysUtils,
  Data.DB,
  System.TypInfo;

type
  TSQLParam = record
    Nome: string;
    Valor: TValue;
    TipoKind: TTypeKind;
    TipoNome: string;
    IsNull: Boolean;
  end;

  TSQLResult = record
    SQL: string;
    Params: TArray<TSQLParam>;
  end;

  TFenixRTTI<T: class> = class
  private
    FInstance: T;
    function EhPrimaryKey(const lprop: TRttiProperty): Boolean;
    function EhPrimaryKeymanual(const lprop: TRttiProperty): Boolean;
    class function ForeingKey(const lprop: TRttiProperty): Boolean;
    class function Ignorar(const lprop: TRttiProperty): Boolean;
    class function NaoSerializar(const lprop: TRttiProperty): Boolean;
    class function ObterNomeColuna(const AProp: TRttiProperty): string;
    function ConverterPropriedadeParaParam(const AProp: TRttiProperty; const AInstancia: TObject; const AIndice: Integer): TSQLParam;
    function EhAutoInc(const AProp: TRttiProperty; var AGenName: string): Boolean;
  public
    constructor Create(pInstance: T );
    destructor Destroy; override;

    function TableName(var pTableName: string): TFenixRTTI<T>;
    function PrimaryKey(var pPrimaryKey: string): TFenixRTTI<T>;

    function Fields(var pFields: string): TFenixRTTI<T>;
    function Insert(): TSQLResult;
    function Update(): TSQLResult;
    function Delete(): TSQLResult;
    class procedure SerializarObjeto(const lQuery: TDataSet; const lClasse: T);
  end;

implementation

{ TFenixRTTI<T> }

constructor TFenixRTTI<T>.Create(pInstance: T);
begin
  FInstance := pInstance;
end;

function TFenixRTTI<T>.Delete: TSQLResult;
begin
  var lProp: TRttiProperty;
  var lClasse: TObject;
  lClasse := TObject(FInstance);

  try
    var lContexto: TRttiContext;
    var lTipo := lContexto.GetType(T.ClassInfo);

    var lWhere: string;
    var lParams: TArray<TSQLParam>;

    for lProp in lTipo.GetProperties do
    begin
      if EhPrimaryKey(lProp) then
      begin
        var lNomeColuna := ObterNomeColuna(lProp);
        var lParam := ConverterPropriedadeParaParam(lProp, lClasse, 0);
        lWhere := ' WHERE ' + lNomeColuna + ' = ' + lParam.Nome;
        SetLength(lParams, 1);
        lParams[0] := lParam;
        Break;
      end;
    end;

    var lTableName: string;
    TableName(lTableName);

    Result.SQL := 'DELETE FROM ' + lTableName + lWhere;
    Result.Params := lParams;

  except on E: Exception do
    begin
      TControllerFuncao.GravarLog(E.Message + lProp.PropertyType.Name);
      raise;
    end;
  end;
end;

destructor TFenixRTTI<T>.Destroy;
begin
//  FInstance.free;
  inherited;
end;

function TFenixRTTI<T>.EhPrimaryKey(const lprop: TRttiProperty): Boolean;
begin
  Result := False;
  for var atributo in lprop.GetAttributes do
  begin
    if atributo is Pk then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TFenixRTTI<T>.EhPrimaryKeymanual(const lprop: TRttiProperty): Boolean;
begin
  Result := False;
  for var atributo in lprop.GetAttributes do
  begin
    if atributo is PkManual then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TFenixRTTI<T>.Fields(var pFields: string): TFenixRTTI<T>;
begin
  var lContexto: TRttiContext;
  var lTipo: TRttiType;
  var lPropriedade: TRttiProperty;
  var Informacao: PTypeInfo;

  Result := Self;
  Informacao := System.TypeInfo(T);
  lContexto := TRttiContext.Create;
  try
    lTipo := lContexto.GetType(Informacao);
    for lPropriedade in lTipo.GetProperties do
    begin
      if not NaoSerializar(lPropriedade) then
        pFields := pFields + ObterNomeColuna(lPropriedade) + ', ';
    end;
  finally
    pFields := Copy(pFields, 0, Length(pFields) - 2) + ' ';
    lContexto.Free;
  end;
end;

class function TFenixRTTI<T>.ForeingKey(const lprop: TRttiProperty): Boolean;
begin
  Result := False;
  for var atributo in lprop.GetAttributes do
  begin
    if atributo is Fk then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class function TFenixRTTI<T>.Ignorar(const lprop: TRttiProperty): Boolean;
begin
  Result := False;
  for var atributo in lprop.GetAttributes do
  begin
    if (atributo is Ignore) or (atributo is NoSerialize) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TFenixRTTI<T>.Insert: TSQLResult;
begin
  var lProp: TRttiProperty;
  var lClasse: TObject;
  lClasse := TObject(FInstance);

  try
    var lContexto: TRttiContext;
    var lTipo := lContexto.GetType(T.ClassInfo);
    var lCampos := '';
    var lValores := '';
    var lParams: TArray<TSQLParam>;
    var lIndice := 0;

    for lProp in lTipo.GetProperties do
    begin
      if EhPrimaryKey(lProp) then
      begin
        var lGenName: string;
        if EhAutoInc(lProp, lGenName) then
        begin
          lCampos := lCampos + ObterNomeColuna(lProp) + ',';
          lValores := lValores + 'GEN_ID(' + lGenName + ', 1),';
        end;
        Continue;
      end;

      if Ignorar(lProp) then
        Continue;

      lCampos := lCampos + ObterNomeColuna(lProp) + ',';

      var lParam := ConverterPropriedadeParaParam(lProp, lClasse, lIndice);
      lValores := lValores + lParam.Nome + ',';
      SetLength(lParams, Length(lParams) + 1);
      lParams[High(lParams)] := lParam;
      Inc(lIndice);
    end;

    lCampos := Copy(lCampos, 0, Length(lCampos) - 1);
    lValores := Copy(lValores, 0, Length(lValores) - 1);

    var lTableName: string;
    TableName(lTableName);

    Result.SQL := 'INSERT INTO ' + lTableName + ' (' + lCampos + ') VALUES (' + lValores + ')';
    Result.Params := lParams;

  except on E: Exception do
    begin
      TControllerFuncao.GravarLog(E.Message + lProp.PropertyType.Name);
      raise;
    end;
  end;
end;

function TFenixRTTI<T>.PrimaryKey(var pPrimaryKey: string): TFenixRTTI<T>;
begin
  Result := self;
  var lContexto: TRttiContext;
  var lTipo: TRttiType;
  var lPropriedade: TRttiProperty;
    
  Result := Self;
  lContexto := TRttiContext.Create;
  try
    lTipo := lContexto.GetType(T.ClassInfo);
    for lPropriedade in lTipo.GetProperties do
    begin
      for var atributo in lPropriedade.GetAttributes do
        if (atributo is Pk) then
        begin
          pPrimaryKey := lPropriedade.Name;
          break;
        end;
    end;
  finally
    lContexto.Free;
  end;
end;

class procedure TFenixRTTI<T>.SerializarObjeto(const lQuery: TDataSet; const lClasse: T);
var
  Contexto: TRttiContext;
  Tipo    : TRttiType;
  Prop    : TRttiProperty;
  lNomeColuna: string;
begin
  Tipo := Contexto.GetType(Tobject(lClasse).ClassInfo);
  for Prop in Tipo.GetProperties do
  begin
    if Ignorar(prop) then
        Continue;

    lNomeColuna := ObterNomeColuna(Prop);

    case Prop.PropertyType.TypeKind of
      tkInt64:
      begin
        if Assigned(lQuery.FindField(lNomeColuna)) then
          Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsLargeInt);
      end;
      tkInteger:
      begin
        if Assigned(lQuery.FindField(lNomeColuna)) then
          Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsInteger);
      end;
      tkEnumeration:
        if Prop.PropertyType.Name = 'Boolean' then
        begin
          if Assigned(lQuery.FindField(lNomeColuna)) then
            Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsBoolean);
        end;

      tkUString,
      tkLString,
      tkString,
      tkWString:
        if Assigned(lQuery.FindField(lNomeColuna)) then
          Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsString);
        tkFloat:
        begin
          if Assigned(lQuery.FindField(lNomeColuna)) then
            if (Prop.PropertyType.Name = 'TDate') or (Prop.PropertyType.Name = 'TDateTime') then
              Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsDateTime)
            else
              Prop.SetValue(Tobject(lClasse), lQuery.FieldByName(lNomeColuna).AsCurrency)
        end;
    end;
  end;
end;

class function TFenixRTTI<T>.NaoSerializar(const lprop: TRttiProperty): Boolean;
begin
  Result := False;
  for var atributo in lprop.GetAttributes do
  begin
    if atributo is NoSerialize then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TFenixRTTI<T>.TableName(var pTableName: string): TFenixRTTI<T>;
begin
  Result := self;

  var lTipo: PTypeInfo;
  var lContexto: TRttiContext;
  var lTttiTipo: TRttiType;

  lTipo := System.TypeInfo(T);
  lContexto := TRttiContext.Create;
  try
    lTttiTipo := lContexto.GetType(lTipo);

    for var atributo in lTttiTipo.GetAttributes do
      if atributo is Tabela then
        pTableName := (atributo as Tabela).Name;
  finally
    lContexto.Free;
  end;
end;

function TFenixRTTI<T>.Update: TSQLResult;
begin
  var lProp: TRttiProperty;
  var lClasse: TObject;
  lClasse := TObject(FInstance);

  try
    var lContexto: TRttiContext;
    var lTipo := lContexto.GetType(T.ClassInfo);
    var lValor := '';
    var lWhere: string;
    var lParams: TArray<TSQLParam>;
    var lIndice := 0;
    var lWhereParam: TSQLParam;

    for lProp in lTipo.GetProperties do
    begin
      if EhPrimaryKey(lProp) or EhPrimaryKeymanual(lProp) then
      begin
        var lNomeColuna := ObterNomeColuna(lProp);
        lWhereParam := ConverterPropriedadeParaParam(lProp, lClasse, lIndice);
        lWhere := ' WHERE ' + lNomeColuna + ' = ' + lWhereParam.Nome;
        Inc(lIndice);
        Continue;
      end;

      if Ignorar(lProp) then
        Continue;

      var lNomeColuna := ObterNomeColuna(lProp);
      var lParam := ConverterPropriedadeParaParam(lProp, lClasse, lIndice);
      lValor := lValor + lNomeColuna + ' = ' + lParam.Nome + ',';
      SetLength(lParams, Length(lParams) + 1);
      lParams[High(lParams)] := lParam;
      Inc(lIndice);
    end;

    lValor := Copy(lValor, 0, Length(lValor) - 1);

    // Adicionar parametro do WHERE ao final do array
    SetLength(lParams, Length(lParams) + 1);
    lParams[High(lParams)] := lWhereParam;

    var lTableName: string;
    TableName(lTableName);

    Result.SQL := 'UPDATE ' + lTableName + ' SET ' + lValor + lWhere;
    Result.Params := lParams;

  except on E: Exception do
    begin
      TControllerFuncao.GravarLog(E.Message + lProp.PropertyType.Name);
      raise;
    end;
  end;
end;

class function TFenixRTTI<T>.ObterNomeColuna(const AProp: TRttiProperty): string;
begin
  for var lAtributo in AProp.GetAttributes do
  begin
    if lAtributo is Campo then
    begin
      Result := (lAtributo as Campo).Name;
      Exit;
    end;
  end;
  Result := AProp.Name;
end;

function TFenixRTTI<T>.ConverterPropriedadeParaParam(const AProp: TRttiProperty; const AInstancia: TObject; const AIndice: Integer): TSQLParam;
begin
  Result.Nome := ':P' + IntToStr(AIndice);
  Result.TipoKind := AProp.PropertyType.TypeKind;
  Result.TipoNome := AProp.PropertyType.Name;
  Result.IsNull := False;
  Result.Valor := AProp.GetValue(AInstancia);

  case AProp.PropertyType.TypeKind of
    tkInteger,
    tkInt64:
    begin
      if (AProp.GetValue(AInstancia).AsInt64 <= 0) and ForeingKey(AProp) then
        Result.IsNull := True;
    end;
    tkEnumeration:
    begin
      // Boolean - valor ja atribuido acima
    end;
    tkFloat:
    begin
      if AProp.PropertyType.Name = 'TDate' then
      begin
        if (FormatDateTime('dd.mm.yyyy', AProp.GetValue(AInstancia).AsVariant) = '30.12.1899') or
           (FormatDateTime('dd.mm.yyyy', AProp.GetValue(AInstancia).AsVariant) = '00.00.0000') then
          Result.IsNull := True;
      end
      else if AProp.PropertyType.Name = 'TDateTime' then
      begin
        if (FormatDateTime('dd.mm.yyyy hh:mm:ss', AProp.GetValue(AInstancia).AsVariant) = '30.12.1899 00:00:00') or
           (FormatDateTime('dd.mm.yyyy hh:mm:ss', AProp.GetValue(AInstancia).AsVariant) = '00.00.0000 00:00:00') then
          Result.IsNull := True;
      end
      else if AProp.PropertyType.Name = 'TTime' then
      begin
        if FormatDateTime('hh:mm:ss', AProp.GetValue(AInstancia).AsVariant) = '00:00:00' then
          Result.IsNull := True;
      end;
      // Currency - valor ja atribuido acima
    end;
    // String e demais tipos - valor ja atribuido acima
  end;
end;

function TFenixRTTI<T>.EhAutoInc(const AProp: TRttiProperty; var AGenName: string): Boolean;
begin
  Result := False;
  for var lAtributo in AProp.GetAttributes do
  begin
    if lAtributo is AutoInc then
    begin
      AGenName := (lAtributo as AutoInc).GeneratorName;
      Result := True;
      Exit;
    end;
  end;
end;

end.
