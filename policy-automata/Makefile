LARVA="/home/pardo/LARVA complete package/Larva system/"
JAVA_VERSION=1.8
CURRENT:=$(shell pwd)

compile: 
	java -cp $(LARVA):. compiler.Compiler $(CURRENT)/policy.lrv -o $(CURRENT)
	javac -target $(JAVA_VERSION) SocketServerPackage/EchoServer.java 
	ajc -1.5 -cp aspectjrt.jar:. -sourceroots .
	ajc -1.5 -cp aspectjrt.jar:. -outxmlfile ./META-INF/aop.xml ./aspects/*.aj

run:
	sudo aj5 -cp . SocketServerPackage.EchoServer 7

clean:
	rm -rf META-INF/ larva/ aspects/ output_policy.txt _diag_diaspora.txt
