

try {
require('/common/web.config.jsx');
require('/common/web.db.const.jsx');

var myjson = {};
myjson.website = {};
myjson.website.page_title = '测试页面';
myjson.website.page_url = 'http://www.baidu.com';
myjson.website.pagesize = 100;
myjson.website.data = [];
myjson.website.data[0] = 'd1';
myjson.website.data[1] = 'd1';

Response.Write(JsObjMgr.formatjson(myjson,false));

} catch(e){
    Response.Write(e.message);
}
