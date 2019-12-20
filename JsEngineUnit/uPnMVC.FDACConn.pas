unit uPnMVC.FDACConn;

interface

uses
  System.SysUtils,
  System.Classes,
  qjson,
  Datasnap.DBClient,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.Client, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef,
  FireDAC.Comp.UI, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageBin,
  lib.PnLocker;

type
  TPnFDACConn = class
  private
    FDBServer       : string;
    FDBUser         : string;
    FDBPass         : string;
    FDBName         : string;

    FConn           : TFDConnection;
    FConnErrorCount : Integer;  //连续计数
    //FExcLock        : TPnLocker;
  public
    property DBServer: string read FDBServer write FDBServer;
    property DBUser: string read FDBUser write FDBUser;
    property DBPass: string read FDBPass write FDBPass;
    property DBName: string read FDBName write FDBName;
    property Conn: TFDConnection read FConn;
    property ConnErrorCount: Integer read FConnErrorCount;
  public
    constructor Create;
    destructor Destroy; override;

    procedure OpenDatabase(ReConnected: Boolean = False);
    procedure CloseDatabase;

    function StrToSQL(Asql: string): string;
    function Execute(Asql: string): Boolean;
    function GetRs(ASql: string): TFDQuery;
    function CommandJson(ACmd: string; AJson: TQJson): Integer;
    function CommandQuery(ACmd: string; AQuery: TFDQuery): Integer;
    function fetchone(ASql: string): string;
  end;

implementation

uses
  qlog;

{ TPnFDACConn }
constructor TPnFDACConn.Create;
begin
  inherited Create;
  FConn := TFDConnection.Create(nil);
  FConnErrorCount := 0;
  //FExcLock := TPnLocker.Create('FExcLock');
end;

destructor TPnFDACConn.Destroy;
begin
  //FreeAndNil(FExcLock);
  if Assigned(FConn) then
  begin
    CloseDatabase;
    FreeAndNil(FConn);
  end;
  inherited Destroy;
end;

procedure TPnFDACConn.OpenDatabase(ReConnected: Boolean = False);
begin
  //debug('OpenDatabase', []);
  try
    if not Assigned(FConn) then
    begin
      FConn := TFDConnection.Create(nil);
      ReConnected := True;
    end;

    if ReConnected then
    begin
      if Assigned(FConn) then
      begin
        if FConn.Connected then
          FConn.Connected := False;
        //FreeAndNil(FConn);
        Sleep(500);
      end;

      FConn.Params.Values['LoginTimeout'] := '6';
      FConn.Params.DriverID := 'MSSQL';
      FConn.Params.Values['Server'] := FDBServer;
      FConn.Params.Database := FDBName;
      FConn.Params.UserName := FDBUser;
      FConn.Params.Password := FDBPass;
      FConn.LoginPrompt := False;
      FConn.Connected := True;
    end;

    if not Assigned(FConn) then
      raise Exception.Create('对像未能创建。');

    if (not FConn.Connected) then
    begin
      FConn.Params.Values['LoginTimeout'] := '6';
      FConn.Params.DriverID := 'MSSQL';
      FConn.Params.Values['Server'] := FDBServer;
      FConn.Params.Database := FDBName;
      FConn.Params.UserName := FDBUser;
      FConn.Params.Password := FDBPass;
      FConn.LoginPrompt := False;
      FConn.Connected := True;
    end;
    FConnErrorCount := 0;
  except
    On E: Exception do
    begin
      FConnErrorCount := FConnErrorCount + 1;
      //debug('OpenDatabase: %d', [FConnErrorCount]);
      PostLog(TQLogLevel.llError, 'TPnFDACConn.OpenDatabase: %s', [E.Message], '');
    end;
  end;
end;

procedure TPnFDACConn.CloseDatabase;
begin
  try
    if FConn.Connected then
    begin
      FConn.Connected := False;
    end;
  except

  end;
end;

