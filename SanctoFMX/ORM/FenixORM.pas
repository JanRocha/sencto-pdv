{
  ORM para persistencia de dados
  Unit utilizando generics para receber as classe modelos e gravar no banco
}
unit FenixORM;

interface

uses
  FenixSQL,
  System.TypInfo,
  Rtti.Atributos,
  FenixRTTI,
  System.SysUtils,
  System.Classes,
  System.RTTI,
  System.JSON,
  System.Generics.Collections,
  FireDAC.Stan.Option,
  Firedac.stan.Param,
  FireDAC.Comp.Client,
  Data.DB,
  RESTRequest4D;

type
  TDataProviderMode = (dpmLocal, dpmCloud, dpmHybrid);

  THttpMethod = (hmGet, hmPost, hmPut, hmDelete);

  TFenixORM<T: class> = class
  private
    FPrimarykey: string;
    FNomeTabela: string;
    FConexao: TFDConnection;
    FClasse: TObject;
    FTransacaoExplicita: Boolean;
    FWhereCampo: string;
    FWhereValor: TValue;
    FUsarWhere: Boolean;
//    FDataSource: TDataSource;

    // Campos para modo cloud
    FModo: TDataProviderMode;  // dpmLocal (padrao), dpmCloud ou dpmHybrid
    FBaseURL: string;          // URL base da Cloud API
    FJWTToken: string;         // Token JWT para autenticacao cloud
    FRefreshToken: string;     // Refresh token para renovacao automatica
    FTokenExpiration: TDateTime; // Data/hora de expiracao do token

    function ExecutarQuery(const pSQL: string): Boolean;
    function ExecutarQueryParametrizada(const AResult: TSQLResult): Boolean;
    function Consultar(const pSQL: string): TFDQuery;
    procedure AplicarWhereParametrizado(const AQuery: TFDQuery);
    procedure LimparWhere;

    // Metodos privados para modo cloud
    procedure RefreshTokenSeNecessario;
    function ExecuteCloudRequest(const AMethod: THttpMethod; const AEndpoint: string;
      const ABody: string = ''): IResponse;
    function GetCloudEndpoint: string;
    function ObterOID(AEntity: T): string;
    function CloudInsert(AEntity: T): Boolean;
    function CloudUpdate(AEntity: T): Boolean;
    function CloudDelete(AEntity: T): Boolean;
    function CloudFind(const AId: Integer; AEntity: T): Boolean;
    function CloudFindByFilter(const AFilter: string; AEntity: T): Boolean;
    function CloudFindAll(const AFilter: string): TObjectList<T>;
    function CloudCount(const AFilter: string): Integer;
    function CloudLastId: Integer;
    function CloudRegistroExiste(const pOID: string): Integer;
    function EntityToJson(AEntity: T): string;
    procedure JsonToEntity(const AJson: string; AEntity: T);
  public
    property NomeTabela: string read FNomeTabela;
    property Modo: TDataProviderMode read FModo;
    function DataSource(pDataSource: TDataSource): TFenixORM<T>;

    function Find(): TFDQuery; overload;
    procedure Find(const pIdentificador: Integer; aValue: T); overload;
    procedure Find(const pSQL: string; pClasse: T); overload;
    procedure Find(pClasse: T;const pSQL: string); overload;
    function Find(const pSQL: string): TFDQuery; overload;

    function Insert(aValue: T): Boolean;
    function Update(aValue: T): Boolean;
    function Delete(aValue: T): Boolean;
    function Save(aValue: T): Boolean;
    function FindAll(const AFiltro: string = ''): TObjectList<T>;
    function Count(const AFiltro: string = ''): Integer;
    function Where(const ACampo: string; const AValor: TValue): TFenixORM<T>;
    function LastId(): Integer;
    function CarregarOID(const pNomeTabela: string; const pID: Integer): string;
    function RegistroExiste(const pOID: string): Integer;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
    procedure AtualizarTokens(const AJWTToken, ARefreshToken: string);
    constructor Create(const pConexao: TFDConnection); overload;
    constructor Create(const ABaseURL, AJWTToken: string); overload;
    destructor Destroy; override;
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils;

{ TFenixORM<T> }

function TFenixORM<T>.CarregarOID(
  const pNomeTabela: string;
  const pID: Integer): string;
