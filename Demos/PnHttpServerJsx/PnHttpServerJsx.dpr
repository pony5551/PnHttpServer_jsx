program PnHttpServerJsx;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmHttpServerMain in 'ufrmHttpServerMain.pas' {frmHttpServerMain},
  uPnMVC.Core in '..\..\Source\uPnMVC.Core.pas',
  uPnMVC.HttpServer in '..\..\Source\uPnMVC.HttpServer.pas',
  uPnMVC.Router.PlugIn in '..\..\PnMVCBase\uPnMVC.Router.PlugIn.pas',
  uPnMVC.Router.Base in '..\..\Source\uPnMVC.Router.Base.pas',
  uPnMVC.JsFDACConn in '..\..\JsEngineUnit\uPnMVC.JsFDACConn.pas',
  uPnMVC.JsHttpContext in '..\..\JsEngineUnit\uPnMVC.JsHttpContext.pas',
  uPnMVC.JsModule in '..\..\JsEngineUnit\uPnMVC.JsModule.pas',
  uPnMVC.JsObjMgr in '..\..\JsEngineUnit\uPnMVC.JsObjMgr.pas',
  uPnMVC.JsSQLPages in '..\..\JsEngineUnit\uPnMVC.JsSQLPages.pas',
  uPnMVC.FDACConn in '..\..\JsEngineUnit\uPnMVC.FDACConn.pas',
  uPnMVC.FDSQLPages in '..\..\JsEngineUnit\uPnMVC.FDSQLPages.pas',
  uPnMVC.Router.JsxMgr in '..\..\JsEngineUnit\uPnMVC.Router.JsxMgr.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutDown := True;

  Application.Initialize;
  Application.CreateForm(TfrmHttpServerMain, frmHttpServerMain);
  Application.Run;
end.


