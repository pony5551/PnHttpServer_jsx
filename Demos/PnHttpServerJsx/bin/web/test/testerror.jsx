require('/common/web.config.jsx');

var PageAction = (function (/*定义参数*/) {

    this.StopWatch = new Date();
    this.Message = '';
    this.ACT = Request.GetParams('ACT','');
    this.PageEvent = Request.GetParams('PageEvent', '');
    this.PageType = Request.GetParams('PageType', '');
    this.PageTitle = '首页';
    this.PageActTitle = '';

    //page参数
    this.pageIndex = Request.GetParams('pageIndex', 1);
    this.pageSize = Request.GetParams('pageSize', 100);
    this.sortField = Request.GetParams('sortField', '');
    this.sortOrder = Request.GetParams('sortOrder', '');

    //Request参数
    this.id = Request.GetParams('id', 0);
    this.orderid = Request.GetParams('orderid', 0);
    this.gcode = Request.GetParams('gcode', '');
    this.gname = Request.GetParams('gname', '');
    this.menuset = Request.GetParams('menuset', '');
    this.menuset2 = Request.GetParams('menuset2', '');
    this.powerset = Request.GetParams('powerset', '');
    this.powerset2 = Request.GetParams('powerset2', '');
    this.CreateTime = Request.GetParams('CreateTime', '');
    this.ids = Request.GetParams('ids', '');
    this.key = Request.GetParams('key', '');

    this.PageDefault = function () {
        var myjson = {};
        myjson.website = {};
        myjson.website.sys_name = 'XXXX管理系统';
        myjson.website.page_title = '用户分组管理';
        myjson.website.page_css = '/doc/css/admin_index.css';
        myjson.website.page_size = 100;
        myjson.website.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();

        var outhtml = JsMVCView.LoadView(
            ["admin_head", "admin_headmast", "admin_sys_usergroup_default", "admin_foot"],
            JsObjMgr.formatjson(myjson, false));
        Response.Write(outhtml);
        myjson = null;
    };
    this.PageDefaultList = function () {
        var myjson = {};
        try {
            var conn = JsObjMgr.NewObject('TJsFDACConn');
            conn.DBServer = webseting.db1.DBServer;
            conn.DBUser = webseting.db1.DBUser;
            conn.DBPass = webseting.db1.DBPass;
            conn.DBName = webseting.db1.DBName;
            conn.OpenDatabase(false);

            var strWhere = '';
            if (key != '') {
                strWhere = '(gcode like \'%' + key + '%\') or (gname like \'%' + key + '%\')';
            }

            var idx = 0;
            myjson.total = 0;
            myjson.data = [];

            try {
                var JsSQLPage = JsObjMgr.NewObject('TJsSQLPages');
                JsSQLPage.Conn = conn;
                JsSQLPage.PageSize = this.pageSize;
                JsSQLPage.CurrentPage = this.pageIndex;
                //字段,表,主键,条件,分组,排序
                JsSQLPage.setSQL('*$db_sys_usergroup$id$' + strWhere + '$$id');
                try {
                    var rs = JsSQLPage.GetRs();
                    myjson.total = JsSQLPage.TotalRecord;
                    while (!rs.Eof) {
                        idx++;
                        var JsonItem = {};
                        JsonItem.IndexID = idx;
                        JsonItem.id = rs.FieldByName('id').AsLargeInt;
                        JsonItem.orderid = rs.FieldByName('orderid').AsLargeInt;
                        JsonItem.gcode = rs.FieldByName('gcode').AsString;
                        JsonItem.gname = rs.FieldByName('gname').AsString;
                        JsonItem.menuset = rs.FieldByName('menuset').AsString;
                        JsonItem.menuset2 = rs.FieldByName('menuset2').AsString;
                        JsonItem.powerset = rs.FieldByName('powerset').AsString;
                        JsonItem.powerset2 = rs.FieldByName('powerset2').AsString;
                        JsonItem.CreateTime = rs.FieldByName('CreateTime').AsDateTime;
                        JsonItem.RowOption = '';

                        myjson.data.push(JsonItem);
                        rs.Next();
                    }
                } finally {
                    JsObjMgr.ReleaseObject(rs);
                    rs = null;
                }
            } finally {
                JsObjMgr.ReleaseObject(JsSQLPage);
                JsSQLPage = null;
            }

        } finally {
            conn.CloseDatabase();
            JsObjMgr.ReleaseObject(conn);
            conn = null;
        }

        myjson.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();
        Response.StatusCode = 200;
        //Response.ContentType = "application/json;charset=utf-8";
        Response.Write(JsObjMgr.formatjson(myjson, false));
        myjson = null;
    };
    //this.AddForm = function () {
    //    var myjson = {};
    //    myjson.website = {};
    //    myjson.website.sys_name = 'XXXX管理系统';
    //    myjson.website.page_title = '系统用户管理';
    //    myjson.website.page_css = '/doc/css/admin_index.css';
    //    myjson.website.page_size = 100;

    //    try {
    //        var conn = JsObjMgr.NewObject('TJsFDACConn');
    //        conn.DBServer = webseting.db1.DBServer;
    //        conn.DBUser = webseting.db1.DBUser;
    //        conn.DBPass = webseting.db1.DBPass;
    //        conn.DBName = webseting.db1.DBName;
    //        conn.OpenDatabase(false);

    //        this.orderid = parseInt(conn.fetchone('select max(orderid) from db_sys_usergroup with(nolock)'));
    //        this.orderid++;
    //        myjson.website.id = id;
    //        myjson.website.orderid = this.orderid;
    //        myjson.website.gcode = this.gcode;
    //        myjson.website.gname = this.gname;
    //        myjson.website.menuset = this.menuset;
    //        myjson.website.menuset2 = this.menuset2;
    //        myjson.website.powerset = this.powerset;
    //        myjson.website.powerset2 = this.powerset2;
    //        myjson.website.CreateTime = this.CreateTime;

    //    } finally {
    //        conn.CloseDatabase();
    //        JsObjMgr.ReleaseObject(conn);
    //        conn = null;
    //    }

    //    myjson.website.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();
    //    var outhtml = JsMVCView.LoadView(
    //        ["admin_head", "admin_headmast", "admin_sys_usergroup_add", "admin_foot"],
    //        JsObjMgr.formatjson(myjson, false));
    //    Response.Write(outhtml);
    //    myjson = null;
    //};
    //this.CheckAddForm = function () {
    //    var bRet = true;
    //    if (!isNaN(this.orderid) && this.orderid <= 0) {
    //        this.Message += '“排序”必须为大于0的正整数！<br>';
    //        bRet = false;
    //    }

    //    if ((this.gcode.length < 4) || (this.gcode.length > 50)) {
    //        this.Message += '“分组编码”限定长度为4-50！<br>';
    //        bRet = false;
    //    }

    //    if ((this.gname.length < 4) || (this.gname.length > 50)) {
    //        this.Message += '“分组名称”限定长度为4-50！<br>';
    //        bRet = false;
    //    }

    //    return bRet;
    //};
    //this.Add = function () {
    //    var myjson = {};
    //    myjson.error = '';
    //    myjson.data = '';

    //    if (!this.CheckAddForm()) {
    //        myjson.error = this.Message.replace(/\r\n/g, '<br>');
    //        Response.Write(JsObjMgr.formatjson(myjson, false));
    //        return;
    //    }

    //    try {
    //        var conn = JsObjMgr.NewObject('TJsFDACConn');
    //        conn.DBServer = webseting.db1.DBServer;
    //        conn.DBUser = webseting.db1.DBUser;
    //        conn.DBPass = webseting.db1.DBPass;
    //        conn.DBName = webseting.db1.DBName;
    //        conn.OpenDatabase(false);

    //        if (conn.fetchone('select id from db_sys_usergroup with(nolock) where ((gname=\'' + conn.StrToSQL(gname) + '\') or (gcode=\'' + conn.StrToSQL(gcode) + '\'))') != '') {
    //            this.Message += '已存在相同的“分组名称”或“分组编码”！<br>';
    //            myjson.error = this.Message.replace(/\r\n/g, '<br>');
    //            myjson.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();
    //            Response.Write(JsObjMgr.formatjson(myjson, false));
    //            return;
    //        }

    //        var strSQL = 'select * from db_sys_usergroup where (gname=\'' + conn.StrToSQL(gname) + '\') or (gcode=\'' + conn.StrToSQL(gcode) + '\')';
    //        try {
    //            var rs = conn.GetRs(strSQL);
    //            if (!rs.Eof) {
    //                this.Message += '<li>已经存在相同的分组！</li><br>';
    //                myjson.error = this.Message.replace(/\r\n/g, '<br>');
    //                myjson.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();
    //                Response.Write(JsObjMgr.formatjson(myjson, false));
    //                return;
    //            }

    //            rs.Insert();
    //            rs.FieldByName('orderid').AsLargeInt = this.orderid;
    //            rs.FieldByName('gcode').AsString = this.gcode;
    //            rs.FieldByName('gname').AsString = this.gname;
    //            rs.Append();

    //        } finally {
    //            JsObjMgr.ReleaseObject(rs);
    //            rs = null;
    //        }

    //        var myId = conn.fetchone('select id from db_sys_usergroup with(nolock) where (gname=\'' + conn.StrToSQL(gname) + '\') or (gcode=\'' + conn.StrToSQL(gcode) + '\')');
    //        this.Message += '“添加分组[' + myId + ']”成功！<br>';
    //        //OperationalLog(Session(APP_CACHENAME + "_UID"), "添加分组", CMSCore.CMSMessage, "db_menu", Rs("id").value, 1);
    //        myjson.error = '';
    //        myjson.data = this.Message.replace(/\r\n/g, '<br>');
    //        myjson.Processed = 'Runtime in ' + ((new Date()).valueOf() - this.StopWatch.valueOf()).toString();
    //        Response.Write(JsObjMgr.formatjson(myjson, false));

    //    } finally {
    //        conn.CloseDatabase();
    //        JsObjMgr.ReleaseObject(conn);
    //        conn = null;
    //    }
    //};


    this.Main = function () {
        switch (this.ACT) {
            case '':
                if (this.PageEvent == '') {
                    this.PageDefault();
                } else if (this.PageEvent == 'List') {
                    this.PageDefaultList();
                }
                break;

            case 'Add':
                if (this.PageEvent == '') {
                    this.AddForm();
                } else if (this.PageEvent == 'SAVE') {
                    this.Add();
                }
                break;


        }
    };

    return this;
})(/*传入参数*/);

PageAction.Main();
PageAction = null;