begin
  var lSQL :=      'SELECT'
    + sLineBreak + '  OID'
    + sLineBreak + 'FROM'
    + sLineBreak + '  ' + pNomeTabela
    + sLineBreak + 'WHERE'
    + sLineBreak + '  (ID = :ID)';

  var lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FConexao;
    lQuery.SQL.Text := lSQL;
    lQuery.ParamByName('ID').AsInteger := pID;
    lQuery.Open();

    Result := lQuery.FieldByName('OID').AsString;
  finally
    lQuery.Free;
  end;
end;

function TFenixORM<T>.Consultar(const pSQL: string): TFDQuery;
begin
  var lOwner: TComponent := nil;
  if Assigned(FConexao) then
    lOwner := FConexao.Owner;

  Result := TFDQuery.Create(lOwner);
  Result.UpdateOptions.AssignedValues := [uvEDelete,uvEInsert,uvEUpdate,uvCountUpdatedRecords,uvCheckRequired,uvCheckReadOnly,uvCheckUpdatable];
  Result.Connection := FConexao;
  Result.Open(pSQL);
end;

constructor TFenixORM<T>.Create(const pConexao: TFDConnection);
begin
  FModo := dpmLocal;
  FConexao := pConexao;

  var lRTTI :=  TFenixRTTI<T>.Create(FClasse);
  try
    lRTTI.PrimaryKey(FPrimarykey);
    lRTTI.TableName(FNomeTabela);
  finally
    lRTTI.Free;
  end;
end;

constructor TFenixORM<T>.Create(const ABaseURL, AJWTToken: string);
begin
  FModo := dpmCloud;
  FBaseURL := ABaseURL;

  // Validar HTTPS em producao (permitir HTTP apenas em localhost para desenvolvimento)
  if (not FBaseURL.StartsWith('https://')) and
     (not FBaseURL.Contains('localhost')) and
     (not FBaseURL.Contains('127.0.0.1')) then
    raise Exception.Create('Cloud API requer HTTPS. URL informada: ' + FBaseURL);

  FJWTToken := AJWTToken;
  FConexao := nil;

  var lRTTI := TFenixRTTI<T>.Create(FClasse);
  try
    lRTTI.PrimaryKey(FPrimarykey);
    lRTTI.TableName(FNomeTabela);
  finally
    lRTTI.Free;
  end;
end;

function TFenixORM<T>.DataSource(pDataSource: TDataSource): TFenixORM<T>;
begin
  Result := Self;
  pDataSource.DataSet := Find();
end;

function TFenixORM<T>.Delete(aValue: T): Boolean;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudDelete(aValue);
    Exit;
  end;

  var lFenixSQL := TFenixSQL<T>.Create(TObject(aValue));
  try
    Result := ExecutarQueryParametrizada(lFenixSQL.Delete());
  finally
    lFenixSQL.free();
  end;
end;

destructor TFenixORM<T>.Destroy;
begin
  inherited;
end;

function TFenixORM<T>.ExecutarQuery(const pSQL: string): Boolean;
begin
 var lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FConexao;
    Result := lQuery.ExecSQL(pSQL) > 0;
    if not FTransacaoExplicita then
      FConexao.CommitRetaining;
  finally
    lQuery.Free();
  end;
end;

