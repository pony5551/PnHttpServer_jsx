function factorial2(n) {
    var a = [1];
    var m, i, j;
    var len = 16 - (n + '').length;
    var range = Math.pow(10, len);
    //Response.Write(len + ',' + range);
    for (i = 1; i <= n; ++i) {
        for (j = 0, c = 0; j < a.length || c != 0; ++j) {
            m = (j < a.length) ? (i * a[j] + c) : c;
            a[j] = m % range;
            //Response.Write(i + ',' + n + ',' + m + ','+ a[j] +'<br>');                        
            c = Math.floor(m / range);
        }
    }
    for (i = 0; i < a.length - 1; ++i) {
        a[i] = (Math.pow(10, len - (a[i] + '').length) + '' + a[i]).substr(1);
    }
    return a.reverse().join("");
}

function showReport(n) {
    n = parseInt(n);
    if (isNaN(n)) {
        return "非数字";
    }

    var buffer = [];//["<table border=1 style='table-layout:fixed;font-family:tahoma;font-size:12px;word-wrap:break-word'><tr><td width=60>n</td><td width=60>time(ms)</td><td>result</td></tr>"];
    var ss = new Date();
    var pp = factorial2(n);
    var tt = (new Date()).valueOf() - ss.valueOf();
    buffer.push("<tr bgcolor=#efefef><td>" + n + "</td><td>" + tt + "</td><td>" + pp + "</td></tr>");
    //buffer.push("</table>");
    //buffer.push("=====" + n + ", " + tt + "ms, " + pp);
    return buffer.join("");
}

Response.Write("<table border=1 style='table-layout:fixed;font-family:tahoma;font-size:12px;word-wrap:break-word'><tr><td width=60>n</td><td width=60>time(ms)</td><td>result</td></tr>");
var nums = [100, 500, 800, 1000, 2000, 3000];
for (var i = 0; i < nums.length; i++) {
    Response.Write(showReport(nums[i]) + "\r\n<br>");
}
Response.Send("</table>");