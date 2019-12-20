unit ufrmHttpServerMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox,
  FMX.Memo, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Objects, FMX.TabControl,
  System.Diagnostics,
  Net.CrossSocket.Base,
  Net.CrossWebSocketServer,
  uPnMVC.HttpServer;

type
  TfrmHttpServerMain = class(TForm)
    pnl1: TPanel;
    pnl2: TPanel;
    btnStart: TButton;
    btnBoardcast: TButton;
    btnCloseAll: TButton;
    MagicDock4: TRectangle;
    labelConns: TLabel;
    labelRcvData: TLabel;
    labelSndData: TLabel;
    labelSndSpeed: TLabel;
    labelRcvSpeed: TLabel;
    labelTime: TLabel;
    labelRcvCount: TLabel;
    labelSndCount: TLabel;
    tmr1: TTimer;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Memo1: TMemo;
    procedure btnStartClick(Sender: TObject);
    procedure btnBoardcastClick(Sender: TObject);
    procedure btnCloseAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure Memo1ApplyStyleLookup(Sender: TObject);
  private
    { Private declarations }
    FBounds: TBounds;
    FPnMVCHttpServer: IPnMVCHttpServer;
  public
    { Public declarations }
  end;

var
  frmHttpServerMain: TfrmHttpServerMain;

implementation

{$R *.fmx}

uses
  System.IOUtils,
  System.UIConsts,
  Utils.Utils,
  Net.CrossHttpUtils;

function BytesToStr(const Bytes: Extended): string;
const
  KB = Int64(1024);
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * 1024;
  PB = TB * 1024;
begin
  if (Bytes = 0) then
    Result := ''
  else if (Bytes < KB) then
    Result := FormatFloat('0.##B', Bytes)
  else if (Bytes < MB) then
    Result := FormatFloat('0.##KB', Bytes / KB)
  else if (Bytes < GB) then
    Result := FormatFloat('0.##MB', Bytes / MB)
  else if (Bytes < TB) then
    Result := FormatFloat('0.##GB', Bytes / GB)
  else if (Bytes < PB) then
    Result := FormatFloat('0.##TB', Bytes / TB)
  else
    Result := FormatFloat('0.##PB', Bytes / PB)
end;

function WatchToStr(const AWatch: TStopwatch): string;
begin
  Result := '';
  if (AWatch.Elapsed.Days > 0) then
    Result := Result + AWatch.Elapsed.Days.ToString + 'd';
  if (AWatch.Elapsed.Hours > 0) then
    Result := Result + AWatch.Elapsed.Hours.ToString + 'h';
  if (AWatch.Elapsed.Minutes > 0) then
    Result := Result + AWatch.Elapsed.Minutes.ToString + 'm';
  if (AWatch.Elapsed.Seconds > 0) then
    Result := Result + AWatch.Elapsed.Seconds.ToString + 's';
end;

procedure TfrmHttpServerMain.btnBoardcastClick(Sender: TObject);
begin
  FPnMVCHttpServer.ForEach(
    procedure(LConnection: ICrossWebSocketConnection)
    begin
      LConnection.WsSend('Hello, I''m PnHttpServer!');
    end);
end;

procedure TfrmHttpServerMain.btnCloseAllClick(Sender: TObject);
begin
  FPnMVCHttpServer.ForEach(
    procedure(LConnection: ICrossWebSocketConnection)
    begin
      //LConnection.WsClose;
      LConnection.Close;
    end);
end;

procedure TfrmHttpServerMain.btnStartClick(Sender: TObject);
begin
  if not FPnMVCHttpServer.Active then
  begin
    FPnMVCHttpServer.Addr := IPv4v6_ALL;
    FPnMVCHttpServer.Port := FPnMVCHttpServer.MVCEng.Config.ServerPort;
    FPnMVCHttpServer.Start(
      procedure (ASuccess: Boolean)
      begin
      end);
    btnStart.Text := 'Stop';
    //Memo1.Lines.Clear;
    with (FPnMVCHttpServer as TPnMVCHttpServer) do
    begin
      AddLog('Server start at port:%d,IO threads:%d', [Port,IoThreads]);
    end;
  end else
  begin
    FPnMVCHttpServer.Stop;
    btnStart.Text := 'Start';
    with (FPnMVCHttpServer as TPnMVCHttpServer) do
    begin
      AddLog('Server stop', []);
    end;
    Sleep(100);
  end;