function TFenixORM<T>.ExecutarQueryParametrizada(const AResult: TSQLResult): Boolean;
begin
  var lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FConexao;
    lQuery.SQL.Text := AResult.SQL;

    for var lParam in AResult.Params do
    begin
      var lNomeParam := lParam.Nome;
      if lNomeParam.StartsWith(':') then
        lNomeParam := Copy(lNomeParam, 2, Length(lNomeParam) - 1);

      if lParam.IsNull then
      begin
        case lParam.TipoKind of
          tkInteger:
          begin
            lQuery.ParamByName(lNomeParam).DataType := ftInteger;
            lQuery.ParamByName(lNomeParam).Clear;
          end;
          tkInt64:
          begin
            lQuery.ParamByName(lNomeParam).DataType := ftLargeint;
            lQuery.ParamByName(lNomeParam).Clear;
          end;
          tkEnumeration:
          begin
            lQuery.ParamByName(lNomeParam).DataType := ftBoolean;
            lQuery.ParamByName(lNomeParam).Clear;
          end;
          tkFloat:
          begin
            if lParam.TipoNome = 'TDate' then
            begin
              lQuery.ParamByName(lNomeParam).DataType := ftDate;
              lQuery.ParamByName(lNomeParam).Clear;
            end
            else if lParam.TipoNome = 'TDateTime' then
            begin
              lQuery.ParamByName(lNomeParam).DataType := ftDateTime;
              lQuery.ParamByName(lNomeParam).Clear;
            end
            else if lParam.TipoNome = 'TTime' then
            begin
              lQuery.ParamByName(lNomeParam).DataType := ftTime;
              lQuery.ParamByName(lNomeParam).Clear;
            end
            else
            begin
              lQuery.ParamByName(lNomeParam).DataType := ftCurrency;
              lQuery.ParamByName(lNomeParam).Clear;
            end;
          end;
        else
          begin
            lQuery.ParamByName(lNomeParam).DataType := ftString;
            lQuery.ParamByName(lNomeParam).Clear;
          end;
        end;
      end
      else
      begin
        case lParam.TipoKind of
          tkInteger:
            lQuery.ParamByName(lNomeParam).AsInteger := lParam.Valor.AsInteger;
          tkInt64:
            lQuery.ParamByName(lNomeParam).AsLargeInt := lParam.Valor.AsInt64;
          tkEnumeration:
            lQuery.ParamByName(lNomeParam).AsBoolean := lParam.Valor.AsBoolean;
          tkFloat:
          begin
            if lParam.TipoNome = 'TDate' then
              lQuery.ParamByName(lNomeParam).AsDate := lParam.Valor.AsVariant
            else if lParam.TipoNome = 'TDateTime' then
              lQuery.ParamByName(lNomeParam).AsDateTime := lParam.Valor.AsVariant
            else if lParam.TipoNome = 'TTime' then
              lQuery.ParamByName(lNomeParam).AsTime := lParam.Valor.AsVariant
            else
              lQuery.ParamByName(lNomeParam).AsCurrency := lParam.Valor.AsCurrency;
          end;
        else
          lQuery.ParamByName(lNomeParam).AsString := lParam.Valor.AsString;
        end;
      end;
    end;

    lQuery.ExecSQL;
    Result := lQuery.RowsAffected > 0;
    if not FTransacaoExplicita then
      FConexao.CommitRetaining;
  finally
    lQuery.Free;
  end;
end;

procedure TFenixORM<T>.BeginTransaction;
begin
  FConexao.StartTransaction;
  FTransacaoExplicita := True;
end;

procedure TFenixORM<T>.Commit;
begin
  FConexao.Commit;
  FTransacaoExplicita := False;
end;

procedure TFenixORM<T>.Rollback;
begin
  if FConexao.InTransaction then
  begin
    FConexao.Rollback;
    FTransacaoExplicita := False;
  end;
end;

procedure TFenixORM<T>.Find(pClasse: T; const pSQL: string);
begin
  if FModo = dpmCloud then
  begin
    CloudFindByFilter(pSQL, pClasse);
    Exit;
  end;

  if FUsarWhere then
  begin
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL := lFenixSQL.Select().Fields('*').Generate();
      var lQuery := TFDQuery.Create(nil);
      try
        lQuery.Connection := FConexao;
        lQuery.SQL.Text := lSQL;
        AplicarWhereParametrizado(lQuery);
        lQuery.Open;
        TFenixRTTI<T>.SerializarObjeto(lQuery, pClasse);
      finally
        lQuery.Free;
      end;
    finally
      lFenixSQL.Free;
      LimparWhere;
    end;
  end
  else
  begin
    var lQuery: TFDQuery := nil;
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL: string;
      lSQL := lFenixSQL.Select().Fields('*').Where('(1=1) ').Generate();

      lSQL := lSQL + pSQL;

      lQuery := Consultar(lSQL);
      TFenixRTTI<T>.SerializarObjeto(lQuery, pClasse);
    finally
      lQuery.Free;
      lFenixSQL.Free;
    end;
  end;
end;

function TFenixORM<T>.Find(const pSQL: string): TFDQuery;
begin
  if FModo = dpmCloud then
  begin
    Result := nil; // TFDQuery nao suportado em modo cloud, usar FindAll
    Exit;
  end;

  Result := Consultar(StringReplace(UpperCase(pSQL), '%S', EmptyStr, [rfReplaceAll]));
