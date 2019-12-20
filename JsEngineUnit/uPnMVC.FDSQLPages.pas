unit uPnMVC.FDSQLPages;

interface

uses
  System.SysUtils, uPnMVC.FDACConn, FireDAC.Comp.Client;

type
  TPnSQLPages = record
  public
    Conn: TPNFDACConn;
    PageSize,
    CurrentPage,
    TotalRecord,
    TotalPage: Int64;
    CheckSQLCount: Integer;

  private
    Fields,
    TableNames,
    Primarykey,
    Filter,
    Group,
    Order: string;

  public
    //取得SQL所需表字段条件排序,输入:字段,表,主键,条件,分组,排序
    procedure setSQL(strSQL: string);
    //返回分页后的记录集
    function GetRs(): TFDQuery;

  end;

implementation

{ TPnSQLPages }
procedure TPnSQLPages.setSQL(strSQL: string);
var
  tmpSQL: TArray<string>;
begin
  PageSize := 100;
  CurrentPage := 1;
  TotalRecord := 0;
  TotalPage := 1;

  tmpSQL := strSQL.Split(['$']);
  Fields	    := tmpSQL[0];	// 查询字段
  TableNames	:= tmpSQL[1];	// 表名
  Primarykey  := tmpSQL[2];	// 主键
  Filter	    := tmpSQL[3];	// 条件
  Group	      := tmpSQL[4];	// 分组依据
  Order 	    := tmpSQL[5];	// 排序
end;


function TPnSQLPages.GetRs(): TFDQuery;
var
  CountSQL: string;
  CountRs: TFDQuery;
  StartIndex: Int64;
  //EndIndex: Int64;
  strSQL: string;
begin
  // 计算总记录
  if (Pos('inner ', LowerCase(TableNames))>0) or (Pos('left ', LowerCase(TableNames))>0) or (Pos('right ', LowerCase(TableNames))>0) then
  begin
    if (Filter='') then
    begin
      if (Group<>'') then
      begin
        CountSQL := 'select COUNT(rownum) from (select COUNT(*) as rownum from '+TableNames+' group by '+Group+') T';
      end
      else begin
        CountSQL := 'select count(*) from '+TableNames+' ';
      end;
    end
    else begin
      if (Group<>'') then
      begin
        CountSQL := 'select COUNT(rownum) from (select COUNT(*) as rownum from '+TableNames+' where '+Filter+' group by '+Group+') T';
      end
      else begin
        CountSQL := 'select count(*) from '+TableNames+' where '+Filter+' ';
      end;
    end;

  end
  else begin
    if (Filter='') then
    begin
      if (Group<>'') then
      begin
        CountSQL := 'select COUNT(rownum) from (select COUNT(*) as rownum from '+TableNames+' with(nolock) group by '+Group+') T ';
      end
      else begin
        CountSQL := 'select count(*) from '+TableNames+' with(nolock)';
      end;
    end
    else begin
      if (Group<>'') then
      begin
        CountSQL := 'select COUNT(rownum) from (select COUNT(*) as rownum from '+TableNames+' with(nolock) where '+Filter+' group by '+Group+') T ';
      end
      else begin
        CountSQL := 'select count(*) from '+TableNames+' with(nolock) where '+Filter+' ';
      end;
    end;

  end;

  CountRs := Conn.GetRs(CountSQL);
  try
    if (not CountRs.Eof) then
    begin
      TotalRecord := CountRs.Fields[0].AsLongWord;
    end
    else begin
			TotalRecord := 0;
			TotalPage   := 1;
    end;

  finally
    FreeAndNil(CountRs);
  end;

  //计算总页数
  if TotalRecord<>0 then
  begin
    TotalPage := TotalRecord div PageSize;
    if (TotalRecord Mod PageSize)<>0 then
    begin
      TotalPage := TotalPage + 1;
    end;
  end
  else begin
    TotalPage := 1;
  end;

  if (CurrentPage>TotalPage) then
  begin
    CurrentPage := TotalPage;
  end;

  //新分页
  StartIndex := PageSize * (CurrentPage-1) + 1;
  //EndIndex := PageSize * (CurrentPage);
  if (Group<>'') then
  begin
    Group := 'group by ' + Group;
  end;
  if (Order<>'') then
  begin
    Order := 'order by ' + Order;
  end;
  if (Filter<>'') then
  begin
    Filter := ' where ' + Filter;
  end;

  if (Pos('select ', LowerCase(TableNames))>0) or (Pos('from ', LowerCase(TableNames))>0) then
  begin
    strSQL := 'select '+Fields+' from '+TableNames+' '+Filter+' '+Group+' '+Order+' offset '+IntToStr(StartIndex-1)+' rows fetch next '+IntToStr(PageSize)+' rows only';
  end
  else begin
    strSQL := 'select '+Fields+' from '+TableNames+' with(nolock) '+Filter+' '+Group+' '+Order+' offset '+IntToStr(StartIndex-1)+' rows fetch next '+IntToStr(PageSize)+' rows only';
  end;

  Result := Conn.GetRs(strSQL);
  CheckSQLCount := CheckSQLCount + 2;
end;

end.
