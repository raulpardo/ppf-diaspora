package larva;


import SocketServerPackage.EchoServer;

import java.util.LinkedHashMap;
import java.io.PrintWriter;

public class _cls_policy1 implements _callable{

public static LinkedHashMap<_cls_policy1,_cls_policy1> _cls_policy1_instances = new LinkedHashMap<_cls_policy1,_cls_policy1>();

_cls_policy0 parent;
public static String uid;
public static String s;
public String user;
int no_automata = 1;
public Clock c = new Clock(this,"c");
 public int postCounter =0 ;

public static void initialize(){}
//inheritance could not be used because of the automatic call to super()
//when the constructor is called...we need to keep the SAME parent if this exists!

public _cls_policy1( String user) {
parent = _cls_policy0._get_cls_policy0_inst();
c.register(40000l);
this.user = user;
}

public void initialisation() {
   c.reset();
}

public static _cls_policy1 _get_cls_policy1_inst( String user) { synchronized(_cls_policy1_instances){
_cls_policy1 _inst = new _cls_policy1( user);
if (_cls_policy1_instances.containsKey(_inst))
{
_cls_policy1 tmp = _cls_policy1_instances.get(_inst);
 return _cls_policy1_instances.get(_inst);
}
else
{
 _inst.initialisation();
 _cls_policy1_instances.put(_inst,_inst);
 return _inst;
}
}
}

public boolean equals(Object o) {
 if ((o instanceof _cls_policy1)
 && (user == null || user.equals(((_cls_policy1)o).user))
 && (parent == null || parent.equals(((_cls_policy1)o).parent)))
{return true;}
else
{return false;}
}

public int hashCode() {
return 0;
}

public void _call(String _info, int... _event){
synchronized(_cls_policy1_instances){
_performLogic_diaspora(_info, _event);
}
}

public void _call_all_filtered(String _info, int... _event){
}

public static void _call_all(String _info, int... _event){

_cls_policy1[] a = new _cls_policy1[1];
synchronized(_cls_policy1_instances){
a = _cls_policy1_instances.keySet().toArray(a);}
for (_cls_policy1 _inst : a)

if (_inst != null) _inst._call(_info, _event);
}

public void _killThis(){
try{
if (--no_automata == 0){
synchronized(_cls_policy1_instances){
_cls_policy1_instances.remove(this);}
synchronized(c){
c.off();
c._inst = null;
c = null;}
}
else if (no_automata < 0)
{throw new Exception("no_automata < 0!!");}
}catch(Exception ex){ex.printStackTrace();}
}

int _state_id_diaspora = 0;

public void _performLogic_diaspora(String _info, int... _event) {

_cls_policy0.pw.println("[diaspora]AUTOMATON::> diaspora("+user + " " + ") STATE::>"+ _string_diaspora(_state_id_diaspora, 0));
_cls_policy0.pw.flush();

if (0==1){}
else if (_state_id_diaspora==0){
		if (1==0){}
		else if ((_occurredEvent(_event,0/*postEvent*/)) && (postCounter <1 )){
		EchoServer .response ("do-nothing\n");
postCounter ++;

		_state_id_diaspora = 0;//moving to state start
		_goto_diaspora(_info);
		}
		else if ((_occurredEvent(_event,0/*postEvent*/)) && (postCounter ==1 )){
		EchoServer .response ("disable-posting\n");

		_state_id_diaspora = 0;//moving to state start
		_goto_diaspora(_info);
		}
		else if ((_occurredEvent(_event,2/*clockEvent*/)) && (postCounter ==1 )){
		EchoServer .timer_handler (user +";enable-posting\n");
postCounter =0 ;
c .reset ();

		_state_id_diaspora = 0;//moving to state start
		_goto_diaspora(_info);
		}
		else if ((_occurredEvent(_event,2/*clockEvent*/)) && (postCounter <1 )){
		EchoServer .timer_handler (user +";do-nothing\n");
c .reset ();

		_state_id_diaspora = 0;//moving to state start
		_goto_diaspora(_info);
		}
}
}

public void _goto_diaspora(String _info){
_cls_policy0.pw.println("[diaspora]MOVED ON METHODCALL: "+ _info +" TO STATE::> " + _string_diaspora(_state_id_diaspora, 1));
_cls_policy0.pw.flush();
}

public String _string_diaspora(int _state_id, int _mode){
switch(_state_id){
case 0: if (_mode == 0) return "start"; else return "start";
default: return "!!!SYSTEM REACHED AN UNKNOWN STATE!!!";
}
}

public boolean _occurredEvent(int[] _events, int event){
for (int i:_events) if (i == event) return true;
return false;
}
}