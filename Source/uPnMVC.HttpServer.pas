unit uPnMVC.HttpServer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  FMX.Memo,
  {$IFDEF __CROSS_SSL__}
  Net.CrossSslSocket,
  Net.CrossSslDemoCert,
  {$ENDIF}
  Net.CrossSocket.Base,
  Net.CrossHttpServer,
  Net.CrossWebSocketServer,
  uPnMVC.Core,
  lib.PnObject,
  lib.PnObjectPool,
  uPnMVC.Router.Base,
  qlog;

type
  TQLogVclMemoWriter = class(TQLogWriter)
  private
    FMemo: TMemo;
    FMaxLogLines: Word;
    procedure HandleNeeded; override;
  public
    constructor Create(AMemo: TMemo; AMaxLogLines: Word); overload;
    function WriteItem(AItem: PQLogItem): Boolean; override;
  end;

  IPnMVCHttpServer = interface(ICrossWebSocketServer)
  ['{A50735B0-71D6-4E26-B45C-46FF63358D98}']
    function GetMemo: TMemo;
    function GetMVCEng: TPnMVCEngine;
    function GetSentBytes: Int64;
    function GetRcvdBytes: Int64;
    function GetLastSent: Int64;
    function GetLastRcvd: Int64;
    function GetSendCount: Int64;
    function GetRcvdCount: Int64;
    function GetRunWatch: TStopwatch;
    function GetSendWatch: TStopwatch;
    function GetRecvWatch: TStopwatch;
    procedure SetMemo(const Value: TMemo);
    procedure SetLastSent(const Value: Int64);
    procedure SetLastRcvd(const Value: Int64);
    procedure SetSendWatch(const Value: TStopwatch);
    procedure SetRecvWatch(const Value: TStopwatch);
    property Memo: TMemo read GetMemo write SetMemo;
    property MVCEng: TPnMVCEngine read GetMVCEng;
    property SentBytes: Int64 read GetSentBytes;
    property RcvdBytes: Int64 read GetRcvdBytes;
    property LastSent: Int64 read GetLastSent write SetLastSent;
    property LastRcvd: Int64 read GetLastRcvd write SetLastRcvd;
    property SendCount: Int64 read GetSendCount;
    property RcvdCount: Int64 read GetRcvdCount;
    property RunWatch: TStopwatch read GetRunWatch;
    property SendWatch: TStopwatch read GetSendWatch write SetSendWatch;
    property RecvWatch: TStopwatch read GetRecvWatch write SetRecvWatch;

    procedure AddLog(const Fmt: string; const Args: array of const);
    procedure ForEach(AProc: TProc<ICrossWebSocketConnection>);
  end;

  TPnMVCHttpServer = class(TNetCrossWebSocketServer, IPnMVCHttpServer)
  private const
    WORK_SHUTDOWN_FLAG = Cardinal(-1);
  private
    FMemo: TMemo;
    FMVCEng: TPnMVCEngine;
    FRouterArr: TPnRouterBaseArr;
    FSentBytes, FRcvdBytes,
    FLastSent, FLastRcvd,
    FSendCount, FRcvdCount: Int64;
    FRunWatch, FSendWatch, FRecvWatch: TStopwatch;
    function GetMemo: TMemo;
    function GetMVCEng: TPnMVCEngine;
    function GetSentBytes: Int64;
    function GetRcvdBytes: Int64;
    function GetLastSent: Int64;
    function GetLastRcvd: Int64;
    function GetSendCount: Int64;
    function GetRcvdCount: Int64;
    function GetRunWatch: TStopwatch;
    function GetSendWatch: TStopwatch;
    function GetRecvWatch: TStopwatch;
    procedure SetMemo(const Value: TMemo);
    procedure SetLastSent(const Value: Int64);
    procedure SetLastRcvd(const Value: Int64);
    procedure SetSendWatch(const Value: TStopwatch);
    procedure SetRecvWatch(const Value: TStopwatch);
    procedure _OnReceived(Sender: TObject; AConnection: ICrossConnection;
      ABuf: Pointer; ALen: Integer);
    procedure _OnSent(Sender: TObject; AConnection: ICrossConnection;
      ABuf: Pointer; ALen: Integer);
    procedure _ProcChatMessage(AConnection: ICrossWebSocketConnection;
      const AChatMessage: string);
    //mvc模板demo
    procedure RouterPraseMvcViewDemo(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse);
    procedure _CreateRouter;
  protected
    procedure TriggerIoThreadBegin(AIoThread: TIoEventThread); override;
    procedure TriggerIoThreadEnd(AIoThread: TIoEventThread); override;
    procedure DoOnRequest(AConnection: ICrossHttpConnection); override;

  public
    property Memo: TMemo read GetMemo write SetMemo;
    property MVCEng: TPnMVCEngine read GetMVCEng;
    property SentBytes: Int64 read GetSentBytes;
    property RcvdBytes: Int64 read GetRcvdBytes;
    property LastSent: Int64 read GetLastSent write SetLastSent;
    property LastRcvd: Int64 read GetLastRcvd write SetLastRcvd;
    property SendCount: Int64 read GetSendCount;
    property RcvdCount: Int64 read GetRcvdCount;
    property RunWatch: TStopwatch read GetRunWatch;
    property SendWatch: TStopwatch read GetSendWatch write SetSendWatch;
    property RecvWatch: TStopwatch read GetRecvWatch write SetRecvWatch;
  public
    constructor Create(AIoThreads: Integer = 0; AMemo: TMemo = nil); overload;
    destructor Destroy; override;

    procedure AddLog(const Fmt: string; const Args: array of const);
    procedure ForEach(AProc: TProc<ICrossWebSocketConnection>);
  end;

