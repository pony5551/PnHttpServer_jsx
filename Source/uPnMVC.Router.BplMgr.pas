unit uPnMVC.Router.BplMgr;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Net.CrossHttpServer,
  Net.CrossHttpUtils,
  uPnMVC.Core,
  uPnMVC.Router.Base,
  uPnMVC.HttpContext_I,
  uPnMVC.HttpContext,
  uPnMVC.DBPool;

type
  { 实体路由(dll/bpl/so)模块管理器 }
  TPnRouterBplMgr = class(TPnRouterBase)
  const
    CONST_RouterPath = '/*.do';
  private
    FMods: TList<HMODULE>;
    procedure ClsFinderGetClass(AClass: TPersistentClass);
  protected class threadvar
    FPnDBPool: TPnDBPool;
    FPnModMVCView: TPnModMVCView;
    FPnModHttpRequest: TPnModHttpRequest;
    FPnModHttpResponse: TPnModHttpResponse;
  protected
    function GetRouterPath: string; override;
  public
    constructor Create(AMVCEng: TPnMVCEngine); override;
    destructor Destroy; override;
    procedure RouterProc(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse); override;
    procedure TriggerThreadBegin(AThread: TThread); override;
    procedure TriggerThreadEnd(AThread: TThread); override;
  end;

  TPnPageMain = procedure(const APnDBPool: IPnDBPool;
    const AMVCView: IPnModMVCView;
    const ARequest: IPnModHttpRequest;
    const AResponse: IPnModHttpResponse); {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}

implementation

uses
  uPnMVC.Router.PlugIn,
  uPnMVC.WebConfig,
  uPnMVC.WebPageList,
  qlog;


{ TPnRouterBplMgr }
procedure TPnRouterBplMgr.ClsFinderGetClass(AClass: TPersistentClass);
var
  LPlugin: TPnRouterPlugBase;
  IPlug: IPnRouterPlug;
begin
  //debugEx('ClaseeName: %s, %s', [AClass.ClassName, AClass.ClassParent.ClassName]);
  if AClass.ClassParent.ClassName = 'TPnRouterPlugBase' then
  begin
    try
      LPlugin := TPnRouterPlugClass(AClass).Create;
      if LPlugin<>nil then
      begin
        IPlug := LPlugin as IPnRouterPlug;
        IPlug.SetServerInfo(@MVCEng.Config);
//        IPlug.SetPostLogProc(qlog.PostLog);
//        IPlug.SetWebConfig(gWebConfig);
//        IPlug.LoadPages(gPnWebPageList);

        PostLog(TQLogLevel.llAlert, '模块: [%s,%s] 加载成功.', [AClass.ClassName, IPlug.GetRemark], '');
      end;
    finally
      FreeAndNil(LPlugin);
    end;
  end;
end;


constructor TPnRouterBplMgr.Create(AMVCEng: TPnMVCEngine);
var
  I: Integer;
  LModFile: string;
  hMod: HMODULE;
  LClsFinder: TClassFinder;
begin
  inherited Create(AMVCEng);
  FMods := TList<HMODULE>.Create;
  for I := Low(MVCEng.Config.ServerModuleArr) to High(MVCEng.Config.ServerModuleArr) do
  begin
    {$IFDEF MSWINDOWS}
    LModFile := 'Plugins\' + Trim(MVCEng.Config.ServerModuleArr[I]) + '.bpl';
    {$ELSE}
    LModFile := 'Plugins/' + Trim(MVCEng.Config.ServerModuleArr[I]) + '.so';
    {$ENDIF}
    hMod := LoadPackage(LModFile);
    if hMod<>0 then
      FMods.Add(hMod);
  end;

  LClsFinder := TClassFinder.Create();
  try
    LClsFinder.GetClasses(ClsFinderGetClass);
  finally
    FreeAndNil(LClsFinder);
  end;
end;

destructor TPnRouterBplMgr.Destroy;
var
  I: Integer;
begin
  for I := FMods.Count-1 downto 0 do
  begin
    UnloadPackage(FMods.Items[I]);
    FMods.Delete(I);
  end;
  FreeAndNil(FMods);
  inherited;
end;

function TPnRouterBplMgr.GetRouterPath: string;
begin
  Result := CONST_RouterPath;
end;

procedure TPnRouterBplMgr.RouterProc(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse);
var
  LUrl,
  LUrlFile: string;
//  LUrlFileText: string;
//  LViewName,
  LViewPath: string;
  LPagePath: string;
  LPnPageMain: TPnPageMain;
begin
  FPnModHttpRequest.Request := ARequest;
  FPnModHttpResponse.Response := AResponse;
  try
    try
      FPnModHttpResponse.Clear;
      AResponse.StatusCode := 200;
      AResponse.ContentType := TMediaType.TEXT_HTML_UTF8;
      {$IFDEF MSWINDOWS}
      LUrl := StringReplace(ARequest.Path, '/', '\', [rfReplaceAll]);
      {$ELSEIF defined(LINUX)}
      LUrl := ARequest.Path;
      {$ENDIF}
      LUrlFile := MVCEng.Config.WebRoot + LUrl;
      //View
//      LViewName := ChangeFileExt(ExtractFileName(LUrl), '');
      LViewPath := IncludeTrailingPathDelimiter(ExtractFilePath(LUrl));
      FPnModMVCView.ViewPath := LViewPath;

      //页面入口函数
      @LPnPageMain := nil;
      LPagePath := ChangeFileExt(LowerCase(ARequest.Path),'');
      if gPnWebPageList.ContainsKey(LPagePath) then
      begin
        @LPnPageMain := gPnWebPageList.Items[LPagePath];
      end;

      if @LPnPageMain<>nil then
      begin
        LPnPageMain(FPnDBPool, FPnModMVCView, FPnModHttpRequest, FPnModHttpResponse);
      end
      else
        raise Exception.CreateFmt('File [%s] not found', [ARequest.Path]);

    except
      on E: Exception do
      begin
        AResponse.Send(E.Message);
      end;
    end;
  finally
    if not AResponse.Sent then
      AResponse.Send(FPnModHttpResponse.RespOutput.ToString);
    FPnModHttpResponse.Clear;
  end;
end;

procedure TPnRouterBplMgr.TriggerThreadBegin(AThread: TThread);
begin
  FPnDBPool := TPnDBPool.Create;
  FPnModMVCView := TPnModMVCView.Create(MVCEng);
  FPnModHttpRequest := TPnModHttpRequest.Create;
  FPnModHttpResponse := TPnModHttpResponse.Create;
end;

procedure TPnRouterBplMgr.TriggerThreadEnd(AThread: TThread);
begin
  if Assigned(FPnModHttpResponse) then
    FreeAndNil(FPnModHttpResponse);
  if Assigned(FPnModHttpRequest) then
    FreeAndNil(FPnModHttpRequest);
  if Assigned(FPnModMVCView) then
    FreeAndNil(FPnModMVCView);
  if Assigned(FPnDBPool) then
    FreeAndNil(FPnDBPool);
end;

initialization
  //注册Bpl模块管理器
  gPnRouterBases.RegisterClasses([TPnRouterBplMgr]);

finalization
  gPnRouterBases.UnregisterClasses([TPnRouterBplMgr]);

end.
