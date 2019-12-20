unit uPnMVC.JsObjMgr;

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
  uPnMVC.JsFDACConn, qlog;

type
  TJsConsoleLogEvent = procedure (Sender: TObject; const Text: UnicodeString; Level: TQLogLevel = llMessage) of object;

  { TJsConsole }
  TJsConsole = class(TNativeObject)
  private
    FOnLog: TJsConsoleLogEvent;

    function Assert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogError(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogInfo(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogNone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogWarn(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    procedure DoLog(const Text: UnicodeString; Level: TQLogLevel = llMessage); virtual;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;

    function Log(Args: PJsValueRef; ArgCount: Word; Level: TQLogLevel = llMessage): JsValueRef; overload;
    function Log(const Args: array of JsValueRef; Level: TQLogLevel = llMessage): JsValueRef; overload;

    property OnLog: TJsConsoleLogEvent read FOnLog write FOnLog;
  end;

  { TJsObjectManager }
  TJsObjectManager = class(TNativeObject)
  private
    FJsFDACConns: TJsFDACConns;
    function NewObject(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function ReleaseObject(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function formatjson(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
  end;

implementation

uses
  uPnMVC.JsHttpContext,
  qjson;

function FmtSpecPos(S: PWideChar): PWideChar;
var
  P: PWideChar;
begin
  Result := nil;

  P := WStrPos(S, '%');
  while Assigned(P) do
  begin
    case (P + 1)^ of
      #0:
        Break;
      'd', 'i', 'f', 'o', 's':
        begin
          Result := P;
          Break;
        end;
      '%':
        begin
          Inc(P);
          if P^ = #0 then
            Break;
        end;
    end;

    P := WStrPos(P + 1, '%');
  end;
end;

{ TJsConsole private }

function TJsConsole.Assert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  ArgCondition: JsValueRef;
  SMessage: UnicodeString;
begin
  Result := JsUndefinedValue;
  if ArgCount < 1 then
    Exit;

  SMessage := 'Assertion failed';

  // arg 1 = condition (boolean)
  ArgCondition := Args^;
  if (JsGetValueType(ArgCondition) <> JsBoolean) then
    raise Exception.Create('condition passed to console.assert not a boolean');

  Inc(Args);
  Dec(ArgCount);

  if (JsBooleanToBoolean(ArgCondition)) then // assertion passed
    Exit;

  if ArgCount = 0 then // no message/data
    DoLog(SMessage, llError)
  else
    Log(Args, ArgCount, llError);
end;

function TJsConsole.LogError(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, llError);
end;

function TJsConsole.LogInfo(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, llHint);
end;

function TJsConsole.LogNone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, llMessage);
end;

function TJsConsole.LogWarn(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, llWarning);
end;

{ TJsConsole protected }
procedure TJsConsole.DoLog(const Text: UnicodeString; Level: TQLogLevel);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, Text, Level);
end;

{ TJsConsole public }
constructor TJsConsole.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited Create(Args, ArgCount, AFinalize);
end;

destructor TJsConsole.Destroy;
begin
  inherited;
end;

function TJsConsole.Log(Args: PJsValueRef; ArgCount: Word; Level: TQLogLevel): JsValueRef;
var
  FirstArg, S, SCopy: UnicodeString;
  P, PPrev: PWideChar;
  Arg: PJsValueRef;
  I, ArgIndex: Integer;
begin
  Result := JsUndefinedValue;
  if not Assigned(Args) then
    Exit;

  S := '';
  P := nil;
  PPrev := nil;
  Arg := Args;
  ArgIndex := 0;
  if Assigned(Args) and (ArgCount > 0) and (JsGetValueType(Args^) = JsString) then
  begin
    FirstArg := JsStringToUnicodeString(Args^);
    PPrev := PWideChar(FirstArg);
    P := FmtSpecPos(PPrev);
  end;

  if Assigned(P) then
  begin
    Inc(Arg);
    Inc(ArgIndex);
    while Assigned(P) do
    begin
      if ArgIndex > ArgCount - 1 then
      begin
        SetString(SCopy, PPrev, (P - PPrev) + 2);
        S := S + WideStringReplace(SCopy, '%%', '%', [rfReplaceAll]);
      end
      else
      begin
        SetString(SCopy, PPrev, P - PPrev);
        S := S + WideStringReplace(SCopy, '%%', '%', [rfReplaceAll]);
        case (P + 1)^ of
          'd', 'i':
            S := S + UnicodeString(IntToStr(JsNumberToInt(Arg^)));
          'f':
            S := S + UnicodeString(FloatToStr(JsNumberToDouble(Arg^), DefaultFormatSettings));
          'o':
            S := S + JsInspect(Arg^);
          's':
            S := S + JsStringToUnicodeString(JsValueAsJsString(Arg^));
        end;
      end;

      PPrev := P + 2;
      P := FmtSpecPos(PPrev);
      Inc(Arg);
      Inc(ArgIndex);
    end;
    S := S + WideStringReplace(PPrev, '%%', '%', [rfReplaceAll]);
  end
  else
  begin
    for I := 0 to ArgCount - 1 do
    begin
      if S <> '' then
        S := S + ' ';
      S := S + JsStringToUnicodeString(JsValueAsJsString(Arg^));
      Inc(Arg);
    end;
  end;
  DoLog(S, Level);
end;

function TJsConsole.Log(const Args: array of JsValueRef; Level: TQLogLevel): JsValueRef;
var
  P: PJsValueRef;
  L: Integer;
begin
  P := nil;
  L := Length(Args);
  if L > 0 then
    P := @Args[0];
  Result := Log(P, L, Level);
end;

class procedure TJsConsole.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'assert', @TJsConsole.Assert);
  RegisterMethod(AInstance, 'log', @TJsConsole.LogNone);
  RegisterMethod(AInstance, 'info', @TJsConsole.LogInfo);
  RegisterMethod(AInstance, 'warn', @TJsConsole.LogWarn);
  RegisterMethod(AInstance, 'error', @TJsConsole.LogError);
  RegisterMethod(AInstance, 'exception', @TJsConsole.LogError);
end;


{ TJsObjectManager }
function TJsObjectManager.NewObject(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  LArgs: PJsValueRef;
  LClassName: string;
  LCacheName: string;
  LClass: TPersistentClass;
  ObjConn: TJsFDACConn;
  obj: TNativeObject;
begin
  Result := JsUndefinedValue;
  if Assigned(Args) and (ArgCount >= 1) and (JsGetValueType(Args^) = JsString) then
  begin
    LClassName := JsStringToUnicodeString(JsValueAsJsString(Args^));
    if (LClassName='TJsFDACConn') and (ArgCount>1) then
    begin
      LArgs := Args;
      Inc(LArgs);
      LCacheName := JsStringToUnicodeString(JsValueAsJsString(LArgs^));
      ObjConn := nil;
      if FJsFDACConns.ContainsKey(LCacheName) then
        ObjConn := FJsFDACConns.Items[LCacheName];
      if Assigned(ObjConn) then
      begin
        ObjConn.AddRef;
        Result := ObjConn.Instance;
        Exit;
      end
      else begin
        //对象已释放，删除对象
        if FJsFDACConns.ContainsKey(LCacheName) then
          FJsFDACConns.Remove(LCacheName);
      end;
    end;

    LClass := GetClass(LClassName);
    if not Assigned(LClass) then
      raise Exception.Create(Format('%s not found.',[LClassName]));
    obj := TNativeClass(LClass).Create;
    if (obj is TJsFDACConn) and (LCacheName<>'') then
    begin
      ObjConn := TJsFDACConn(Obj);
      ObjConn.CacheName := LCacheName;
      FJsFDACConns.AddOrSetValue(LCacheName, ObjConn);
    end;
    obj.AddRef;
    Result := obj.Instance;
  end;
end;

function TJsObjectManager.ReleaseObject(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  obj: TNativeObject;
  ObjConn: TJsFDACConn;
begin
  Result := JsUndefinedValue;
  if Assigned(Args) and (ArgCount >= 1) and (JsGetValueType(Args^) = JsObject) then
  begin
    obj := TNativeObject(JsGetExternalData(Args^));
    if obj<>nil then
    begin
      if (obj is TJsFDACConn) then
      begin
        ObjConn := TJsFDACConn(Obj);
        if ObjConn.CacheName<>'' then
          Exit;
      end;
      obj.Release;
      FreeAndNil(obj);
    end;
  end;
end;

function TJsObjectManager.formatjson(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  LArgs: PJsValueRef;
  compress: Boolean;
  sResult: string;
  JsonData: TQJson;
begin
  Result := JsNullValue;
  if not Assigned(Args)
    or (ArgCount < 2)
    or ((JsGetValueType(Args^) <> JsObject) and (JsGetValueType(Args^) <> JsArray)) then
    raise Exception.Create('ArgCount<2 or Args[0] not JsObject.');
  LArgs := Args;
  Inc(LArgs);
  compress := JsBooleanToBoolean(LArgs^);
  sResult := JsInspect(Args^);
  if compress then
  begin
    JsonData := TQJson.Create;
    try
      try
        JsonData.Parse(sResult);
        sResult := JsonData.Encode(True);
      except

      end;
    finally
      JsonData.Free;
    end;
  end;
  Result := StringToJsString(sResult);
end;

class procedure TJsObjectManager.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'NewObject', @TJsObjectManager.NewObject);
  RegisterMethod(AInstance, 'ReleaseObject', @TJsObjectManager.ReleaseObject);
  RegisterMethod(AInstance, 'formatjson', @TJsObjectManager.formatjson);
end;

constructor TJsObjectManager.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited;
  FJsFDACConns := TJsFDACConns.Create();
end;

destructor TJsObjectManager.Destroy;
var
  LConnArr: TArray<TPair<string, TJsFDACConn>>;
  LConn: TJsFDACConn;
  I: Integer;
begin
  LConnArr := FJsFDACConns.ToArray;
  for I := FJsFDACConns.Count-1 downto 0 do
  begin
    LConn := LConnArr[I].Value;
    if Assigned(LConn) then
      FreeAndNil(LConn);
  end;
  FJsFDACConns.Clear;
  FreeAndNil(FJsFDACConns);
  inherited;
end;

initialization
  RegisterClasses([TJsConsole]);

finalization
  UnRegisterClasses([TJsConsole]);

end.