end;

function TFenixORM<T>.Find: TFDQuery;
begin
  if FModo = dpmCloud then
  begin
    Result := nil; // TFDQuery nao suportado em modo cloud, usar FindAll
    Exit;
  end;

  var lSQL: string;
  var lFenixSQL:= TFenixSQL<T>.Create(nil);
  try
   // TFenixSQL<T>.New(nil).Select(lSQL);
    lSQL := lFenixSQL.Select().Fields('*').Generate();
    Result := Consultar(lSQL);
  finally
    lFenixSQL.Free;
  end;
end;

procedure TFenixORM<T>.Find(const pIdentificador: Integer; aValue: T);
begin
  if FModo = dpmCloud then
  begin
    CloudFind(pIdentificador, aValue);
    Exit;
  end;

  var lQuery: TFDQuery := nil;
  var lSQL := TFenixSQL<T>.Create(aValue);
  var lConsulta: string;
  try
    lSQL.SelectId(lConsulta);
    lQuery := Consultar(Format(lConsulta, [pIdentificador]));
    TFenixRTTI<T>.SerializarObjeto(lQuery, aValue);
  finally
    lSQL.Free;
    lQuery.Free;
  end;
end;

function TFenixORM<T>.Insert(aValue: T): Boolean;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudInsert(aValue);
    Exit;
  end;

  FClasse := aValue;
  var lFenixSQL := TFenixSQL<T>.Create(FClasse);
  try
    Result := ExecutarQueryParametrizada(lFenixSQL.Insert());
  finally
    lFenixSQL.free();
  end;
end;

function TFenixORM<T>.LastId: Integer;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudLastId;
    Exit;
  end;

  var lSQL: string;
  var lFenixSQL := TFenixSQL<T>.Create(FClasse);

  try
    lSQL := lFenixSQL.LastID();

    var lQuery := Consultar(lSQL);
    try
      Result := lQuery.FieldByName(FPrimarykey).AsInteger;
    finally
      lQuery.Free();
    end;
  finally
    lFenixSQL.Free;
  end;
end;

function TFenixORM<T>.RegistroExiste(const pOID: string): Integer;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudRegistroExiste(pOID);
    Exit;
  end;

  var lSQL :=      'SELECT'
    + sLineBreak + '  ID'
    + sLineBreak + 'FROM'
    + sLineBreak + '  ' + FNomeTabela
    + sLineBreak + 'WHERE'
    + sLineBreak + '  (OID = :OID)';

  var lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FConexao;
    lQuery.SQL.Text := lSQL;
    lQuery.ParamByName('OID').AsString := pOID;
    lQuery.Open();

    if lQuery.IsEmpty then
      Result := 0
    else
      Result := lQuery.FieldByName('ID').AsInteger;
  finally
    lQuery.Free;
  end;

end;

function TFenixORM<T>.Update(aValue: T): Boolean;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudUpdate(aValue);
    Exit;
  end;

  var lFenixSQL := TFenixSQL<T>.Create(TObject(aValue));
  try
    Result := ExecutarQueryParametrizada(lFenixSQL.Update());
  finally
    lFenixSQL.free();
  end;
end;

procedure TFenixORM<T>.Find(const pSQL: string; pClasse: T);
begin
  if FModo = dpmCloud then
  begin
    CloudFindByFilter(pSQL, pClasse);
    Exit;
  end;

  if FUsarWhere then
  begin
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL := lFenixSQL.Select().Fields('*').Generate();
      var lQuery := TFDQuery.Create(nil);
      try
        lQuery.Connection := FConexao;
        lQuery.SQL.Text := lSQL;
        AplicarWhereParametrizado(lQuery);
        lQuery.Open;
        TFenixRTTI<T>.SerializarObjeto(lQuery, pClasse);
      finally
        lQuery.Free;
      end;
    finally
      lFenixSQL.Free;
      LimparWhere;
    end;
  end
  else
  begin
    var lQuery: TFDQuery := nil;
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL: string;
      var lTermo: string := Copy(pSQL,0,6);
      if not lTermo.Contains('SELECT') then
      begin
        lSQL := lFenixSQL.Select().Fields('*').Where('(1=1) ').Generate();
      end;

      lSQL := lSQL + pSQL;

      lQuery := Consultar(lSQL);
      TFenixRTTI<T>.SerializarObjeto(lQuery, pClasse);
    finally
      lQuery.Free;
      lFenixSQL.Free;
    end;
  end;
