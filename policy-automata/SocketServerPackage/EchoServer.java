/*
 * Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 *   - Neither the name of Oracle or the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package SocketServerPackage;

import java.net.*;
import java.io.*;
import java.util.*;

public class EchoServer {
    static PrintWriter out;
    public static void main(String[] args) throws IOException {

        if (args.length != 1) {
            System.err.println("Usage: java EchoServer <port number>");
            System.exit(1);
        }

        int portNumber = Integer.parseInt(args[0]);

        try {
	ServerSocket serverSocket =
                new ServerSocket(Integer.parseInt(args[0]));
	while(true){
            Socket clientSocket = serverSocket.accept();
            out =
                new PrintWriter(clientSocket.getOutputStream(), true);
            BufferedReader in = new BufferedReader(
                new InputStreamReader(clientSocket.getInputStream()));

            String inputLine;
            // This loop guarantees that only the messges that are not null are
            // read. readLine() keeps reading null values in the socket until
            // the client program writes anything else in the socket. The server
            // finishes when the client finishes its executing. The server is
            // able to detect that the client closed the connection to the
            // socket.
	    while ((inputLine = in.readLine()) != null) {
		System.out.println("Message receive: " + inputLine);
		// Structure of the message 'diaspora;<user_id>;<action>'
		List<String> list = new ArrayList<String>(Arrays.asList(inputLine.split(";")));
		EchoServer a = new EchoServer();
		if(list.get(2).toString().equals("post")){
		    a.post(list.get(1).toString(), "nothing");
		}
		
		if(list.get(2).toString().equals("monday")){
		    a.monday(list.get(1).toString(), "nothing");
		}

		if(list.get(2).toString().equals("friday")){
		    a.friday(list.get(1).toString(), "nothing");
		}
	    }
	}
        } catch (IOException e) {
            System.out.println("Exception caught when trying to listen on port "
                + portNumber + " or listening for a connection");
            System.out.println(e.getMessage());
        }
    }

    public void post(String u, String s) {}
    public void monday(String u, String s) {}
    public void friday(String u, String s) {}

    public static void response(String s){
	//timer_handler(s);
        out.println(s);
    }

    public static void timer_handler(String m){
	String hostName = "localhost";
	int portNumber = 3001;

	try { 
            Socket echoSocket = new Socket(hostName, portNumber);
            PrintWriter out =
                new PrintWriter(echoSocket.getOutputStream(), true);
            BufferedReader in =
                new BufferedReader(
                    new InputStreamReader(echoSocket.getInputStream()));
                
	    out.println(m);
	    System.out.println("Diaspora answer: " + in.readLine());
	
        } catch (UnknownHostException e) {
            System.err.println("Don't know about host " + hostName);
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Couldn't get I/O for the connection to " +
                hostName);
            System.exit(1);
        }
    }
}
