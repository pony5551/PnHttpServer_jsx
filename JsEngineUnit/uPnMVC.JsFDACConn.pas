unit uPnMVC.JsFDACConn;

interface

{$include common.inc}

uses
  System.SysUtils,
  System.Classes,
{$ifdef HAS_WIDESTRUTILS}
  System.WideStrUtils,
{$endif}
  System.Generics.Collections,
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses,
  uPnMVC.FDACConn,
  Datasnap.DBClient,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.Client, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef,
  FireDAC.Comp.UI, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageBin;

type
  TJsField = class;
  TJsFields = TDictionary<string, TJsField>;

  { TJsField }
  TJsField = class(TNativeObject)
  private
    FJsFields: TJsFields;
    FField: TField;
    //AsString
    function GetAsString: JsValueRef;
    procedure SetAsString(Value: JsValueRef);
    //AsInteger
    function GetAsInteger: JsValueRef;
    procedure SetAsInteger(Value: JsValueRef);
    //AsLongWord
    function GetAsLongWord: JsValueRef;
    procedure SetAsLongWord(Value: JsValueRef);
    //AsLargeInt
    function GetAsLargeInt: JsValueRef;
    procedure SetAsLargeInt(Value: JsValueRef);
    //AsFloat
    function GetAsFloat: JsValueRef;
    procedure SetAsFloat(Value: JsValueRef);
    //AsBoolean
    function GetAsBoolean: JsValueRef;
    procedure SetAsBoolean(Value: JsValueRef);
    //AsDateTime
    function GetAsDateTime: JsValueRef;
    procedure SetAsDateTime(Value: JsValueRef);
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;

    property JsFields: TJsFields read FJsFields write FJsFields;
    property Field: TField read FField write FField;
  end;

  { TJsFDQuery }
  TJsFDQuery = class(TNativeObject)
  private
    FJsFields: TJsFields;
    FFDQuery: TFDQuery;
    //Eof
    function GetEof: JsValueRef;
    function Next(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Insert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Edit(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Append(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Post(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function FieldByNameEx(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function FieldByName(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;

    property FDQuery: TFDQuery read FFDQuery write FFDQuery;
  end;

  TJsFDACConn = class;
  TJsFDACConns = TDictionary<string, TJsFDACConn>;

  { TJsFDACConn }
  TJsFDACConn = class(TNativeObject)
  private
    FCacheName: string;
    FPnFDACConn: TPnFDACConn;
    //CacheName
    function GetCacheName: JsValueRef;
    procedure SetCacheName(Value: JsValueRef);
    //DBServer
    function GetDBServer: JsValueRef;
    procedure SetDBServer(Value: JsValueRef);
    //DBUser
    function GetDBUser: JsValueRef;
    procedure SetDBUser(Value: JsValueRef);
    //DBPass
    function GetDBPass: JsValueRef;
    procedure SetDBPass(Value: JsValueRef);
    //DBName
    function GetDBName: JsValueRef;
    procedure SetDBName(Value: JsValueRef);
    function OpenDatabase(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function CloseDatabase(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function StrToSQL(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Execute(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function GetRs(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function CommandQuery(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function fetchone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;

    property CacheName: string read FCacheName write FCacheName;
    property Conn: TPnFDACConn read FPnFDACConn write FPnFDACConn;
  end;

implementation

uses
  System.DateUtils
//  {$IFDEF MSWINDOWS}
//  ,Winapi.Windows
//  {$ENDIF}
  ;

function DateToGMTDate(const ADateTime: TDateTime): Int64;
begin
  Result := MilliSecondsBetween(UnixDateDelta, TTimeZone.Local.ToUniversalTime(ADateTime));
end;

function GMTDateToDate(const AGMTDate: Int64): TDateTime;
begin
  Result := TTimeZone.Local.ToLocalTime(IncMilliSecond(UnixDateDelta, AGMTDate));
end;

{ TJsField }
function TJsField.GetAsString: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := StringToJsString(FField.AsString);
end;

procedure TJsField.SetAsString(Value: JsValueRef);
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  FField.AsString := JsStringToUnicodeString(Value);
end;

function TJsField.GetAsInteger: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := IntToJsNumber(FField.AsInteger);
end;

procedure TJsField.SetAsInteger(Value: JsValueRef);
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  FField.AsInteger := JsNumberToInt(Value);
end;

function TJsField.GetAsLongWord: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := DoubleToJsNumber(FField.AsLongWord);
end;

procedure TJsField.SetAsLongWord(Value: JsValueRef);
var
  nValue: Cardinal;
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  nValue := Trunc(JsNumberToDouble(Value));
  FField.AsLongWord := nValue;
end;

function TJsField.GetAsLargeInt: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := DoubleToJsNumber(FField.AsLargeInt);
end;

procedure TJsField.SetAsLargeInt(Value: JsValueRef);
var
  nValue: Int64;
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  nValue := Trunc(JsNumberToDouble(Value));
  FField.AsLargeInt := nValue;
end;

function TJsField.GetAsFloat: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := DoubleToJsNumber(FField.AsFloat);
end;

procedure TJsField.SetAsFloat(Value: JsValueRef);
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  FField.AsFloat := JsNumberToDouble(Value);
end;

function TJsField.GetAsBoolean: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := BooleanToJsBoolean(FField.AsBoolean);
end;

procedure TJsField.SetAsBoolean(Value: JsValueRef);
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  FField.AsBoolean := JsBooleanToBoolean(Value);
end;

function TJsField.GetAsDateTime: JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  Result := DoubleToJsNumber(DateToGMTDate(FField.AsDateTime));
end;

procedure TJsField.SetAsDateTime(Value: JsValueRef);
begin
  if not Assigned(FField) then
    raise Exception.Create('FField is null.');
  FField.AsDateTime := GMTDateToDate(Trunc(JsNumberToDouble(Value)));
end;

class procedure TJsField.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'AsString', False, False, @TJsField.GetAsString, @TJsField.SetAsString);
  RegisterNamedProperty(AInstance, 'AsInteger', False, False, @TJsField.GetAsInteger, @TJsField.SetAsInteger);
  RegisterNamedProperty(AInstance, 'AsLongWord', False, False, @TJsField.GetAsLongWord, @TJsField.SetAsLongWord);
  RegisterNamedProperty(AInstance, 'AsLargeInt', False, False, @TJsField.GetAsLargeInt, @TJsField.SetAsLargeInt);
  RegisterNamedProperty(AInstance, 'AsFloat', False, False, @TJsField.GetAsFloat, @TJsField.SetAsFloat);
  RegisterNamedProperty(AInstance, 'AsBoolean', False, False, @TJsField.GetAsBoolean, @TJsField.SetAsBoolean);
  RegisterNamedProperty(AInstance, 'AsDateTime', False, False, @TJsField.GetAsDatetime, @TJsField.SetAsDatetime);
end;


constructor TJsField.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited;
end;

destructor TJsField.Destroy;
begin
  inherited;
end;

{ TJsFDQuery }
function TJsFDQuery.GetEof: JsValueRef;
begin
  Result := JsFalseValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  Result := BooleanToJsBoolean(FFDQuery.Eof);
end;

function TJsFDQuery.Next(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  FFDQuery.Next;
end;

function TJsFDQuery.Insert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  FFDQuery.Insert;
end;

function TJsFDQuery.Edit(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  FFDQuery.Edit;
end;

function TJsFDQuery.Append(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  FFDQuery.Append;
end;

function TJsFDQuery.Post(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');
  FFDQuery.Post;
end;

function TJsFDQuery.FieldByNameEx(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  sName: string;
  LArgs: PJsValueRef;
  DataType: Integer;
  sValue: string;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');

  if not Assigned(Args) or (ArgCount < 2) or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  sName := JsStringToUnicodeString(JsValueAsJsString(Args^));
  LArgs := Args;
  Inc(LArgs);
  DataType := JsNumberToInt(LArgs^);

  case TFieldType(DataType) of
    ftString, ftFixedChar, ftMemo, ftAdt, ftGuid:
    begin
      sValue := FFDQuery.FieldByName(sName).AsString;
      Result := StringToJsString(sValue);
    end;

    ftWideString, ftFixedWideChar, ftWideMemo:
    begin
      sValue := FFDQuery.FieldByName(sName).AsString;
      Result := StringToJsString(sValue);
    end;

    ftSmallint, ftAutoInc, ftInteger, ftWord, {ftLongWord,} ftByte, {ftLargeint,} ftShortint:
    begin
      Result := IntToJsNumber(FFDQuery.FieldByName(sName).AsInteger);
    end;

    ftLongWord:
    begin
      Result := DoubleToJsNumber(FFDQuery.FieldByName(sName).AsLongWord);
    end;

    ftLargeint:
    begin
      Result := DoubleToJsNumber(FFDQuery.FieldByName(sName).AsLargeInt);
    end;

    ftTime, ftDate:
    begin
      Result := IntToJsNumber(FFDQuery.FieldByName(sName).AsInteger);
    end;

    ftDateTime, ftTimeStamp, ftTimeStampOffset:
    begin
      Result := DoubleToJsNumber(FFDQuery.FieldByName(sName).AsFloat);
    end;

    ftSingle, ftCurrency, ftFloat:
    begin
      Result := DoubleToJsNumber(FFDQuery.FieldByName(sName).AsExtended);
    end;

    ftBoolean:
    begin
      Result := BooleanToJsBoolean(FFDQuery.FieldByName(sName).AsBoolean);
    end;

  end;
end;

function TJsFDQuery.FieldByName(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  sName: string;
  JsField: TJsField;
begin
  Result := JsNullValue;
  if not Assigned(FFDQuery) then
    raise Exception.Create('FFDQuery is null.');

  if not Assigned(Args) or (ArgCount < 1) or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  sName := JsStringToUnicodeString(JsValueAsJsString(Args^));
  if FJsFields.ContainsKey(sName) then
    JsField := FJsFields.Items[sName]
  else begin
    JsField := TJsField.Create;
    FJsFields.AddOrSetValue(sName, JsField);
  end;

  JsField.AddRef;
  JsField.JsFields := FJsFields;
  JsField.Field := FFDQuery.FieldByName(sName);
  Result := JsField.Instance;
end;

class procedure TJsFDQuery.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'Eof', False, False, @TJsFDQuery.GetEof, nil);
end;

class procedure TJsFDQuery.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'Next', @TJsFDQuery.Next);
  RegisterMethod(AInstance, 'Insert', @TJsFDQuery.Insert);
  RegisterMethod(AInstance, 'Edit', @TJsFDQuery.Edit);
  RegisterMethod(AInstance, 'Append', @TJsFDQuery.Append);
  RegisterMethod(AInstance, 'Post', @TJsFDQuery.Post);
  //RegisterMethod(AInstance, 'FieldByNameEx', @TJsFDQuery.FieldByNameEx);
  RegisterMethod(AInstance, 'FieldByName', @TJsFDQuery.FieldByName);
end;

constructor TJsFDQuery.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited;
  FJsFields := TJsFields.Create();
  FFDQuery := nil;
end;

destructor TJsFDQuery.Destroy;
var
  LJsFieldArr: TArray<TPair<string, TJsField>>;
  LJsField: TJsField;
  I: Integer;
  sKey: string;
begin
  if Assigned(FFDQuery) then
    FreeAndNil(FFDQuery);
  if Assigned(FJsFields) then
  begin
    LJsFieldArr := FJsFields.ToArray;
    for I := FJsFields.Count-1 downto 0 do
    begin
      LJsField := LJsFieldArr[I].Value;
      if Assigned(LJsField) then
      begin
        LJsField.Release;
        FreeAndNil(LJsField);
      end;
      sKey := LJsFieldArr[I].Key;
      if sKey<>'' then
        FJsFields.Remove(sKey);
    end;
    FreeAndNil(FJsFields);
  end;
  inherited;
end;



{ TJsFDACConn }
function TJsFDACConn.GetCacheName: JsValueRef;
begin
  Result := StringToJsString(FCacheName);
end;

procedure TJsFDACConn.SetCacheName(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FCacheName := nValue;
end;

function TJsFDACConn.GetDBServer: JsValueRef;
begin
  Result := StringToJsString(FPnFDACConn.DBServer);
end;

procedure TJsFDACConn.SetDBServer(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FPnFDACConn.DBServer := nValue;
end;

function TJsFDACConn.GetDBUser: JsValueRef;
begin
  Result := StringToJsString(FPnFDACConn.DBUser);
end;

procedure TJsFDACConn.SetDBUser(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FPnFDACConn.DBUser := nValue;
end;

function TJsFDACConn.GetDBPass: JsValueRef;
begin
  Result := StringToJsString(FPnFDACConn.DBPass);
end;

procedure TJsFDACConn.SetDBPass(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FPnFDACConn.DBPass := nValue;
end;

function TJsFDACConn.GetDBName: JsValueRef;
begin
  Result := StringToJsString(FPnFDACConn.DBName);
end;

procedure TJsFDACConn.SetDBName(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FPnFDACConn.DBName := nValue;
end;

function TJsFDACConn.OpenDatabase(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  ReConnected: Boolean;
begin
  Result := JsNullValue;
  if not Assigned(Args) or (ArgCount < 1) or (JsGetValueType(Args^) <> JsBoolean) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsBoolean.');

  ReConnected := JsBooleanToBoolean(JsValueAsJsBoolean(Args^));
  FPnFDACConn.OpenDatabase(ReConnected);
end;

function TJsFDACConn.CloseDatabase(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsNullValue;
  FPnFDACConn.CloseDatabase;
end;

function TJsFDACConn.StrToSQL(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  Asql: string;
  sRetult: string;
begin
  Result := JsNullValue;
  if not Assigned(Args) or (ArgCount < 1) or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  Asql := JsStringToUnicodeString(JsValueAsJsString(Args^));
  sRetult := FPnFDACConn.StrToSQL(Asql);
  Result := StringToJsString(sRetult);
end;

function TJsFDACConn.Execute(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  Asql: string;
  bRetult: Boolean;
begin
  Result := JsFalseValue;
  if not Assigned(Args) or (ArgCount < 1) or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  Asql := JsStringToUnicodeString(JsValueAsJsString(Args^));
  bRetult := FPnFDACConn.Execute(Asql);
  Result := BooleanToJsBoolean(bRetult);
end;

function TJsFDACConn.GetRs(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  Asql: string;
  LJsFDQuery: TJsFDQuery;
begin
  Result := JsNullValue;
  if not Assigned(Args) or (ArgCount < 1) or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  Asql := JsStringToUnicodeString(JsValueAsJsString(Args^));
  LJsFDQuery := TJsFDQuery.Create;
  LJsFDQuery.FFDQuery := FPnFDACConn.GetRs(Asql);
  Result := LJsFDQuery.Instance;
end;

function TJsFDACConn.CommandQuery(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  LArgs1: PJsValueRef;
  ACmd: string;
  LFDQuery: TFDQuery;
  LJsFDQuery: TJsFDQuery;
  nResult: Integer;
begin
  Result := JsNullValue;
  if not Assigned(Args)
    or (ArgCount < 2)
    or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  ACmd := JsStringToUnicodeString(JsValueAsJsString(Args^));
  LArgs1 := PJsValueRef(NativeInt(Args)+1);
  if (JsGetValueType(LArgs1^) = JsObject) then
  begin
    LFDQuery := TFDQuery.Create(nil);
    nResult := FPnFDACConn.CommandQuery(ACmd, LFDQuery);
    LJsFDQuery := TJsFDQuery(JsGetExternalData(LArgs1^));
    LJsFDQuery.FFDQuery := LFDQuery;
  end
  else begin
    nResult := FPnFDACConn.CommandQuery(ACmd, nil);
  end;
  Result := IntToJsNumber(nResult);
end;

function TJsFDACConn.fetchone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  ASql: string;
  sResult: string;
begin
  Result := JsNullValue;
  if not Assigned(Args)
    or (ArgCount < 1)
    or (JsGetValueType(Args^) <> JsString) then
    raise Exception.Create('ArgCount<1 or Args[0] not JsString.');

  ASql := JsStringToUnicodeString(JsValueAsJsString(Args^));
  sResult := FPnFDACConn.fetchone(ASql);
  Result := StringToJsString(sResult);
end;

class procedure TJsFDACConn.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'CacheName', False, False, @TJsFDACConn.GetCacheName, @TJsFDACConn.SetCacheName);
  RegisterNamedProperty(AInstance, 'DBServer', False, False, @TJsFDACConn.GetDBServer, @TJsFDACConn.SetDBServer);
  RegisterNamedProperty(AInstance, 'DBUser', False, False, @TJsFDACConn.GetDBUser, @TJsFDACConn.SetDBUser);
  RegisterNamedProperty(AInstance, 'DBPass', False, False, @TJsFDACConn.GetDBPass, @TJsFDACConn.SetDBPass);
  RegisterNamedProperty(AInstance, 'DBName', False, False, @TJsFDACConn.GetDBName, @TJsFDACConn.SetDBName);
end;

class procedure TJsFDACConn.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'OpenDatabase', @TJsFDACConn.OpenDatabase);
  RegisterMethod(AInstance, 'CloseDatabase', @TJsFDACConn.CloseDatabase);
  RegisterMethod(AInstance, 'StrToSQL', @TJsFDACConn.StrToSQL);
  RegisterMethod(AInstance, 'Execute', @TJsFDACConn.Execute);
  RegisterMethod(AInstance, 'GetRs', @TJsFDACConn.GetRs);
  RegisterMethod(AInstance, 'CommandQuery', @TJsFDACConn.CommandQuery);
  RegisterMethod(AInstance, 'fetchone', @TJsFDACConn.fetchone);
end;

constructor TJsFDACConn.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited;
  FPnFDACConn := TPnFDACConn.Create;
end;

destructor TJsFDACConn.Destroy;
begin
  FreeAndNil(FPnFDACConn);
  inherited;
end;


initialization
  RegisterClasses([TJsFDQuery, TJsFDACConn]);

finalization
  UnRegisterClasses([TJsFDQuery, TJsFDACConn]);

end.
