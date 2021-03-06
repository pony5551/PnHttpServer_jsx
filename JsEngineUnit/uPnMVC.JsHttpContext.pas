unit uPnMVC.JsHttpContext;

interface

uses
  System.SysUtils,
  System.Classes,
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses,
  Net.CrossHttpParams,
  Net.CrossHttpServer,
  uPnMVC.Core;

type
  TJsMVCView = class(TNativeObject)
  private
    FView: TPnMVCView;
    //ViewPath
    function GetViewPath: JsValueRef;
    procedure SetViewPath(Value: JsValueRef);
    //methods
    function LoadView(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    property View: TPnMVCView read FView write FView;
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
  end;

  TJsHttpRequest = class(TNativeObject)
  private
    FRequest: ICrossHttpRequest;
    //RawRequestText
    function GetRawRequestText: JsValueRef;
    //RawPathAndParams
    function GetRawPathAndParams: JsValueRef;
    //Method
    function GetMethod: JsValueRef;
    //Path
    function GetPath: JsValueRef;
    //Version
    function GetVersion: JsValueRef;
    //BodyType
    function GetBodyType: JsValueRef;
    //KeepAlive
    function GetKeepAlive: JsValueRef;
    //Accept
    function GetAccept: JsValueRef;
    //AcceptEncoding
    function GetAcceptEncoding: JsValueRef;
    //AcceptLanguage
    function GetAcceptLanguage: JsValueRef;
    //Referer
    function GetReferer: JsValueRef;
    //UserAgent
    function GetUserAgent: JsValueRef;
    //IfModifiedSince
    function GetIfModifiedSince: JsValueRef;
    //IfNoneMatch
    function GetIfNoneMatch: JsValueRef;
    //Range
    function GetRange: JsValueRef;
    //IfRange
    function GetIfRange: JsValueRef;
    //Authorization
    function GetAuthorization: JsValueRef;
    //XForwardedFor
    function GetXForwardedFor: JsValueRef;
    //ContentLength
    function GetContentLength: JsValueRef;
    //HostName
    function GetHostName: JsValueRef;
    //HostPort
    function GetHostPort: JsValueRef;
    //ContentType
    function GetContentType: JsValueRef;
    //ContentEncoding
    function GetContentEncoding: JsValueRef;
    //RequestBoundary
    function GetRequestBoundary: JsValueRef;
    //RequestCmdLine
    function GetRequestCmdLine: JsValueRef;
    //RequestConnection
    function GetRequestConnection: JsValueRef;
    //TransferEncoding
    function GetTransferEncoding: JsValueRef;
    //IsChunked
    function GetIsChunked: JsValueRef;
    //IsMultiPartFormData
    function GetIsMultiPartFormData: JsValueRef;
    //IsUrlEncodedFormData
    function GetIsUrlEncodedFormData: JsValueRef;
    //PostDataSize
    function GetPostDataSize: JsValueRef;
    //PostData
    function GetPostData: JsValueRef;
    //RemoteAddr
    function GetRemoteAddr: JsValueRef;

    //GetParams
    function GetParams(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    property Request: ICrossHttpRequest read FRequest write FRequest;
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
  end;

  TJsHttpResponse = class(TNativeObject)
  private
    FResponse: ICrossHttpResponse;
    FRespOutput: TStringBuilder;
    //StatusCode
    function GetStatusCode: JsValueRef;
    procedure SetStatusCode(Value: JsValueRef);
    //ContentType
    function GetContentType: JsValueRef;
    procedure SetContentType(Value: JsValueRef);
    //methods
    function Write(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function Send(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    property Response: ICrossHttpResponse read FResponse write FResponse;
    property RespOutput: TStringBuilder read FRespOutput;
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
    procedure Clear;
  end;

implementation

{ TJsMVCView }
constructor TJsMVCView.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  //FView := TPnMVCView.Create;
  inherited Create(Args, ArgCount, AFinalize);
end;

destructor TJsMVCView.Destroy;
begin
  //FreeAndNil(FView);
  inherited;
end;

class procedure TJsMVCView.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'ViewPath', False, False, @TJsMVCView.GetViewPath, @TJsMVCView.SetViewPath);
end;

class procedure TJsMVCView.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'LoadView', @TJsMVCView.LoadView);
end;

function TJsMVCView.GetViewPath: JsValueRef;
begin
  Result := StringToJsString(FView.ViewPath);
end;

procedure TJsMVCView.SetViewPath(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  FView.ViewPath := nValue;
end;


function TJsMVCView.LoadView(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  L: Integer;
  LArgs: PJsValueRef;
  I: Integer;
  sViewNames: TArray<string>;
  sLine,
  sJsonData: string;
  outhtml: UTF8String;
begin
  Result := JsUndefinedValue;
  if not Assigned(Args) or (ArgCount < 2) then
    Exit;

  LArgs := Args;
  if (JsGetValueType(LArgs^) <> JsArray) and (JsGetValueType(PJsValueRef(NativeInt(LArgs)+1)^) <> JsString) then
    Exit;

  L := JsArrayLength(LArgs^);
  SetLength(sViewNames, L);
  for I := 0 to L - 1 do
  begin
    sLine := JsStringToUnicodeString(JsArrayGetElement(LArgs^, I));
    sViewNames[I] := sLine;
  end;

  Inc(LArgs);
  sJsonData := JsStringToUnicodeString(LArgs^);
  FView.LoadView(sViewNames, sJsonData, outhtml);
  Result := StringToJsString(outhtml);
end;


{ TJsHttpRequest }
constructor TJsHttpRequest.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited Create(Args, ArgCount, AFinalize);
end;

destructor TJsHttpRequest.Destroy;
begin
  inherited;
end;

function TJsHttpRequest.GetRawRequestText: JsValueRef;
begin
  Result := StringToJsString(FRequest.RawRequestText);
end;

function TJsHttpRequest.GetRawPathAndParams: JsValueRef;
begin
  Result := StringToJsString(FRequest.RawPathAndParams);
end;

function TJsHttpRequest.GetMethod: JsValueRef;
begin
  Result := StringToJsString(FRequest.Method);
end;

function TJsHttpRequest.GetPath: JsValueRef;
begin
  Result := StringToJsString(FRequest.Path);
end;

function TJsHttpRequest.GetVersion: JsValueRef;
begin
  Result := StringToJsString(FRequest.Version);
end;

function TJsHttpRequest.GetBodyType: JsValueRef;
begin
  Result := IntToJsNumber(Integer(FRequest.BodyType));
end;

function TJsHttpRequest.GetKeepAlive: JsValueRef;
begin
  Result := BooleanToJsBoolean(FRequest.KeepAlive);
end;

function TJsHttpRequest.GetAccept: JsValueRef;
begin
  Result := StringToJsString(FRequest.Accept);
end;

function TJsHttpRequest.GetAcceptEncoding: JsValueRef;
begin
  Result := StringToJsString(FRequest.AcceptEncoding);
end;

function TJsHttpRequest.GetAcceptLanguage: JsValueRef;
begin
  Result := StringToJsString(FRequest.AcceptLanguage);
end;

function TJsHttpRequest.GetReferer: JsValueRef;
begin
  Result := StringToJsString(FRequest.Referer);
end;

function TJsHttpRequest.GetUserAgent: JsValueRef;
begin
  Result := StringToJsString(FRequest.UserAgent);
end;

function TJsHttpRequest.GetIfModifiedSince: JsValueRef;
begin
  Result := StringToJsString(DateTimeToStr(FRequest.IfModifiedSince));
end;

function TJsHttpRequest.GetIfNoneMatch: JsValueRef;
begin
  Result := StringToJsString(FRequest.IfNoneMatch);
end;

function TJsHttpRequest.GetRange: JsValueRef;
begin
  Result := StringToJsString(FRequest.Range);
end;

function TJsHttpRequest.GetIfRange: JsValueRef;
begin
  Result := StringToJsString(FRequest.IfRange);
end;

function TJsHttpRequest.GetAuthorization: JsValueRef;
begin
  Result := StringToJsString(FRequest.Authorization);
end;

function TJsHttpRequest.GetXForwardedFor: JsValueRef;
begin
  Result := StringToJsString(FRequest.XForwardedFor);
end;

function TJsHttpRequest.GetContentLength: JsValueRef;
begin
  Result := DoubleToJsNumber(FRequest.GetContentLength);
end;

function TJsHttpRequest.GetHostName: JsValueRef;
begin
  Result := StringToJsString(FRequest.HostName);
end;

function TJsHttpRequest.GetHostPort: JsValueRef;
begin
  Result := IntToJsNumber(FRequest.HostPort);
end;

function TJsHttpRequest.GetContentType: JsValueRef;
begin
  Result := StringToJsString(FRequest.ContentType);
end;

function TJsHttpRequest.GetContentEncoding: JsValueRef;
begin
  Result := StringToJsString(FRequest.ContentEncoding);
end;

function TJsHttpRequest.GetRequestBoundary: JsValueRef;
begin
  Result := StringToJsString(FRequest.RequestBoundary);
end;

function TJsHttpRequest.GetRequestCmdLine: JsValueRef;
begin
  Result := StringToJsString(FRequest.RequestCmdLine);
end;

function TJsHttpRequest.GetRequestConnection: JsValueRef;
begin
  Result := StringToJsString(FRequest.RequestConnection);
end;

function TJsHttpRequest.GetTransferEncoding: JsValueRef;
begin
  Result := StringToJsString(FRequest.TransferEncoding);
end;

function TJsHttpRequest.GetIsChunked: JsValueRef;
begin
  Result := BooleanToJsBoolean(FRequest.IsChunked);
end;

function TJsHttpRequest.GetIsMultiPartFormData: JsValueRef;
begin
  Result := BooleanToJsBoolean(FRequest.IsMultiPartFormData);
end;

function TJsHttpRequest.GetIsUrlEncodedFormData: JsValueRef;
begin
  Result := BooleanToJsBoolean(FRequest.IsUrlEncodedFormData);
end;

function TJsHttpRequest.GetPostDataSize: JsValueRef;
begin
  Result := DoubleToJsNumber(FRequest.PostDataSize);
end;

function TJsHttpRequest.GetPostData: JsValueRef;
var
  LStream: TBytesStream;
  LStrStream: TStringStream;
  sResult: string;
begin
  if FRequest = nil then
  begin
    Result := StringToJsString('');
    Exit;
  end;
  if (FRequest.BodyType = btBinary) then
  begin
    LStream := TBytesStream(FRequest.Body);
    LStrStream := TStringStream.Create;
    try
      LStrStream.CopyFrom(LStream, LStream.Size);
      sResult := LStrStream.DataString;
    finally
      FreeAndNil(LStrStream);
    end;
  end
  else begin
    sResult := '';
  end;
  Result := StringToJsString(sResult);
end;

function TJsHttpRequest.GetRemoteAddr: JsValueRef;
begin
  Result := StringToJsString(FRequest.Connection.PeerAddr);
end;

function TJsHttpRequest.GetParams(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  sName,
  sValue: string;
  LArgs: PJsValueRef;
  jv: JsValueType;
begin
  Result := JsNullValue;
  if not Assigned(Args) then
    Exit;

  if (ArgCount > 0) and (JsGetValueType(Args^) = JsString) then
  begin
    sName := JsStringToUnicodeString(JsValueAsJsString(Args^));
    sValue := FRequest.Query.Params[sName];
    if (sValue = '') and (FRequest.BodyType = btUrlEncoded) then
    begin
      with THttpUrlParams(FRequest.Body) do
      begin
        sValue := Params[sName];
      end;
    end;

    LArgs := Args;
    jv := JsUndefined;
    if (ArgCount > 1) then
    begin
      Inc(LArgs);
      jv := JsGetValueType(LArgs^);
    end;
    if (sValue = '') then
    begin
      Result := LArgs^;
    end
    else begin
      case jv of
        JsNumber:
        begin
          Result := DoubleToJsNumber(StrToFloatDef(sValue,0));
        end;
        JsString:
        begin
          Result := StringToJsString(sValue);
        end;
        JsBoolean:
        begin
          Result := BooleanToJsBoolean(sValue.ToBoolean);
        end;
        else begin
          Result := StringToJsString(sValue);
        end;
//        JsObject: ;
//        JsFunction: ;
//        JsError: ;
//        JsArray: ;
//        JsSymbol: ;
//        JsArrayBuffer: ;
//        JsTypedArray: ;
//        JsDataView: ;
      end;
    end;
  end;
end;

class procedure TJsHttpRequest.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'RawRequestText', False, False, @TJsHttpRequest.GetRawRequestText, nil);
  RegisterNamedProperty(AInstance, 'RawPathAndParams', False, False, @TJsHttpRequest.GetRawPathAndParams, nil);
  RegisterNamedProperty(AInstance, 'Method', False, False, @TJsHttpRequest.GetMethod, nil);
  RegisterNamedProperty(AInstance, 'Path', False, False, @TJsHttpRequest.GetPath, nil);
  RegisterNamedProperty(AInstance, 'Version', False, False, @TJsHttpRequest.GetVersion, nil);
  RegisterNamedProperty(AInstance, 'BodyType', False, False, @TJsHttpRequest.GetBodyType, nil);
  RegisterNamedProperty(AInstance, 'KeepAlive', False, False, @TJsHttpRequest.GetKeepAlive, nil);
  RegisterNamedProperty(AInstance, 'Accept', False, False, @TJsHttpRequest.GetAccept, nil);
  RegisterNamedProperty(AInstance, 'AcceptEncoding', False, False, @TJsHttpRequest.GetAcceptEncoding, nil);
  RegisterNamedProperty(AInstance, 'AcceptLanguage', False, False, @TJsHttpRequest.GetAcceptLanguage, nil);
  RegisterNamedProperty(AInstance, 'Referer', False, False, @TJsHttpRequest.GetReferer, nil);
  RegisterNamedProperty(AInstance, 'UserAgent', False, False, @TJsHttpRequest.GetUserAgent, nil);
  RegisterNamedProperty(AInstance, 'IfModifiedSince', False, False, @TJsHttpRequest.GetIfModifiedSince, nil);
  RegisterNamedProperty(AInstance, 'IfNoneMatch', False, False, @TJsHttpRequest.GetIfNoneMatch, nil);
  RegisterNamedProperty(AInstance, 'Range', False, False, @TJsHttpRequest.GetRange, nil);
  RegisterNamedProperty(AInstance, 'IfRange', False, False, @TJsHttpRequest.GetIfRange, nil);
  RegisterNamedProperty(AInstance, 'Authorization', False, False, @TJsHttpRequest.GetAuthorization, nil);
  RegisterNamedProperty(AInstance, 'XForwardedFor', False, False, @TJsHttpRequest.GetXForwardedFor, nil);
  RegisterNamedProperty(AInstance, 'ContentLength', False, False, @TJsHttpRequest.GetContentLength, nil);
  RegisterNamedProperty(AInstance, 'HostName', False, False, @TJsHttpRequest.GetHostName, nil);
  RegisterNamedProperty(AInstance, 'HostPort', False, False, @TJsHttpRequest.GetHostPort, nil);
  RegisterNamedProperty(AInstance, 'ContentType', False, False, @TJsHttpRequest.GetContentType, nil);
  RegisterNamedProperty(AInstance, 'ContentEncoding', False, False, @TJsHttpRequest.GetContentEncoding, nil);
  RegisterNamedProperty(AInstance, 'RequestBoundary', False, False, @TJsHttpRequest.GetRequestBoundary, nil);
  RegisterNamedProperty(AInstance, 'RequestCmdLine', False, False, @TJsHttpRequest.GetRequestCmdLine, nil);
  RegisterNamedProperty(AInstance, 'RequestConnection', False, False, @TJsHttpRequest.GetRequestConnection, nil);
  RegisterNamedProperty(AInstance, 'TransferEncoding', False, False, @TJsHttpRequest.GetTransferEncoding, nil);
  RegisterNamedProperty(AInstance, 'IsChunked', False, False, @TJsHttpRequest.GetIsChunked, nil);
  RegisterNamedProperty(AInstance, 'IsMultiPartFormData', False, False, @TJsHttpRequest.GetIsMultiPartFormData, nil);
  RegisterNamedProperty(AInstance, 'IsUrlEncodedFormData', False, False, @TJsHttpRequest.GetIsUrlEncodedFormData, nil);
  RegisterNamedProperty(AInstance, 'PostDataSize', False, False, @TJsHttpRequest.GetPostDataSize, nil);
  RegisterNamedProperty(AInstance, 'PostData', False, False, @TJsHttpRequest.GetPostData, nil);
  RegisterNamedProperty(AInstance, 'RemoteAddr', False, False, @TJsHttpRequest.GetRemoteAddr, nil);

//  RegisterNamedProperty(AInstance, 'ContentType', False, False, @TJsHttpResponse.GetContentType, @TJsHttpResponse.SetContentType);
end;

class procedure TJsHttpRequest.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'GetParams', @TJsHttpRequest.GetParams);
//  RegisterMethod(AInstance, 'Send', @TJsHttpResponse.Send);
end;


{ TJsHttpResponse }
constructor TJsHttpResponse.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  FRespOutput := TStringBuilder.Create;
  inherited Create(Args, ArgCount, AFinalize);
end;

destructor TJsHttpResponse.Destroy;
begin
  FreeAndNil(FRespOutput);
  inherited;
end;

procedure TJsHttpResponse.Clear;
begin
  FRespOutput.Clear;
end;

class procedure TJsHttpResponse.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'StatusCode', False, False, @TJsHttpResponse.GetStatusCode, @TJsHttpResponse.SetStatusCode);
  RegisterNamedProperty(AInstance, 'ContentType', False, False, @TJsHttpResponse.GetContentType, @TJsHttpResponse.SetContentType);
end;

class procedure TJsHttpResponse.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'Write', @TJsHttpResponse.Write);
  RegisterMethod(AInstance, 'Send', @TJsHttpResponse.Send);
end;

//propertys
function TJsHttpResponse.GetStatusCode: JsValueRef;
begin
  Result := IntToJsNumber(FResponse.StatusCode);
end;

procedure TJsHttpResponse.SetStatusCode(Value: JsValueRef);
var
  nValue: Integer;
begin
  nValue := JsNumberToInt(Value);
  if nValue <> FResponse.StatusCode then
  begin
    // Prop1 changed
    FResponse.StatusCode := nValue;
  end;
end;

function TJsHttpResponse.GetContentType: JsValueRef;
begin
  Result := StringToJsString(FResponse.ContentType);
end;

procedure TJsHttpResponse.SetContentType(Value: JsHandle);
var
  nValue: UnicodeString;
begin
  nValue := JsStringToUnicodeString(Value);
  if nValue <> FResponse.ContentType then
  begin
    // Prop1 changed
    FResponse.ContentType := nValue;
  end;
end;


//functions
function TJsHttpResponse.Write(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  S: string;
  bSend: Boolean;
  LArgs: PJsValueRef;
begin
  Result := JsUndefinedValue;
  if not Assigned(Args) then
    Exit;

  LArgs := Args;
  if (ArgCount > 0) and (JsGetValueType(LArgs^) = JsString) then
  begin
    S := JsStringToUnicodeString(JsValueAsJsString(LArgs^));
    FRespOutput.Append(S);
    if ArgCount<2 then Exit;
    Inc(LArgs);
    bSend := False;
    if JsGetValueType(LArgs^) = JsBoolean then
      bSend := JsBooleanToBoolean(JsValueAsJsBoolean(LArgs^));
    if bSend and Assigned(FResponse) then
    begin
      FResponse.Send(FRespOutput.ToString);
      FRespOutput.Clear;
    end;
  end;
end;

function TJsHttpResponse.Send(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  S: string;
  LArgs: PJsValueRef;
begin
  Result := JsUndefinedValue;
  if not Assigned(Args) then
    Exit;

  LArgs := Args;
  if (ArgCount > 0) and (JsGetValueType(LArgs^) = JsString) then
  begin
    S := JsStringToUnicodeString(JsValueAsJsString(LArgs^));
    FRespOutput.Append(S);
    if Assigned(FResponse) then
      FResponse.Send(FRespOutput.ToString);
  end
  else begin
    if Assigned(FResponse) then
      FResponse.Send(FRespOutput.ToString);
  end;
  FRespOutput.Clear;
end;


initialization
  RegisterClasses([TJsMVCView]);

finalization
  UnRegisterClasses([TJsMVCView]);

end.