function TPnFDACConn.StrToSQL(ASql: string): string;
begin
  Result := StringReplace(ASql, '''', '''''', [rfReplaceAll, rfIgnoreCase]);
end;

function TPnFDACConn.Execute(Asql: string): Boolean;
begin
  Result := False;
  //错误计数大于5则重新连接
  if FConnErrorCount>5 then
    OpenDatabase(True);
  try
    FConn.ExecSQL(ASql);
    FConnErrorCount := 0;
    Result := True;
  except
    On E: Exception do
    begin
      FConnErrorCount := FConnErrorCount + 1;
      //debug('Execute: %d', [FConnErrorCount]);
      PostLog(TQLogLevel.llError, 'TPnFDACConn.Execute(%s): %s', [Asql, E.Message], '');
    end;
  end;
end;

function TPnFDACConn.GetRs(ASql: string): TFDQuery;
var
  FDQuery: TFDQuery;
begin
  Result := nil;
  //错误计数大于5则重新连接
  if FConnErrorCount>5 then
    OpenDatabase(True);
  try
    FDQuery := TFDQuery.Create(nil);
    Result := FDQuery;
    FDQuery.Connection := FConn;
    FDQuery.SQL.Text := ASql;
    FDQuery.Active := True;

    FConnErrorCount := 0;
  except
    On E: Exception do
    begin
      FConnErrorCount := FConnErrorCount + 1;
      //debug('GetRs: %d', [FConnErrorCount]);
      PostLog(TQLogLevel.llError, 'TPnFDACConn.GetRs(%s): %s', [Asql, E.Message], '');
    end;
  end;
end;

function TPnFDACConn.CommandJson(ACmd: string; AJson: TQJson): Integer;
var
  FDQuery: TFDQuery;
  nFirstRet: Integer;
  AStream: TMemoryStream;
begin
  //FExcLock.Lock;
  try
    nFirstRet := -1;
    Result := -1;
    //错误计数大于5则重新连接
    if FConnErrorCount>5 then
    begin
      OpenDatabase(True);
    end;


    try
      FDQuery := TFDQuery.Create(nil);
      try
        FDQuery.Connection := FConn;
        FDQuery.FetchOptions.AutoClose := False;
        FDQuery.Open(ACmd);

        if AJson<>nil then
        begin
          //数据集转到json
          AStream := TMemoryStream.Create;
          try
            AStream.Seek(0, TSeekOrigin.soBeginning);
            FDQuery.SaveToStream(AStream, sfJSON);
            AStream.Seek(0, TSeekOrigin.soCurrent);
            AStream.Position := 0;
            AJson.LoadFromStream(AStream);
            AJson.SaveToFile('11111.txt');
          finally
            FreeAndNil(AStream);
          end;
        end;

        //First RETURN_VALUE
        if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
          nFirstRet := FDQuery.Fields[0].AsInteger;

        //下一记录集
        FDQuery.NextRecordSet;
        if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
        begin
          //取得第二个记录集的返回值
          if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
            Result := FDQuery.Fields[0].AsInteger;
        end
        else begin
          //取得第一个记录集的返回值
          Result := nFirstRet;
        end;

      finally
        FreeAndNil(FDQuery);
      end;
      FConnErrorCount := 0;
    except
      On E: Exception do
      begin
        Result := -1;
        FConnErrorCount := FConnErrorCount + 1;
        //debug('CommandJson: %d', [FConnErrorCount]);
        PostLog(TQLogLevel.llError, 'TPnFDACConn.CommandJson(%s): %s', [ACmd, E.Message], '');
      end;
    end;
  finally
    //FExcLock.UnLock;
  end;
end;

function TPnFDACConn.CommandQuery(ACmd: string; AQuery: TFDQuery): Integer;
var
  FDQuery: TFDQuery;
  nFirstRet: Integer;
  AStream: TMemoryStream;
begin
  //FExcLock.Lock;
  try
    nFirstRet := -1;
    Result := -1;
    //错误计数大于5则重新连接
    if FConnErrorCount>5 then
    begin
      OpenDatabase(True);
    end;


    try
      FDQuery := TFDQuery.Create(nil);
      try
        FDQuery.Connection := FConn;
        FDQuery.FetchOptions.AutoClose := False;
        FDQuery.Open(ACmd);

        if AQuery<>nil then
        begin
          AQuery.Connection := FConn;
          AQuery.FetchOptions.AutoClose := False;

          //数据集转到json
          AStream := TMemoryStream.Create;
          try
            AStream.Seek(0, TSeekOrigin.soBeginning);
            FDQuery.SaveToStream(AStream, sfBinary);
            AStream.Seek(0, TSeekOrigin.soCurrent);
            AStream.Position := 0;
            AQuery.LoadFromStream(AStream, sfBinary);
          finally
            FreeAndNil(AStream);
          end;
        end;

        //First RETURN_VALUE
        if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
          nFirstRet := FDQuery.Fields[0].AsInteger;

        //下一记录集
        FDQuery.NextRecordSet;
        if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
        begin
          //取得第二个记录集的返回值
          if (Not FDQuery.Eof) and (FDQuery.Fields.Count=1) then
            Result := FDQuery.Fields[0].AsInteger;
        end
        else begin
          //取得第一个记录集的返回值
          Result := nFirstRet;
        end;

      finally
        FreeAndNil(FDQuery);
      end;
      FConnErrorCount := 0;
    except
      On E: Exception do
      begin
        Result := -1;
        FConnErrorCount := FConnErrorCount + 1;
        //debug('Command: %d', [FConnErrorCount]);
        PostLog(TQLogLevel.llError, 'TPnFDACConn.CommandQuery(%s): %s', [ACmd, E.Message], '');
      end;
    end;
  finally
    //FExcLock.UnLock;
  end;
end;

function TPnFDACConn.fetchone(ASql: string): string;
var
  FDQuery: TFDQuery;
begin
  Result := '';
  //FExcLock.Lock;
  try
      //错误计数大于5则重新连接
      if FConnErrorCount>5 then
      begin
        OpenDatabase(True);
      end;

      try
        FDQuery := TFDQuery.Create(nil);
        try
          FDQuery.Connection := FConn;
          FDQuery.SQL.Text := ASql;
          FDQuery.Active := True;

          if not FDQuery.Eof then
          begin
            Result := FDQuery.Fields[0].AsString;
          end;

        finally
          FreeAndNil(FDQuery);
        end;

        FConnErrorCount := 0;
      except
        On E: Exception do
        begin
          Result := '';
          FConnErrorCount := FConnErrorCount + 1;
          //debug('GetRs: %d', [FConnErrorCount]);
          PostLog(TQLogLevel.llError, 'TPnFDACConn.fetchone(%s): %s', [ASql, E.Message], '');
        end;
      end;
  finally
    //FExcLock.UnLock;
  end;
end;

end.