implementation

uses
  System.IOUtils,
  Net.CrossHttpUtils,
  Utils.Utils,
  qstring,
  qjson
  ;

{ TQLogVclMemoWriter }

constructor TQLogVclMemoWriter.Create(AMemo: TMemo; AMaxLogLines: Word);
begin
  inherited Create;
  FMemo := AMemo;
  FMaxLogLines := AMaxLogLines;
end;

function TQLogVclMemoWriter.WriteItem(AItem: PQLogItem): Boolean;
var
  s: QStringW;
begin
//  if AItem.Level<>llMessage then
//  begin
//    Result := False;
//    Exit;
//  end;

  Result := True;
  s := FormatDateTime('hh:nn:ss.zzz', AItem.TimeStamp) + ' [' +
  IntToStr(AItem.ThreadId) + '] ' + StrDupX(@AItem.Text[0], AItem.MsgLen shr 1);

  //放入线程队列
  TThread.Queue(nil,
    procedure
    begin
      FMemo.Lines.BeginUpdate;
      try
        if FMemo.Lines.Count>FMaxLogLines then
          FMemo.Lines.Delete(0);
        FMemo.Lines.Add(s);
      finally
        FMemo.Lines.EndUpdate;
      end;
      FMemo.GoToTextEnd;
    end);
end;

procedure TQLogVclMemoWriter.HandleNeeded;
begin
end;


{ TPnMVCHttpServer }
constructor TPnMVCHttpServer.Create(AIoThreads: Integer = 0; AMemo: TMemo = nil);
var
  sConfigFile: string;
  LRouterClassArr: TPnRouterBaseClasses;
  LIoThreads: Integer;
  I: Integer;
begin
  sConfigFile := TPath.Combine(TUtils.AppPath, 'config.ini');
  FMVCEng := TPnMVCEngine.Create();
  with FMVCEng do
  begin
    if FileExists(sConfigFile) then
      Config.Load(sConfigFile);
    Config.WebRoot := TPath.Combine(TUtils.AppPath, Config.WebRoot);
    Config.ViewRootPath := TPath.Combine(TUtils.AppPath, Config.ViewRootPath);
    Config.ViewFileExt := 'html';
    //Config.Save('config.ini');
    LIoThreads := Config.ServerIoThreads;
  end;
  if LIoThreads<>0 then
    AIoThreads := LIoThreads;
  inherited Create(AIoThreads);
  Memo := AMemo;

  //取得所有注册模块并实例化
  LRouterClassArr := gPnRouterBases.GetClasses;
  SetLength(FRouterArr, Length(LRouterClassArr));
  for I := Low(LRouterClassArr) to High(LRouterClassArr) do
  begin
    FRouterArr[I] := TPnRouterBaseClass(LRouterClassArr[I]).Create(FMVCEng);
  end;

  OnReceived := _OnReceived;
  OnSent := _OnSent;
  {$IFDEF __CROSS_SSL__}
  SetCertificate(SSL_SERVER_CERT);
  SetPrivateKey(SSL_SERVER_PKEY);
  {$ENDIF}
  Compressible := True;

  FRunWatch := TStopwatch.StartNew;

  // 绑定WebSocket事件
  Self
  .OnOpen(
    procedure(AConnection: ICrossWebSocketConnection)
    begin
      AddLog('OnOpen [%s:%d]',
        [AConnection.PeerAddr, AConnection.PeerPort]);
    end)
  .OnMessage(
    procedure(AConnection: ICrossWebSocketConnection;
      ARequestType: TWsRequestType; const ARequestData: TBytes)
    var
      LMessage: string;
    begin
      LMessage := TEncoding.UTF8.GetString(ARequestData);

      _ProcChatMessage(AConnection, Format('[%s:%d]%s',
        [AConnection.PeerAddr, AConnection.PeerPort, LMessage]));

      AddLog('OnMessage [%s:%d]%s : %s',
        [AConnection.PeerAddr, AConnection.PeerPort,
         AConnection.Request.Path,
         LMessage]);
    end)
  .OnClose(
    procedure(AConnection: ICrossWebSocketConnection)
    begin
      AddLog('OnClose [%s:%d]',
        [AConnection.PeerAddr, AConnection.PeerPort]);
    end);

  _CreateRouter;
