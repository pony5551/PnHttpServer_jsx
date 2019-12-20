unit uPnMVC.Core;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  qjson,
  lib.PnLocker,
  lib.PnIniRec4Rtti;

type
  TPnMVCConfig = record
  type
    TPnMVCServerInfo = record
      [IniValue('ServerInfo','ServerPath','')]
      ServerPath: string;
      [IniValue('ServerInfo','ServerName','PnHttpServer/1.0')]
      ServerName: string;
      [IniValue('ServerInfo','ServerPort','8000')]
      ServerPort: Integer;
      [IniValue('ServerInfo','ServerIoThreads','0')]
      ServerIoThreads: Integer;
      [IniValue('ServerInfo','WebRoot','webroot')]
      WebRoot: string;
      [IniValue('ServerInfo','ViewRootPath','templates')]
      ViewRootPath: string;
      [IniValue('ServerInfo','ViewFileExt','html')]
      ViewFileExt: string;
    end;

  private
    ServerInfo: TPnMVCServerInfo;
    [IniValue('ServerModules','','')]
    ServerModules: string;

    function GetServerPath: string;
    procedure SetServerPath(const Value: string);
    function GetServerName: string;
    procedure SetServerName(const Value: string);
    function GetServerPort: Integer;
    procedure SetServerPort(const Value: Integer);
    function GetServerIoThreads: Integer;
    procedure SetServerIoThreads(const Value: Integer);
    function GetWebRoot: string;
    procedure SetWebRoot(const Value: string);
    function GetViewRootPath: string;
    procedure SetViewRootPath(const Value: string);
    function GetViewFileExt: string;
    procedure SetViewFileExt(const Value: string);
  public
    ServerModuleArr: TArray<string>;

    procedure Load(const CfgFile: string);
    procedure Save(const CfgFile: string);

    property ServerPath: string read GetServerPath write SetServerPath;
    property ServerName: string read GetServerName write SetServerName;
    property ServerPort: Integer read GetServerPort write SetServerPort;
    property ServerIoThreads: Integer read GetServerIoThreads write SetServerIoThreads;
    property WebRoot: string read GetWebRoot write SetWebRoot;
    property ViewRootPath: string read GetViewRootPath write SetViewRootPath;
    property ViewFileExt: string read GetViewFileExt write SetViewFileExt;
  end;

  { 模板缓存 }
  TPnMVCViewCache = class(TDictionary<string, UTF8String>)
  private
    FLocker: TPnLocker;
  public
    constructor Create;
    destructor Destroy; override;
    function GetViewCache(const ViewFile: string; IsSafe: Boolean = False): UTF8String;
    procedure SetViewCache(const ViewFile: string; ViewValue: UTF8String; IsSafe: Boolean = False);
  end;

  { MVC核心引擎 }
  TPnMVCEngine = class
  private
    FMVCConfig: TPnMVCConfig;
    FMVCViewCache: TPnMVCViewCache;
    function GetMVCViewCache: TPnMVCViewCache;
    procedure ConfigDefaultValues; virtual;
  public
    property Config: TPnMVCConfig read FMVCConfig;
    property MVCViewCache: TPnMVCViewCache read GetMVCViewCache;
  public
    constructor Create(ConfigProc: TProc<TPnMVCConfig> = nil);
    destructor Destroy; override;
  end;

  { Mustache模板渲染 }
  TPnMVCView = class
  private
    FMVCEng: TPnMVCEngine;
    FViewPath: string;
    FViewRootPath: string;
    FViewFileExt: string;
    function GetViewPath: string;
    function GetViewRootPath: string;
    function GetViewFileExt: string;
    procedure SetViewPath(const Value: string);
    procedure SetViewRootPath(const Value: string);
    procedure SetViewFileExt(const Value: string);
    function GetViewFileText(const ViewName: string): UTF8String;
  public
    property MVCEng: TPnMVCEngine read FMVCEng write FMVCEng;
    property ViewPath: string read GetViewPath write SetViewPath;
    property ViewRootPath: string read GetViewRootPath write SetViewRootPath;
    property ViewFileExt: string read GetViewFileExt write SetViewFileExt;
  public
    constructor Create(AMVCEng: TPnMVCEngine);
    destructor Destroy; override;
    procedure LoadView(const ViewNames: TArray<string>; const JsonData: string; var AOutput: UTF8String);
  end;

implementation

uses
  System.IOUtils
  {$ifdef MSWINDOWS},SynMustache{$endif}
  ;