end;

function TFenixORM<T>.Count(const AFiltro: string): Integer;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudCount(AFiltro);
    Exit;
  end;

  var lSQL := 'SELECT COUNT(*) AS QTD FROM ' + FNomeTabela;

  if AFiltro.Trim <> '' then
    lSQL := lSQL + ' WHERE ' + AFiltro;

  var lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FConexao;
    lQuery.Open(lSQL);

    if lQuery.IsEmpty then
      Result := 0
    else
      Result := lQuery.FieldByName('QTD').AsInteger;
  finally
    lQuery.Free;
  end;
end;

function TFenixORM<T>.FindAll(const AFiltro: string): TObjectList<T>;
begin
  if FModo = dpmCloud then
  begin
    Result := CloudFindAll(AFiltro);
    Exit;
  end;

  Result := TObjectList<T>.Create(True);

  if FUsarWhere then
  begin
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL := lFenixSQL.Select().Fields('*').Generate();
      var lQuery := TFDQuery.Create(nil);
      try
        lQuery.Connection := FConexao;
        lQuery.SQL.Text := lSQL;
        AplicarWhereParametrizado(lQuery);
        lQuery.Open;

        while not lQuery.Eof do
        begin
          var lContexto: TRttiContext;
          var lTipo := lContexto.GetType(T.ClassInfo);
          var lMetaClass := lTipo.AsInstance.MetaclassType;
          var lInstancia := T(lMetaClass.Create);
          TFenixRTTI<T>.SerializarObjeto(lQuery, lInstancia);
          Result.Add(lInstancia);
          lQuery.Next;
        end;
      finally
        lQuery.Free;
      end;
    finally
      lFenixSQL.Free;
      LimparWhere;
    end;
  end
  else
  begin
    var lFenixSQL := TFenixSQL<T>.Create(nil);
    try
      var lSQL: string;

      if AFiltro.Trim <> '' then
        lSQL := lFenixSQL.Select().Fields('*').Where(AFiltro).Generate()
      else
        lSQL := lFenixSQL.Select().Fields('*').Generate();

      var lQuery := Consultar(lSQL);
      try
        while not lQuery.Eof do
        begin
          var lContexto: TRttiContext;
          var lTipo := lContexto.GetType(T.ClassInfo);
          var lMetaClass := lTipo.AsInstance.MetaclassType;
          var lInstancia := T(lMetaClass.Create);
          TFenixRTTI<T>.SerializarObjeto(lQuery, lInstancia);
          Result.Add(lInstancia);
          lQuery.Next;
        end;
      finally
        lQuery.Free;
      end;
    finally
      lFenixSQL.Free;
    end;
  end;
end;

function TFenixORM<T>.Where(const ACampo: string; const AValor: TValue): TFenixORM<T>;
begin
  Result := Self;
  FWhereCampo := ACampo;
  FWhereValor := AValor;
  FUsarWhere := True;
end;

procedure TFenixORM<T>.AplicarWhereParametrizado(const AQuery: TFDQuery);
begin
  AQuery.SQL.Text := AQuery.SQL.Text + ' WHERE ' + FWhereCampo + ' = :PWHERE';

  case FWhereValor.Kind of
    tkInteger:
      AQuery.ParamByName('PWHERE').AsInteger := FWhereValor.AsInteger;
    tkInt64:
      AQuery.ParamByName('PWHERE').AsLargeInt := FWhereValor.AsInt64;
    tkFloat:
      AQuery.ParamByName('PWHERE').AsCurrency := FWhereValor.AsCurrency;
  else
    AQuery.ParamByName('PWHERE').AsString := FWhereValor.AsString;
  end;
end;

procedure TFenixORM<T>.LimparWhere;
begin
  FUsarWhere := False;
  FWhereCampo := '';
  FWhereValor := TValue.Empty;
end;