end;

destructor TPnMVCHttpServer.Destroy;
var
  I: Integer;
begin
  for I := Low(FRouterArr) to High(FRouterArr) do
  begin
    FreeAndNil(FRouterArr[I]);
  end;
  inherited Destroy;
  FreeAndNil(FMVCEng);
end;

procedure TPnMVCHttpServer.AddLog(const Fmt: string; const Args: array of const);
begin
  PostLog(TQLogLevel.llMessage, Format(Fmt, Args), '');
end;

procedure TPnMVCHttpServer.ForEach(AProc: TProc<ICrossWebSocketConnection>);
var
  LConnections: TArray<ICrossConnection>;
  LConnection: ICrossConnection;
begin
  LConnections := LockConnections.Values.ToArray;
  UnlockConnections;

  for LConnection in LConnections do
  begin
    if Assigned(AProc) then
      AProc(LConnection as ICrossWebSocketConnection);
  end;
end;

function TPnMVCHttpServer.GetMemo: TMemo;
begin
  Result := FMemo;
end;

function TPnMVCHttpServer.GetMVCEng: TPnMVCEngine;
begin
  Result := FMVCEng;
end;

function TPnMVCHttpServer.GetSentBytes: Int64;
begin
  Result := FSentBytes;
end;

function TPnMVCHttpServer.GetRcvdBytes: Int64;
begin
  Result := FRcvdBytes;
end;

function TPnMVCHttpServer.GetLastSent: Int64;
begin
  Result := FLastSent;
end;

function TPnMVCHttpServer.GetLastRcvd: Int64;
begin
  Result := FLastRcvd;
end;

function TPnMVCHttpServer.GetSendCount: Int64;
begin
  Result := FSendCount;
end;

function TPnMVCHttpServer.GetRcvdCount: Int64;
begin
  Result := FRcvdCount;
end;

function TPnMVCHttpServer.GetRunWatch: TStopwatch;
begin
  Result := FRunWatch;
end;

function TPnMVCHttpServer.GetSendWatch: TStopwatch;
begin
  Result := FSendWatch;
end;

function TPnMVCHttpServer.GetRecvWatch: TStopwatch;
begin
  Result := FRecvWatch;
end;

procedure TPnMVCHttpServer.SetMemo(const Value: TMemo);
var
  FMemoWriter: TQLogVclMemoWriter;
begin
  if Value<>nil then
  begin
    FMemo := Value;
    FMemoWriter := TQLogVclMemoWriter.Create(FMemo, 100);
    Logs.Castor.AddWriter(FMemoWriter);
    FMemoWriter.LazyMode := True;
  end;
end;

procedure TPnMVCHttpServer.SetLastSent(const Value: Int64);
begin
  FLastSent := Value;
end;

procedure TPnMVCHttpServer.SetLastRcvd(const Value: Int64);
begin
  FLastRcvd := Value;
end;

procedure TPnMVCHttpServer.SetSendWatch(const Value: TStopwatch);
begin
  FSendWatch := Value;
end;

procedure TPnMVCHttpServer.SetRecvWatch(const Value: TStopwatch);
begin
  FRecvWatch := Value;
end;

procedure TPnMVCHttpServer._OnReceived(Sender: TObject; AConnection: ICrossConnection;
  ABuf: Pointer; ALen: Integer);
