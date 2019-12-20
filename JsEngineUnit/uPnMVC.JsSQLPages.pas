unit uPnMVC.JsSQLPages;

interface

{$include common.inc}

uses
  System.SysUtils,
  System.Classes,
{$ifdef HAS_WIDESTRUTILS}
  System.WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses,
  uPnMVC.JsFDACConn,
  uPnMVC.FDSQLPages;

type
  { TJsSQLPages }
  TJsSQLPages = class(TNativeObject)
  private
    FJsFDACConn: TJsFDACConn;
    FPnSQLPages: TPnSQLPages;
    //Conn
    procedure SetConn(Value: JsValueRef);
    //PageSize
    function GetPageSize: JsValueRef;
    procedure SetPageSize(Value: JsValueRef);
    //CurrentPage
    function GetCurrentPage: JsValueRef;
    procedure SetCurrentPage(Value: JsValueRef);
    //TotalRecord
    function GetTotalRecord: JsValueRef;
    procedure SetTotalRecord(Value: JsValueRef);
    //TotalPage
    function GetTotalPage: JsValueRef;
    procedure SetTotalPage(Value: JsValueRef);
    function setSQL(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function GetRs(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
  end;

implementation

{ TJsSQLPages }
procedure TJsSQLPages.SetConn(Value: JsValueRef);
begin
  if (JsGetValueType(Value) = JsObject) then
  begin
    FJsFDACConn := TJsFDACConn(JsGetExternalData(Value));
    FPnSQLPages.Conn := FJsFDACConn.Conn;
  end;
end;

function TJsSQLPages.GetPageSize: JsValueRef;
begin
  Result := DoubleToJsNumber(FPnSQLPages.PageSize);
end;

procedure TJsSQLPages.SetPageSize(Value: JsValueRef);
begin
  FPnSQLPages.PageSize := Trunc(JsNumberToDouble(Value));
end;

function TJsSQLPages.GetCurrentPage: JsValueRef;
begin
  Result := DoubleToJsNumber(FPnSQLPages.CurrentPage);
end;

procedure TJsSQLPages.SetCurrentPage(Value: JsValueRef);
begin
  FPnSQLPages.CurrentPage := Trunc(JsNumberToDouble(Value));
end;

function TJsSQLPages.GetTotalRecord: JsValueRef;
begin
  Result := DoubleToJsNumber(FPnSQLPages.TotalRecord);
end;

procedure TJsSQLPages.SetTotalRecord(Value: JsValueRef);
begin
  FPnSQLPages.TotalRecord := Trunc(JsNumberToDouble(Value));
end;

function TJsSQLPages.GetTotalPage: JsValueRef;
begin
  Result := DoubleToJsNumber(FPnSQLPages.TotalPage);
end;

procedure TJsSQLPages.SetTotalPage(Value: JsValueRef);
begin
  FPnSQLPages.TotalPage := Trunc(JsNumberToDouble(Value));
end;

function TJsSQLPages.setSQL(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  strSQL: string;
begin
  Result := JsNullValue;
  if Assigned(Args) and (ArgCount >= 1) and (JsGetValueType(Args^) = JsString) then
  begin
    strSQL := JsStringToUnicodeString(JsValueAsJsString(Args^));
    FPnSQLPages.setSQL(strSQL);
  end;
end;

function TJsSQLPages.GetRs(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  LJsFDQuery: TJsFDQuery;
begin
  Result := JsNullValue;
  LJsFDQuery := TJsFDQuery.Create;
  LJsFDQuery.FDQuery := FPnSQLPages.GetRs();
  Result := LJsFDQuery.Instance;
end;

class procedure TJsSQLPages.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'Conn', False, False, nil, @TJsSQLPages.SetConn);
  RegisterNamedProperty(AInstance, 'PageSize', False, False, @TJsSQLPages.GetPageSize, @TJsSQLPages.SetPageSize);
  RegisterNamedProperty(AInstance, 'CurrentPage', False, False, @TJsSQLPages.GetCurrentPage, @TJsSQLPages.SetCurrentPage);
  RegisterNamedProperty(AInstance, 'TotalRecord', False, False, @TJsSQLPages.GetTotalRecord, @TJsSQLPages.SetTotalRecord);
  RegisterNamedProperty(AInstance, 'TotalPage', False, False, @TJsSQLPages.GetTotalPage, @TJsSQLPages.SetTotalPage);
end;

class procedure TJsSQLPages.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'setSQL', @TJsSQLPages.setSQL);
  RegisterMethod(AInstance, 'GetRs', @TJsSQLPages.GetRs);
end;

constructor TJsSQLPages.Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False);
begin
  inherited;
end;

destructor TJsSQLPages.Destroy;
begin
  inherited;
end;


initialization
  RegisterClasses([TJsSQLPages]);

finalization
  UnRegisterClasses([TJsSQLPages]);

end.