{$IFDEF LINUX}
type
  TSetLengthBytes = procedure (var aBytes: TBytes; NewLength: Integer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}

function dmustacheParse1(
    tplStr: PAnsiChar;
    jsonStr: PAnsiChar;
    out outputstr: TBytes;
    SetLengthBytes: TSetLengthBytes): Integer; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
    external 'libdmustache.so' name 'dmustacheParse1';

procedure SetLengthBytes(var aBytes: TBytes; NewLength: Integer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  SetLength(aBytes, NewLength);
end;

{$ENDIF}

{ TPnMVCConfig }
procedure TPnMVCConfig.Load(const CfgFile: string);
begin
  TIniRec4Rtti.Load(CfgFile, @Self, TypeInfo(TPnMVCConfig));

  ServerInfo.ServerPath := GetCurrentDir;
  ServerModuleArr := ServerModules.Split([#13#10], TStringSplitOptions.ExcludeEmpty);
end;

procedure TPnMVCConfig.Save(const CfgFile: string);
var
  I: Integer;
begin
  ServerModules := '';
  for I := Low(ServerModuleArr) to High(ServerModuleArr) do
  begin
    ServerModules := ServerModuleArr[I];
  end;
  TIniRec4Rtti.Save(CfgFile, @Self, TypeInfo(TPnMVCConfig));
end;

function TPnMVCConfig.GetServerName: string;
begin
  Result := ServerInfo.ServerName;
end;

procedure TPnMVCConfig.SetServerName(const Value: string);
begin
  ServerInfo.ServerName := Value;
end;

function TPnMVCConfig.GetServerPath: string;
begin
  Result := ServerInfo.ServerPath;
end;

procedure TPnMVCConfig.SetServerPath(const Value: string);
begin
  ServerInfo.ServerPath := Value;
end;

function TPnMVCConfig.GetServerPort: Integer;
begin
  Result := ServerInfo.ServerPort;
end;

procedure TPnMVCConfig.SetServerPort(const Value: Integer);
begin
  ServerInfo.ServerPort := Value;
end;

function TPnMVCConfig.GetServerIoThreads: Integer;
begin
  Result := ServerInfo.ServerIoThreads;
end;

procedure TPnMVCConfig.SetServerIoThreads(const Value: Integer);
begin
  ServerInfo.ServerIoThreads := Value;
end;

function TPnMVCConfig.GetWebRoot: string;
begin
  Result := ServerInfo.WebRoot;
end;

procedure TPnMVCConfig.SetWebRoot(const Value: string);
begin
  ServerInfo.WebRoot := Value;
end;

function TPnMVCConfig.GetViewRootPath: string;
begin
  Result := ServerInfo.ViewRootPath;
end;

procedure TPnMVCConfig.SetViewRootPath(const Value: string);
begin
  ServerInfo.ViewRootPath := Value;
end;

function TPnMVCConfig.GetViewFileExt: string;
begin
  Result := ServerInfo.ViewFileExt;
end;

procedure TPnMVCConfig.SetViewFileExt(const Value: string);
begin
  ServerInfo.ViewFileExt := Value;
end;


{ TPnMVCViewCache }
constructor TPnMVCViewCache.Create;
begin
  inherited Create;
  FLocker := TPnLocker.Create('TMVCViewCache');
end;

destructor TPnMVCViewCache.Destroy;
begin
  FreeAndNil(FLocker);
  inherited;
end;

function TPnMVCViewCache.GetViewCache(const ViewFile: string; IsSafe: Boolean = False): UTF8String;
begin
  Result := '';
  if IsSafe then
  begin
    FLocker.Lock;
    try
      if ContainsKey(ViewFile) then
        Result := Items[ViewFile];
    finally
      FLocker.UnLock;
    end;
  end
  else begin
    if ContainsKey(ViewFile) then
      Result := Items[ViewFile];
  end;
end;

procedure TPnMVCViewCache.SetViewCache(const ViewFile: string; ViewValue: UTF8String; IsSafe: Boolean = False);
begin
  if IsSafe then
  begin
    FLocker.Lock;
    try
      AddOrSetValue(ViewFile, ViewValue);
    finally
      FLocker.UnLock;
    end;
  end
  else begin
    AddOrSetValue(ViewFile, ViewValue);
  end;
end;

{ TPnMVCEngine }

constructor TPnMVCEngine.Create(ConfigProc: TProc<TPnMVCConfig>);
begin
  inherited Create;
  //FMVCConfig := TPnMVCConfig.Create;
  //ConfigDefaultValues;
  if Assigned(ConfigProc) then
  begin
    ConfigProc(FMVCConfig);
  end;
  FMVCViewCache := TPnMVCViewCache.Create;
end;

destructor TPnMVCEngine.Destroy;
begin
  if Assigned(FMVCViewCache) then
    FreeAndNil(FMVCViewCache);
//  if Assigned(FMVCConfig) then
//    FreeAndNil(FMVCConfig);
  inherited;
end;

function TPnMVCEngine.GetMVCViewCache: TPnMVCViewCache;
begin
  Result := FMVCViewCache;
end;

procedure TPnMVCEngine.ConfigDefaultValues;
begin
//  Config[TMVCConfigKey.Server_Port] := '8000';
//  Config[TMVCConfigKey.Server_IoThreads] := '0';
//  Config[TMVCConfigKey.Server_PraseJSX] := 'true';
//  Config[TMVCConfigKey.Server_PrasePSX] := 'true';
//  Config[TMVCConfigKey.WebRoot] := 'webroot';
//  Config[TMVCConfigKey.ViewRootPath] := 'templates';
//  Config[TMVCConfigKey.ViewFileExt] := 'html';
//  Config[TMVCConfigKey.ServerName] := 'PnHttpServer/1.0';
end;

{ TPnMVCView }
constructor TPnMVCView.Create(AMVCEng: TPnMVCEngine);
begin
  inherited Create;
  FMVCEng := AMVCEng;
  if FMVCEng<>nil then
  begin
//    FViewRootPath := FMVCEng.Config[TMVCConfigKey.ViewRootPath];
//    FViewFileExt := FMVCEng.Config[TMVCConfigKey.ViewFileExt];

    FViewRootPath := FMVCEng.Config.ServerInfo.ViewRootPath;
    FViewFileExt := FMVCEng.Config.ServerInfo.ViewFileExt;
  end;
end;

destructor TPnMVCView.Destroy;
begin
  inherited;
end;

procedure TPnMVCView.LoadView(const ViewNames: TArray<System.string>; const JsonData: string; var AOutput: UTF8String);
var
  LViewName: string;
  LViewText: UTF8String;
  {$IFDEF MSWINDOWS}
  fViewTemplate: TSynMustache;
  {$ELSE}
  pOutputStr: TBytes;
  {$ENDIF}
begin
  AOutput := '';
  LViewText := '';
  for LViewName in ViewNames do
  begin
    LViewText := LViewText + GetViewFileText(LViewName);
  end;

  {$IFDEF MSWINDOWS}
  fViewTemplate := TSynMustache.Parse(LViewText);
  AOutput := fViewTemplate.RenderJSON(UTF8Encode(JsonData));
  {$ELSEIF defined(LINUX)}
  //linux
  dmustacheParse1(
    PAnsiChar(LViewText),
    PAnsiChar(UTF8Encode(JsonData)),
    pOutputStr,
    @SetLengthBytes);
  AOutput := PAnsiChar(@pOutputStr[0]);
  {$ENDIF}
end;

function TPnMVCView.GetViewPath: string;
begin
  Result := FViewPath;
end;

function TPnMVCView.GetViewRootPath: string;
begin
  Result := FViewRootPath;
end;

function TPnMVCView.GetViewFileExt: string;
begin
  Result := FViewFileExt;
end;

procedure TPnMVCView.SetViewPath(const Value: string);
begin
  FViewPath := Value;
end;

procedure TPnMVCView.SetViewRootPath(const Value: string);
begin
  FViewRootPath := Value;
end;

procedure TPnMVCView.SetViewFileExt(const Value: string);
begin
  FViewFileExt := Value;
end;

function TPnMVCView.GetViewFileText(const ViewName: string): UTF8String;
var
  LViewFile: string;
  LViewFileFull: string;
  LTemplate: UTF8String;
begin
  LViewFile :=  FViewPath + ViewName;
  LTemplate := FMVCEng.MVCViewCache.GetViewCache(LViewFile, True);
  if LTemplate<>'' then
  begin
    //从缓存读取
    Result := LTemplate;
  end
  else begin
    //从文件读取
    LViewFileFull := FViewRootPath + LViewFile + '.' + FViewFileExt;
    if not FileExists(LViewFileFull) then
      raise Exception.CreateFmt('View [%s] not found', [ViewName]);
    LTemplate := UTF8Encode(TFile.ReadAllText(LViewFileFull, TEncoding.UTF8));
    FMVCEng.FMVCViewCache.SetViewCache(LViewFile, LTemplate, True);
    Result := LTemplate;
  end;
end;

end.