end;


procedure TfrmHttpServerMain.FormCreate(Sender: TObject);
begin
  FBounds := nil;
  Memo1.Lines.Clear;
  FPnMVCHttpServer := TPnMVCHttpServer.Create(5, Memo1);
  with (FPnMVCHttpServer as TPnMVCHttpServer) do
  begin
    AddLog(TOSVersion.ToString, []);
  end;
  btnStartClick(btnStart);
end;

procedure TfrmHttpServerMain.FormDestroy(Sender: TObject);
begin
  FPnMVCHttpServer.Stop;
  Sleep(10);
  FPnMVCHttpServer := nil;
  if Assigned(FBounds) then
    FreeAndNil(FBounds);
end;

procedure TfrmHttpServerMain.Memo1ApplyStyleLookup(Sender: TObject);
var
  Obj: TFmxObject;
  Rectangle1: TRectangle;
begin
  Obj := Memo1.FindStyleResource('background');
  if Obj <> nil then
  begin
    if not Assigned(FBounds) then
      FBounds := TBounds.Create(TRectF.Create(-1, -1, -1, -1));
    TControl(Obj).Margins   := FBounds;
    Rectangle1              := TRectangle.Create(Obj);
    Obj.AddObject(Rectangle1);
    Rectangle1.Align        := TAlignLayout.Client;
    Rectangle1.Fill.Color   := claBlack;
    Rectangle1.Stroke.Color := claNull;
    Rectangle1.HitTest      := False;
    Rectangle1.SendToBack;
  end;
end;

procedure TfrmHttpServerMain.tmr1Timer(Sender: TObject);
begin
  if not Assigned(FPnMVCHttpServer) then Exit;
  with FPnMVCHttpServer do
  begin
    labelTime.Text := Format('运行时间：%s', [WatchToStr(RunWatch)]);
    labelConns.Text := Format('活动连接：%d', [ConnectionsCount]);

    labelRcvData.Text := Format('接收数据：%s', [BytesToStr(RcvdBytes)]);
    labelRcvData.Hint := RcvdBytes.ToString;
    if (RcvdBytes > LastRcvd) and (RecvWatch.ElapsedTicks > 0) then
      labelRcvSpeed.Text := Format('接收速度：%s/s',
        [BytesToStr((RcvdBytes - LastRcvd) / RecvWatch.Elapsed.TotalSeconds)])
    else
      labelRcvSpeed.Text := '接收速度： ';
    labelRcvCount.Text := Format('接收次数：%d', [RcvdCount]);

    labelSndData.Text := Format('发送数据：%s', [BytesToStr(SentBytes)]);
    labelSndData.Hint := SentBytes.ToString;
    if (SentBytes > LastSent) and (SendWatch.ElapsedTicks > 0) then
      labelSndSpeed.Text := Format('发送速度：%s/s',
        [BytesToStr((SentBytes - LastSent) / SendWatch.Elapsed.TotalSeconds)])
    else
      labelSndSpeed.Text := '发送速度： ';
    labelSndCount.Text := Format('发送次数：%d', [SendCount]);

    if (SentBytes <> LastSent) and ((SendWatch.ElapsedTicks = 0) or
      (SendWatch.Elapsed.TotalSeconds > 2)) then
    begin
      LastSent := SentBytes;
      SendWatch := TStopwatch.StartNew;
    end;

    if (RcvdBytes <> LastRcvd) and ((RecvWatch.ElapsedTicks = 0) or
      (RecvWatch.Elapsed.TotalSeconds > 2)) then
    begin
      LastRcvd := RcvdBytes;
      RecvWatch := TStopwatch.StartNew;
    end;
  end;
end;

end.
