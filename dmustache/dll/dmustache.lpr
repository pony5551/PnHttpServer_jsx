library dmustache;

{$mode objfpc}{$H+}

uses
  SysUtils, SynMustache, SynCommons;

type
  TSetLengthBytes = procedure (var aBytes: TBytes; NewLength: Integer); {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}

function dmustacheParse1(
  tplStr: PAnsiChar;
  jsonStr: PAnsiChar;
  out outputstr: TBytes;
  SetLengthBytes: TSetLengthBytes): Integer; {$ifdef MSWINDOWS}stdcall;{$else}cdecl;{$endif}
var
  MyTplStr, MyJsonStr, MyOutputStr: RawUTF8;
  outputLen: Integer;
  SynMustacheTemplate: TSynMustache;
begin
  Result := -1;
  if @SetLengthBytes=nil then
     Exit;
  try
    MyTplStr := RawUTF8(tplStr);
    MyJsonStr := RawUTF8(jsonStr);
    SynMustacheTemplate := TSynMustache.Parse(MyTplStr);
    MyOutputStr := SynMustacheTemplate.RenderJSON(MyJsonStr);
    //MyOutputStrAnsi := Utf8ToWinAnsi(MyOutputStr);
    outputLen := Length(MyOutputStr)+1;
    SetLengthBytes(outputstr, outputLen);
    FillChar(outputstr[0], outputLen, 0);
    Move(PAnsiChar(MyOutputStr)^, outputstr[0], outputLen-1);
    Result := 0;
  except
  end;
end;

exports
  dmustacheParse1;

begin
end.

