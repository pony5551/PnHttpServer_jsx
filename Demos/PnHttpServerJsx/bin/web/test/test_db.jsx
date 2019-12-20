require('/common/web.config.jsx');
require('/common/web.sys.functions.jsx');

try {
    try {
        var conn = JsObjMgr.NewObject('TJsFDACConn','db1');
        conn.DBServer = webseting.db1.DBServer;
        conn.DBUser = webseting.db1.DBUser;
        conn.DBPass = webseting.db1.DBPass;
        conn.DBName = webseting.db1.DBName;
        conn.OpenDatabase(false);

        try {
            var rs = conn.GetRs('select * from db_sys_user with(nolock)');
            while (!rs.Eof) {
                Response.Write(rs.FieldByName('id').AsInteger+',');
                Response.Write(rs.FieldByName('uid').AsString + ',');
	Response.Write((new Date(rs.FieldByName('regtime').AsDateTime)).format('yyyy-MM-dd hh:mm:ss.S')+',');
	Response.Write('<br>\r\n');

                rs.Next();
            }
        } finally {
            JsObjMgr.ReleaseObject(rs);
            rs = null;
        }

    } finally {
        //conn.CloseDatabase();
        JsObjMgr.ReleaseObject(conn);
        conn = null;
    }

} catch(e){
    Response.Write(e.message);
}
