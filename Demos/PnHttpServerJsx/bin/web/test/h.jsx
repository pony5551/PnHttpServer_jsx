Response.StatusCode = 200;
Response.ContentType = "text/html;charset=utf-8";

try {
var myjson = {};
myjson.website = {};
myjson.website.sys_name = '系统名称';
myjson.website.page_title = '标题';
myjson.website.name = '用户管理';
myjson.website.url = 'http://www.ssss.com/users';

var outhtml = JsMVCView.LoadView(
["test_head","test_headmast","test","test_foot"], 
JsObjMgr.formatjson(myjson,false));

Response.Write(outhtml);
Response.Write("hello js\r\n<br>");
Response.Write("hello js", true);
} catch(e){
Response.Write("error: "+e.message);
}