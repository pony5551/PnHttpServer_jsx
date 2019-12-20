program dtest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils
  ;



type
  TSetLengthBytes = procedure (var aBytes: TBytes; NewLength: Integer); {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}


procedure SetLengthBytes(var aBytes: TBytes; NewLength: Integer); {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  SetLength(aBytes, NewLength);
end;


function dmustacheParse1(
    tplStr: PAnsiChar;
    jsonStr: PAnsiChar;
    out outputstr: TBytes;
    SetLengthBytes: TSetLengthBytes): Integer; {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}
    external 'libdmustache.so' name 'dmustacheParse1';



var
  Template, JSONStr: UTF8String;
  pOutputStr: TBytes;
  s: AnsiString;
begin
  try
    { TODO -oUser -cConsole Main : Insert code here }

    Writeln('start debug..1');
    ReadLn;

    Writeln('start debug..2');
    ReadLn;

    Template := '<b>{{name}}</b> ({{title}})=====';
    JSONStr := '{"name":"pony","title":"title"}';
    dmustacheParse1(
      PAnsiChar(Template),
      PAnsiChar(JSONStr),
      pOutputStr,
      @SetLengthBytes);

    Writeln(AnsiString(PAnsiChar(@pOutputStr[0])));
    SetString(s, PAnsiChar(pOutputStr), Length(pOutputStr));
    Writeln(s);

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
