unit uPnMVC.Router.JsxMgr;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Net.CrossHttpServer,
  Net.CrossHttpUtils,
  uPnMVC.Core,
  uPnMVC.Router.Base,
  //jseng
  uPnMVC.JsModule;

type
  { 实体路由(jsx)模块管理器 }
  TPnRouterJsxMgr = class(TPnRouterBase)
  const
    CONST_RouterPath = '/*.jsx';
  protected class threadvar
    FPnMVCView: TPnMVCView;
    FJsModuleMain: TJsModuleMain;
  protected
    function GetRouterPath: string; override;
  public
    constructor Create(AMVCEng: TPnMVCEngine); override;
    destructor Destroy; override;
    procedure RouterProc(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse); override;
    procedure TriggerThreadBegin(AThread: TThread); override;
    procedure TriggerThreadEnd(AThread: TThread); override;
  end;

implementation

uses
  uPnMVC.Router.PlugIn,
  qlog;


{ TPnRouterJsxMgr }
constructor TPnRouterJsxMgr.Create(AMVCEng: TPnMVCEngine);
var
  I: Integer;
  LModFile: string;
  hMod: HMODULE;
  LClsFinder: TClassFinder;
begin
  inherited Create(AMVCEng);
end;

destructor TPnRouterJsxMgr.Destroy;
begin
  inherited;
end;

function TPnRouterJsxMgr.GetRouterPath: string;
begin
  Result := CONST_RouterPath;
end;

procedure TPnRouterJsxMgr.RouterProc(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse);
var
  LUrl,
  LUrlFile: string;
//  LUrlFileText: string;
//  LViewName,
  LViewPath: string;
begin
  with FJsModuleMain do
  begin
    JsRequest.Request := ARequest;
    JsResponse.Response := AResponse;
    try
      try
        JsResponse.Clear;
        AResponse.StatusCode := 200;
        AResponse.ContentType := TMediaType.TEXT_HTML_UTF8;
        {$IFDEF MSWINDOWS}
        LUrl := StringReplace(ARequest.Path, '/', '\', [rfReplaceAll]);
        {$ELSEIF defined(LINUX)}
        LUrl := ARequest.Path;
        {$ENDIF}
        LUrlFile := MVCEng.Config.WebRoot + LUrl;
        //View
        //LViewName := ChangeFileExt(ExtractFileName(LUrl), '');
        LViewPath := IncludeTrailingPathDelimiter(ExtractFilePath(LUrl));
        JsMVCView.View.ViewPath := LViewPath;
        //FJsMVCView.ViewName := LViewName;
//        if not FileExists(LUrlFile) then
//          raise Exception.CreateFmt('File [%s] not found', [ARequest.Path]);
        //从文件读取jscode并运行
  //      LUrlFileText := TFile.ReadAllText(LUrlFile, TEncoding.UTF8);
  //      FNodeMain.Context.RunScript(LUrlFileText, ARequest.Path);
        FJsModuleMain.Execute(LUrlFile);
      except
        on E: Exception do
        begin
          AResponse.Send(E.Message);
        end;
      end;
    finally
      if not AResponse.Sent then
        AResponse.Send(JsResponse.RespOutput.ToString);
      JsResponse.Clear;
      //>500MB调用CollectGarbage
      if Runtime.MemoryUsage>(1024 * 1024 * 500) then
      begin
        Runtime.CollectGarbage;
        //PostLog(TQLogLevel.llMessage, 'Thread: %d, %d', [TThread.Current.ThreadID, FNodeMain.Runtime.MemoryUsage], '');
      end;
    end;
  end;
end;

procedure TPnRouterJsxMgr.TriggerThreadBegin(AThread: TThread);
begin
  FPnMVCView := TPnMVCView.Create(MVCEng);

  FJsModuleMain := TJsModuleMain.Create(MVCEng, FPnMVCView);
end;

procedure TPnRouterJsxMgr.TriggerThreadEnd(AThread: TThread);
begin
  if Assigned(FJsModuleMain) then
    FreeAndNil(FJsModuleMain);

  if Assigned(FPnMVCView) then
    FreeAndNil(FPnMVCView);
end;

initialization
  //注册Jsx模块管理器
  gPnRouterBases.RegisterClasses([TPnRouterJsxMgr]);

finalization
  gPnRouterBases.UnregisterClasses([TPnRouterJsxMgr]);

end.
