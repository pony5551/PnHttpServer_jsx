unit uPnMVC.JsModule;

interface

{$include common.inc}

uses
{$ifdef FPC}{$ifdef UNIX}
  cwstring,
{$endif}{$endif}
  SysUtils, Classes, Contnrs,
  System.Generics.Collections,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses,
  uPnMVC.Core,
  uPnMVC.JsObjMgr,
  uPnMVC.JsHttpContext,
  qlog;

type
  TJsModule = class
  private
    FBaseDir: UnicodeString;
    FFileName: UnicodeString;
    FFileData: UnicodeString;
    FHandle: JsvalueRef;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFile;

    property FileName: UnicodeString read FFileName;
    property Handle: JsValueRef read FHandle;
  end;
  TJsModules = TDictionary<string, TJsModule>;

  TJsModuleMain = class
  private
    FMVCEng: TPnMVCEngine;
    FPnMVCView: TPnMVCView;
    FBaseDir: UnicodeString;
    FModules: TJsModules;
    FRuntime: TChakraCoreRuntime;
    FContext: TChakraCoreContext;
    //JsObj
    FJsObjMgr: TJsObjectManager;
    FJsConsole: TJsConsole;
    FJsMVCView: TJsMVCView;
    FJsRequest: TJsHttpRequest;
    FJsResponse: TJsHttpResponse;
    //MainModle
    FMainModule: TJsModule;

    procedure ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
    procedure ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TQLogLevel = llMessage);

    function FindModule(const AFileName: UnicodeString): TJsModule;
    procedure LoadModule(Module: TJsModule; const FileName: UnicodeString);
    function Require(CallerModule: TJsModule; const Path: UnicodeString): JsValueRef;
    function Resolve(const Request, CurrentPath: UnicodeString): UnicodeString;
    function ResolveFile(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
  public
    constructor Create(AMVCEng: TPnMVCEngine; APnMVCView: TPnMVCView);
    destructor Destroy; override;
    procedure Execute(const FileName: UnicodeString);

    property BaseDir: UnicodeString read FBaseDir write FBaseDir;
    property Runtime: TChakraCoreRuntime read FRuntime;
    property Context: TChakraCoreContext read FContext;
    property JsObjMgr: TJsObjectManager read FJsObjMgr;
    property JsConsole: TJsConsole read FJsConsole;
    property JsMVCView: TJsMVCView read FJsMVCView;
    property JsRequest: TJsHttpRequest read FJsRequest;
    property JsResponse: TJsHttpResponse read FJsResponse;

  end;

implementation

uses
  System.IOUtils
//  {$IFDEF MSWINDOWS}
//  ,lib.PnDebug
//  {$ENDIF}
  ;

{ TJsModule }
constructor TJsModule.Create;
begin
  inherited Create;
  FFileData := '';
  FHandle := nil;
end;

destructor TJsModule.Destroy;
begin
  if Assigned(FHandle) then
    JsRelease(FHandle);
  FHandle := nil;
  inherited;
end;

procedure TJsModule.LoadFile;
begin
  if FFileData<>'' then Exit;
  if not FileExists(FFileName) then
    raise Exception.CreateFmt('File [%s] not found', [FFileName.Replace(FBaseDir,'',[rfReplaceAll, rfIgnoreCase])]);
  FFileData := TFile.ReadAllText(FFileName, TEncoding.UTF8);
end;

function JsInspectHandler(Value: JsValueRef; E: Exception): UnicodeString;
begin
  Result := WideFormat('[%s] %s', [E.ClassName, E.Message]);
end;

function Require_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  DataModule: TJsModuleMain absolute CallbackState;
  CallerModule: TJsModule;
  Path: UnicodeString;
begin
  Result := JsUndefinedValue;
  try
    if ArgCount <> 2 then
      raise Exception.Create('require: module name not specified');

    if JsGetValueType(Args^[1]) <> JsString then
      raise Exception.Create('require: module name not a string value');

    CallerModule := DataModule.FMainModule;
    //CallerModule := DataModule.FindModule(Callee);
    Path := JsStringToUnicodeString(Args^[1]);
    if PathDelim <> '/' then
      Path := UnicodeStringReplace(Path, '/', PathDelim, [rfReplaceAll]);

    Result := DataModule.Require(CallerModule, Path);
  except
    on E: EChakraCoreScript do
      JsThrowError(WideFormat('%s (%d, %d): [%s] %s', [E.ScriptURL, E.Line + 1, E.Column + 1, E.ClassName, E.Message]));
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

procedure TJsModuleMain.ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
begin
  if NativeObject is TJsConsole then
    TJsConsole(NativeObject).OnLog := ConsoleLog;

  if NativeObject is TJsMVCView then
  begin
    TJsMVCView(NativeObject).View := FPnMVCView;
    //TJsMVCView(NativeObject).View.MVCEng := FMVCEng;
  end;
end;

procedure TJsModuleMain.ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TQLogLevel = llMessage);
var
  S: UTF8String;
