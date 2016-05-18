package aspects;

import SocketServerPackage.EchoServer;

import larva.*;
public aspect _asp_policy1 {

boolean initialized = false;

after():(staticinitialization(*)){
if (!initialized){
	initialized = true;
	_cls_policy1.initialize();
}
}
before ( Clock _c, long millis) : (call(* Clock.event(long)) && args(millis) && target(_c)  && (if (_c.name.equals("c"))) && (if (millis == 40000)) && !cflow(adviceexecution())) {

synchronized(_asp_policy0.lock){
String user;
user =null ;

synchronized(_c){
 if (_c != null && _c._inst != null) {
_c._inst._call(thisJoinPoint.getSignature().toString(), 2/*clockEvent*/);
_c._inst._call_all_filtered(thisJoinPoint.getSignature().toString(), 2/*clockEvent*/);
}
}
}
}
before ( String uid,String s) : (call(* *.post(..)) && args(uid,s) && !cflow(adviceexecution())) {

synchronized(_asp_policy0.lock){
String user;
user =uid ;

_cls_policy1 _cls_inst = _cls_policy1._get_cls_policy1_inst( user);
_cls_inst.uid = uid;
_cls_inst.s = s;
_cls_inst._call(thisJoinPoint.getSignature().toString(), 0/*postEvent*/);
_cls_inst._call_all_filtered(thisJoinPoint.getSignature().toString(), 0/*postEvent*/);
}
}
}