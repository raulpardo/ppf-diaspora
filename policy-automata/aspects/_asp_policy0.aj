package aspects;

import SocketServerPackage.EchoServer;

import larva.*;
public aspect _asp_policy0 {

public static Object lock = new Object();

boolean initialized = false;

after():(staticinitialization(*)){
if (!initialized){
	initialized = true;
	_cls_policy0.initialize();
}
}
}