begin
  S := System.UTF8Encode(Text);
  PostLog(Level, S, '');
end;

function TJsModuleMain.FindModule(const AFileName: UnicodeString): TJsModule;
begin
  Result := nil;
  if FModules.ContainsKey(AFileName) then
    Result := FModules.Items[AFileName];
end;

procedure TJsModuleMain.LoadModule(Module: TJsModule; const FileName: UnicodeString);
begin
  //debugEx('LoadModule: %s', [FileName]);
  Module.FBaseDir := FBaseDir;
  Module.FFileName := FileName;
  Module.LoadFile;
  Module.FHandle := FContext.RunScript(Module.FFileData, FileName);
  if Assigned(Module.Handle) then
    JsAddRef(Module.Handle);
end;

function TJsModuleMain.Require(CallerModule: TJsModule; const Path: UnicodeString): JsValueRef;
var
  FileName: UnicodeString;
  Module: TJsModule;
begin
  Result := JsNullValue;
  //debugEx('Require: %s', [Path]);
  //Â·¾¶´¦Àí
  if Assigned(CallerModule) then
    FileName := Resolve(Path, ExtractFilePath(CallerModule.FileName))
  else
    FileName := Resolve(Path, FBaseDir);

  if FileName = '' then
    raise Exception.CreateFmt('Module ''%s'' not found', [Path]);

//  FileName := FBaseDir + Path;
//  FileName := ExpandFileName(FileName);

  Module := FindModule(FileName);
  if not Assigned(Module) then
  begin
    Module := TJsModule.Create;
    try
      FModules.AddOrSetValue(FileName, Module);
      LoadModule(Module, FileName);
    except
      on E: Exception do
      begin
        if (Module <> nil) and (Module <> FMainModule) then
        begin
          FModules.Remove(FileName);
          FreeAndNil(Module);
        end;
        raise;
      end;
    end;
  end
  else begin
    //debugEx('2: %p', [Module.Handle]);
    if Assigned(Module.Handle) then
      JsAddRef(Module.Handle);
  end;
end;

function TJsModuleMain.Resolve(const Request, CurrentPath: UnicodeString): UnicodeString;
var
  BasePaths: array[0..1] of UnicodeString;
  SRequest: UnicodeString;
  I: Integer;
begin
  //debugEx('Resolve: %s, %s', [Request, CurrentPath]);
  Result := '';
  if Request = '' then
    Exit;

  SRequest := Request;
  if SRequest[1] = '/' then
    BasePaths[0] := {$ifdef MSWINDOWS}ExtractFileDrive(CurrentPath){$else}''{$endif};
  if (SRequest[1] = PathDelim) or
    ((Length(SRequest) > 1) and (SRequest[1] = '.') and (SRequest[2] = PathDelim)) or
    ((Length(SRequest) > 2) and (SRequest[1] = '.') and (SRequest[2] = '.') and (SRequest[3] = PathDelim)) then
    BasePaths[0] := CurrentPath;
  BasePaths[1] := FBaseDir;

  if PathDelim <> '/' then
    SRequest := UnicodeStringReplace(SRequest, '/', PathDelim, [rfReplaceAll]);

  for I := Low(BasePaths) to High(BasePaths) do
  begin
    if ResolveFile(ExpandFileName(IncludeTrailingPathDelimiter(BasePaths[I]) + SRequest), Result) then
      Exit;
  end;
end;