function TFenixORM<T>.Save(aValue: T): Boolean;
begin
  var lContexto: TRttiContext;
  var lTipo := lContexto.GetType(T.ClassInfo);

  for var lProp in lTipo.GetProperties do
  begin
    for var lAtributo in lProp.GetAttributes do
    begin
      if lAtributo is Pk then
      begin
        var lValorPk := lProp.GetValue(TObject(aValue)).AsInteger;
        if lValorPk = 0 then
          Result := Insert(aValue)
        else
          Result := Update(aValue);
        Exit;
      end;
    end;
  end;

  Result := False;
end;

{ === Metodos Cloud === }

function TFenixORM<T>.GetCloudEndpoint: string;
begin
  Result := FBaseURL + '/api/v1/' + LowerCase(FNomeTabela);
end;

function TFenixORM<T>.ObterOID(AEntity: T): string;
begin
  Result := '';
  var lContexto: TRttiContext;
  var lTipo := lContexto.GetType(T.ClassInfo);
  for var lProp in lTipo.GetProperties do
  begin
    if SameText(lProp.Name, 'OID') or SameText(lProp.Name, 'Oid') then
    begin
      Result := lProp.GetValue(TObject(AEntity)).AsString;
      Break;
    end;
  end;
end;

procedure TFenixORM<T>.RefreshTokenSeNecessario;
begin
  if FModo <> dpmCloud then
    Exit;
  if FRefreshToken.IsEmpty then
    Exit;

  // Se token expira em menos de 5 minutos, renovar
  if (FTokenExpiration > 0) and ((FTokenExpiration - Now) < (5 / 1440)) then
  begin
    try
      var lBody := '{"refresh_token":"' + FRefreshToken + '"}';
      var lRequest := TRequest.New
        .BaseURL(FBaseURL + '/auth/refresh')
        .ContentType('application/json')
        .AddBody(lBody)
        .Post;

      if lRequest.StatusCode = 200 then
      begin
        var lJson := TJSONObject.ParseJSONValue(lRequest.Content) as TJSONObject;
        if Assigned(lJson) then
        try
          FJWTToken := lJson.GetValue<string>('token', FJWTToken);
          var lExpiresIn := lJson.GetValue<Integer>('expires_in', 3600);
          FTokenExpiration := Now + (lExpiresIn / 86400);
        finally
          lJson.Free;
        end;
      end;
    except
      // Falha no refresh - continua com token atual
    end;
  end;
end;

procedure TFenixORM<T>.AtualizarTokens(const AJWTToken, ARefreshToken: string);
begin
  FJWTToken := AJWTToken;
  FRefreshToken := ARefreshToken;
  FTokenExpiration := Now + (1 / 24); // assume 1 hora de validade
end;

function TFenixORM<T>.ExecuteCloudRequest(const AMethod: THttpMethod;
  const AEndpoint: string; const ABody: string): IResponse;
begin
  RefreshTokenSeNecessario;

  var lRequest := TRequest.New
    .BaseURL(AEndpoint)
    .TokenBearer(FJWTToken)
    .ContentType('application/json')
    .Accept('application/json');

  if ABody <> '' then
    lRequest.AddBody(ABody);

  case AMethod of
    hmGet:    Result := lRequest.Get;
    hmPost:   Result := lRequest.Post;
    hmPut:    Result := lRequest.Put;
    hmDelete: Result := lRequest.Delete;
  end;
end;

