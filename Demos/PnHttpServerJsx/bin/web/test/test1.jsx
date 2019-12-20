require('./hh.js');

try {

    var hello=new Hello('jone','28','20000')
    hello.say(); 

    Response.Write("test");

} catch(e){
    Response.Write(e.message);
}