begin
  AtomicIncrement(FRcvdCount);
  AtomicIncrement(FRcvdBytes, ALen);
end;

procedure TPnMVCHttpServer._OnSent(Sender: TObject; AConnection: ICrossConnection;
  ABuf: Pointer; ALen: Integer);
begin
  AtomicIncrement(FSendCount);
  AtomicIncrement(FSentBytes, ALen);
end;

procedure TPnMVCHttpServer._ProcChatMessage(AConnection: ICrossWebSocketConnection;
  const AChatMessage: string);
begin
  ForEach(
    procedure(LConnection: ICrossWebSocketConnection)
    begin
      LConnection.WsSend(AChatMessage);
    end);
end;

procedure TPnMVCHttpServer.RouterPraseMvcViewDemo(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse);
var
  JsonData: TQJson;
  JsonDataStr: string;
  LUrl,
  LViewName,
  LViewPath: string;
  LView: TPnMVCView;
  LOutHtml: UTF8String;
begin
  {$IFDEF MSWINDOWS}
  LUrl := StringReplace(ARequest.Path, '/', '\', [rfReplaceAll]);
  {$ELSEIF defined(LINUX)}
  LUrl := ARequest.Path;
  {$ENDIF}

  JsonData := TQJson.Create;
  try
    with JsonData.ForcePath('website') do
    begin
      ForcePath('sys_name').AsString := 'PnHttpServerMvc';
      ForcePath('page_title').AsString := 'test';
      ForcePath('name').AsString := 'PnHttpServerMvc 测试页面';
      ForcePath('url').AsString := LUrl;
    end;
    JsonDataStr := JsonData.Encode(False);
  finally
    FreeAndNil(JsonData);
  end;

  LView := TPnMVCView.Create(FMVCEng);
  try
    LViewName := ChangeFileExt(ExtractFileName(LUrl), '');
    LViewPath := IncludeTrailingPathDelimiter(ExtractFilePath(LUrl));
    LView.ViewPath := LViewPath;
    LView.LoadView(['test_head','test_headmast',LViewName,'test_foot'], JsonDataStr, LOutHtml);
  finally
    FreeAndNil(LView);
  end;
  AResponse.StatusCode := 200;
  AResponse.ContentType := TMediaType.TEXT_HTML_UTF8;
  AResponse.Send(LOutHtml);
end;

procedure TPnMVCHttpServer._CreateRouter;
var
  I: Integer;
begin
  //注册所有路由模块的处理方法
  for I := Low(FRouterArr) to High(FRouterArr) do
  begin
    All(FRouterArr[I].RouterPath, FRouterArr[I].RouterProc);
  end;
//  Index('/', FMVCEng.Config.WebRoot, nil);
  Dir('/', FMVCEng.Config.WebRoot);
  Get('/sysmanager/test',RouterPraseMvcViewDemo);
  Get('/hello',
    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse)
    begin
      AResponse.Send('Hello World');
    end);
end;

procedure TPnMVCHttpServer.TriggerIoThreadBegin(AIoThread: TIoEventThread);
var
  I: Integer;
begin
  //模块线程的初始化
  for I := Low(FRouterArr) to High(FRouterArr) do
    FRouterArr[I].TriggerThreadBegin(AIoThread);
end;

procedure TPnMVCHttpServer.TriggerIoThreadEnd(AIoThread: TIoEventThread);
var
  I: Integer;
begin
  //模块线程的结束
  for I := Low(FRouterArr) to High(FRouterArr) do
    FRouterArr[I].TriggerThreadEnd(AIoThread);
end;

procedure TPnMVCHttpServer.DoOnRequest(
  AConnection: ICrossHttpConnection);
begin
  AConnection.Response.Header['Server'] := FMVCEng.Config.ServerName;
  //Access-Control-Allow-Origin: http://localhost:3001  //该字段表明可供那个源跨域
  //Access-Control-Allow-Methods: GET, POST, PUT        // 该字段表明服务端支持的请求方法
  //Access-Control-Allow-Headers: X-Custom-Header
  AConnection.Response.Header['Access-Control-Allow-Origin'] := 'http://localhost:8080';
  AConnection.Response.Header['Access-Control-Allow-Methods'] := 'GET, POST';
  AConnection.Response.Header['Access-Control-Allow-Headers'] := '*';
  inherited;
end;

end.