function TFenixORM<T>.EntityToJson(AEntity: T): string;
begin
  Result := '';
  if not Assigned(TObject(AEntity)) then
    Exit;

  var lJsonObj := TJSONObject.Create;
  try
    var lContexto: TRttiContext;
    var lTipo := lContexto.GetType(T.ClassInfo);

    for var lProp in lTipo.GetProperties do
    begin
      if not lProp.IsReadable then
        Continue;

      // Ignora propriedades com atributo [Ignore] ou [NoSerialize]
      var lIgnorar := False;
      for var lAttr in lProp.GetAttributes do
      begin
        if (lAttr is Ignore) or (lAttr is NoSerialize) then
        begin
          lIgnorar := True;
          Break;
        end;
      end;
      if lIgnorar then
        Continue;

      var lNomeCampo := LowerCase(lProp.Name);
      var lValor := lProp.GetValue(TObject(AEntity));

      case lProp.PropertyType.TypeKind of
        tkInteger:
          lJsonObj.AddPair(lNomeCampo, TJSONNumber.Create(lValor.AsInteger));

        tkInt64:
          lJsonObj.AddPair(lNomeCampo, TJSONNumber.Create(lValor.AsInt64));

        tkFloat:
        begin
          var lTipoNome := lProp.PropertyType.Name;

          if lTipoNome = 'TDate' then
            lJsonObj.AddPair(lNomeCampo,
              FormatDateTime('yyyy-mm-dd', lValor.AsExtended))
          else if lTipoNome = 'TDateTime' then
            lJsonObj.AddPair(lNomeCampo,
              FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', lValor.AsExtended))
          else if lTipoNome = 'TTime' then
            lJsonObj.AddPair(lNomeCampo,
              FormatDateTime('hh:nn:ss', lValor.AsExtended))
          else if lTipoNome = 'Currency' then
            lJsonObj.AddPair(lNomeCampo, TJSONNumber.Create(lValor.AsCurrency))
          else
            lJsonObj.AddPair(lNomeCampo, TJSONNumber.Create(lValor.AsExtended));
        end;

        tkEnumeration:
          lJsonObj.AddPair(lNomeCampo, TJSONBool.Create(lValor.AsBoolean));

        tkString, tkLString, tkWString, tkUString:
          lJsonObj.AddPair(lNomeCampo, lValor.AsString);
      end;
    end;

    Result := lJsonObj.ToString;
  finally
    lJsonObj.Free;
  end;
end;

procedure TFenixORM<T>.JsonToEntity(const AJson: string; AEntity: T);
begin
  if AJson.Trim = '' then
    Exit;
  if not Assigned(TObject(AEntity)) then
    Exit;

  var lJsonObj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if not Assigned(lJsonObj) then
    Exit;

  try
    var lContexto: TRttiContext;
    var lTipo := lContexto.GetType(T.ClassInfo);

    for var lProp in lTipo.GetProperties do
    begin
      if not lProp.IsWritable then
        Continue;

      var lNomeCampo := LowerCase(lProp.Name);
      var lJsonValue := lJsonObj.GetValue(lNomeCampo);
      if not Assigned(lJsonValue) then
        Continue;

      case lProp.PropertyType.TypeKind of
        tkInteger:
          lProp.SetValue(TObject(AEntity),
            lJsonValue.GetValue<Integer>);

        tkInt64:
          lProp.SetValue(TObject(AEntity),
            lJsonValue.GetValue<Int64>);

        tkFloat:
        begin
          var lTipoNome := lProp.PropertyType.Name;

          if (lTipoNome = 'TDate') or (lTipoNome = 'TDateTime') then
          begin
            var lDateStr := lJsonValue.Value;
            lDateStr := StringReplace(lDateStr, 'T', ' ', []);
            lProp.SetValue(TObject(AEntity),
              TValue.From<TDateTime>(StrToDateTimeDef(lDateStr, 0)));
          end
          else if lTipoNome = 'TTime' then
          begin
            var lTimeStr := lJsonValue.Value;
            lProp.SetValue(TObject(AEntity),
              TValue.From<TDateTime>(StrToTimeDef(lTimeStr, 0)));
          end
          else if lTipoNome = 'Currency' then
          begin
            var lCurrVal: Currency;
            lCurrVal := lJsonValue.GetValue<Double>;
            lProp.SetValue(TObject(AEntity),
              TValue.From<Currency>(lCurrVal));
          end
          else
            lProp.SetValue(TObject(AEntity),
              lJsonValue.GetValue<Double>);
        end;

        tkEnumeration:
          lProp.SetValue(TObject(AEntity),
            lJsonValue.GetValue<Boolean>);

        tkString, tkLString, tkWString, tkUString:
          lProp.SetValue(TObject(AEntity), lJsonValue.Value);
      end;
    end;
  finally
    lJsonObj.Free;
  end;
end;

function TFenixORM<T>.CloudInsert(AEntity: T): Boolean;
begin
  var lJson := EntityToJson(AEntity);
  var lResponse := ExecuteCloudRequest(hmPost, GetCloudEndpoint, lJson);
  Result := lResponse.StatusCode = 201;
end;

function TFenixORM<T>.CloudUpdate(AEntity: T): Boolean;
begin
  var lOID := ObterOID(AEntity);
  var lJson := EntityToJson(AEntity);
  var lResponse := ExecuteCloudRequest(hmPut, GetCloudEndpoint + '/' + lOID, lJson);
  Result := lResponse.StatusCode = 200;
end;

function TFenixORM<T>.CloudDelete(AEntity: T): Boolean;
begin
  var lOID := ObterOID(AEntity);
  var lResponse := ExecuteCloudRequest(hmDelete, GetCloudEndpoint + '/' + lOID);
  Result := lResponse.StatusCode = 200;
end;

function TFenixORM<T>.CloudFind(const AId: Integer; AEntity: T): Boolean;
begin
  var lResponse := ExecuteCloudRequest(hmGet, GetCloudEndpoint + '/' + IntToStr(AId));
  Result := lResponse.StatusCode = 200;
  if Result then
    JsonToEntity(lResponse.Content, AEntity);
end;

function TFenixORM<T>.CloudFindByFilter(const AFilter: string; AEntity: T): Boolean;
begin
  var lEndpoint := GetCloudEndpoint + '?filter=' + AFilter;
  var lResponse := ExecuteCloudRequest(hmGet, lEndpoint);
  Result := False;
  if lResponse.StatusCode = 200 then
  begin
    var lJsonObj := TJSONObject.ParseJSONValue(lResponse.Content) as TJSONObject;
    if not Assigned(lJsonObj) then
      Exit;
    try
      var lDataArray := lJsonObj.GetValue<TJSONArray>('data');
      if Assigned(lDataArray) and (lDataArray.Count > 0) then
      begin
        JsonToEntity(lDataArray.Items[0].ToString, AEntity);
        Result := True;
      end;
    finally
      lJsonObj.Free;
    end;
  end;
end;

function TFenixORM<T>.CloudFindAll(const AFilter: string): TObjectList<T>;
begin
  Result := TObjectList<T>.Create(True);
  var lEndpoint := GetCloudEndpoint;
  if AFilter <> '' then
    lEndpoint := lEndpoint + '?filter=' + AFilter;

  var lResponse := ExecuteCloudRequest(hmGet, lEndpoint);
  if lResponse.StatusCode = 200 then
  begin
    var lJsonObj := TJSONObject.ParseJSONValue(lResponse.Content) as TJSONObject;
    if not Assigned(lJsonObj) then
      Exit;
    try
      var lDataArray := lJsonObj.GetValue<TJSONArray>('data');
      if Assigned(lDataArray) then
      begin
        for var i := 0 to lDataArray.Count - 1 do
        begin
          var lContexto: TRttiContext;
          var lTipo := lContexto.GetType(T.ClassInfo);
          var lMetaClass := lTipo.AsInstance.MetaclassType;
          var lEntity := T(lMetaClass.Create);
          JsonToEntity(lDataArray.Items[i].ToString, lEntity);
          Result.Add(lEntity);
        end;
      end;
    finally
      lJsonObj.Free;
    end;
  end;
end;

function TFenixORM<T>.CloudCount(const AFilter: string): Integer;
begin
  var lEndpoint := GetCloudEndpoint + '/count';
  if AFilter <> '' then
    lEndpoint := lEndpoint + '?filter=' + AFilter;

  var lResponse := ExecuteCloudRequest(hmGet, lEndpoint);
  if lResponse.StatusCode = 200 then
  begin
    var lJsonObj := TJSONObject.ParseJSONValue(lResponse.Content) as TJSONObject;
    if not Assigned(lJsonObj) then
    begin
      Result := 0;
      Exit;
    end;
    try
      Result := lJsonObj.GetValue<Integer>('count');
    finally
      lJsonObj.Free;
    end;
  end
  else
    Result := 0;
end;

function TFenixORM<T>.CloudLastId: Integer;
begin
  // No modo cloud, IDs sao gerenciados pelo servidor
  Result := 0;
end;

function TFenixORM<T>.CloudRegistroExiste(const pOID: string): Integer;
begin
  var lResponse := ExecuteCloudRequest(hmGet, GetCloudEndpoint + '/exists/' + pOID);
  if lResponse.StatusCode = 200 then
  begin
    var lJsonObj := TJSONObject.ParseJSONValue(lResponse.Content) as TJSONObject;
    if not Assigned(lJsonObj) then
    begin
      Result := 0;
      Exit;
    end;
    try
      Result := lJsonObj.GetValue<Integer>('id');
    finally
      lJsonObj.Free;
    end;
  end
  else
    Result := 0;
end;

end.