function TJsModuleMain.ResolveFile(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
begin
  //debugEx('ResolveFile: %s', [Request]);
  Result := False;
  FileName := '';

  if FileExists(Request) then
  begin
    FileName := Request;
    Result := True;
  end
  else if FileExists(Request + '.js') then
  begin
    FileName := Request + '.js';
    Result := True;
  end;
end;

constructor TJsModuleMain.Create(AMVCEng: TPnMVCEngine; APnMVCView: TPnMVCView);
begin
  inherited Create;
  FMVCEng := AMVCEng;
  FPnMVCView := APnMVCView;
  JsInspectExceptionHandler := JsInspectHandler;
  //FBaseDir := GetCurrentDir;
  //FBaseDir := FMVCEng.Config[TMVCConfigKey.WebRoot];
  FBaseDir := FMVCEng.Config.WebRoot;
  //ccroDisableBackgroundWork
  //ccroEnableExperimentalFeatures
  //ccroDispatchSetExceptionsToDebugger
  FRuntime := TChakraCoreRuntime.Create([]);
  FContext := TChakraCoreContext.Create(FRuntime);
  FContext.OnNativeObjectCreated := ContextNativeObjectCreated;
  FContext.Activate;

  JsSetCallback(FContext.Global, 'require', @Require_Callback, Self);
  FModules := TJsModules.Create;

  //JsObj======begin
  FJsObjMgr := TJsObjectManager.Create;
  JsSetProperty(FContext.Global, 'JsObjMgr', FJsObjMgr.Instance);

  //TJsConsole.Project;
  FJsConsole := TJsConsole.Create;
  FJsConsole.OnLog := ConsoleLog;
  JsSetProperty(FContext.Global, 'console', FJsConsole.Instance);

  //TJsMVCView.Project;
  FJsMVCView := TJsMVCView.Create;
  FJsMVCView.View := FPnMVCView;
  JsSetProperty(FContext.Global, 'JsMVCView', FJsMVCView.Instance);

  FJsRequest := TJsHttpRequest.Create;
  JsSetProperty(FContext.Global, 'Request', FJsRequest.Instance);

  FJsResponse := TJsHttpResponse.Create;
  JsSetProperty(FContext.Global, 'Response', FJsResponse.Instance);
end;

destructor TJsModuleMain.Destroy;
var
  I: Integer;
  LModuleArr: TArray<TJsModule>;
  LModule: TJsModule;
  sKey: string;
begin
  if Assigned(FJsResponse) then
    FreeAndNil(FJsResponse);
  if Assigned(FJsRequest) then
    FreeAndNil(FJsRequest);
  if Assigned(FJsMVCView) then
    FreeAndNil(FJsMVCView);
  if Assigned(FJsConsole) then
    FreeAndNil(FJsConsole);
  if Assigned(FJsObjMgr) then
    FreeAndNil(FJsObjMgr);
  //JsObj======end
  if Assigned(FModules) then
  begin
    LModuleArr := FModules.Values.ToArray;
    for I := FModules.Count-1 downto 0 do
    begin
      LModule := LModuleArr[I];
      sKey := LModule.FileName;
      FreeAndNil(LModule);
      FModules.Remove(sKey);
    end;
    FreeAndNil(FModules);
  end;
  if Assigned(FContext) then
    FreeAndNil(FContext);
  if Assigned(FRuntime) then
    FreeAndNil(FRuntime);
  inherited;
end;

procedure TJsModuleMain.Execute(const FileName: UnicodeString);
var
  FullFileName: UnicodeString;
  LModule: TJsModule;
begin
  FullFileName := ExpandFileName(FileName);

//  FMainModule := TJsModule.Create;
//  try
//    LoadModule(FMainModule, FullFileName);
//  finally
//    FreeAndNil(FMainModule);
//  end;

  LModule := FindModule(FullFileName);
  if Assigned(LModule) then
  begin
    FMainModule := LModule;
    LoadModule(LModule, FullFileName);
  end
  else begin
    LModule := TJsModule.Create;
    try
      FMainModule := LModule;
      FModules.AddOrSetValue(FullFileName, LModule);
      LoadModule(LModule, FullFileName);
    except
      on E: Exception do
      begin
        if LModule<>nil then
        begin
          FMainModule := nil;
          FModules.Remove(FullFileName);
          FreeAndNil(LModule);
        end;
        raise;
      end;
    end;
  end;

end;


end.
