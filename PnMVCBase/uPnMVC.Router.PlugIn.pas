unit uPnMVC.Router.PlugIn;

interface

uses
  System.Classes;

type
  PPlugServerInfo = ^TPlugServerInfo;
  TPlugServerInfo = record
    ServerPath: string;
    ServerName: string;
    ServerPort: Integer;
    ServerIoThreads: Integer;
    WebRoot: string;
    ViewRootPath: string;
    ViewFileExt: string;
  end;

  { ·�ɲ���ӿڣ�����������־����,����ȫ��webconfig,���ز��������webpage }
  IPnRouterPlug = interface
    ['{661F4651-30ED-4A16-A695-29E0E726002D}']
    procedure SetServerInfo(AServerInfo: PPlugServerInfo);
    function GetRemark: string;
  end;

  TPnRouterPlugBase = class;
  TPnRouterPlugClass = class of TPnRouterPlugBase;

  { TPnRouterPlugBase }
  TPnRouterPlugBase = class(TInterfacedPersistent);

implementation


end.
