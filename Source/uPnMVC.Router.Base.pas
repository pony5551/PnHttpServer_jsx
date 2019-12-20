unit uPnMVC.Router.Base;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Net.CrossHttpServer,
  uPnMVC.Core,
  lib.PnLocker
  ;

type
  { 路由模块 }
  TPnRouterBase = class
  const
    CONST_RouterPath = '/sysmgr/*.do';
  private
    FMVCEng: TPnMVCEngine;
  protected
    function GetRouterPath: string; virtual;
  public
    constructor Create(AMVCEng: TPnMVCEngine); virtual;
    destructor Destroy; override;
    procedure RouterProc(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse); virtual; abstract;
    procedure TriggerThreadBegin(AThread: TThread); virtual; abstract;
    procedure TriggerThreadEnd(AThread: TThread); virtual; abstract;
    property MVCEng: TPnMVCEngine read FMVCEng;
    property RouterPath: string read GetRouterPath;
  end;

  TPnRouterBaseClass = class of TPnRouterBase;
  TPnRouterBaseClasses = TArray<TPnRouterBaseClass>;
  TPnRouterBaseArr = TArray<TPnRouterBase>;

  { 路由模块列表，用于注册，注销，取得所有路由模块 }
  TPnRouterBases = class(TList<TPnRouterBaseClass>)
  private
    FLock: TPnLocker;
    procedure RegisterClass(AClass: TPnRouterBaseClass);
    procedure UnregisterClass(AClass: TPnRouterBaseClass);
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterClasses(const AClasses: TPnRouterBaseClasses);
    procedure UnregisterClasses(const AClasses: TPnRouterBaseClasses);
    function GetClasses: TPnRouterBaseClasses;
  end;

var
  gPnRouterBases: TPnRouterBases = nil;

implementation

{ TPnRouterBase }
function TPnRouterBase.GetRouterPath: string;
begin
  Result := CONST_RouterPath;
end;

constructor TPnRouterBase.Create(AMVCEng: TPnMVCEngine);
begin
  inherited Create;
  FMVCEng := AMVCEng;
end;

destructor TPnRouterBase.Destroy;
begin
  inherited;
end;

{ TPnRouterBases }
constructor TPnRouterBases.Create;
begin
  inherited Create;
  FLock := TPnLocker.Create('TPnRouterBases_Locker');
end;

destructor TPnRouterBases.Destroy;
begin
  FreeAndNil(FLock);
  inherited;
end;

procedure TPnRouterBases.RegisterClass(AClass: TPnRouterBaseClass);
var
  idx: Integer;
begin
  while IndexOf(AClass)=-1 do
  begin
    Add(AClass);
    //if AClass = TPnRouterBase then Break;
    //AClass := TPnRouterBaseClass(AClass.ClassParent);
  end;
end;

procedure TPnRouterBases.UnregisterClass(AClass: TPnRouterBaseClass);
begin
  Remove(AClass);
end;

procedure TPnRouterBases.RegisterClasses(const AClasses: TPnRouterBaseClasses);
var
  I: Integer;
begin
  FLock.Lock;
  try
    for I := Low(AClasses) to High(AClasses) do
      RegisterClass(AClasses[I]);
  finally
    FLock.UnLock;
  end;
end;

procedure TPnRouterBases.UnregisterClasses(const AClasses: TPnRouterBaseClasses);
var
  I: Integer;
begin
  FLock.Lock;
  try
    for I := Low(AClasses) to High(AClasses) do
      UnregisterClass(AClasses[I]);
  finally
    FLock.UnLock;
  end;
end;

function TPnRouterBases.GetClasses: TPnRouterBaseClasses;
begin
  FLock.Lock;
  try
    Result := ToArray;
  finally
    FLock.UnLock;
  end;
end;


initialization
  gPnRouterBases := TPnRouterBases.Create;

finalization
  FreeAndNil(gPnRouterBases);

end.
