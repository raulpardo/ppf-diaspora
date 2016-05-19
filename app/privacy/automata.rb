module Privacy
  class Automata
    attr_accessor :monitoring

    def initialize(mon)
      self.monitoring = mon
    end

    def update_policy_automata(user, event, info)
      if monitoring then
        sock = TCPSocket.new('localhost',7)
        message = "diaspora;" + current_user.username.to_s + ";post\n"
        sock.write(message)
        puts("[LARVA - REPONSE] message: " + sock.gets)
        sock.close
      else
        puts "The communication to the LARVA monitor is disabled"
      end
    end

    def startLarvaProtocol()
      #Starting larva automaton
      puts "Starting larva automaton..."
      Thread.new{
        system("sudo aj5 -cp policy-automata/ SocketServerPackage.EchoServer 7")
      }
      puts "Automaton running"

      # Starting receiver of larva policies coming from timers
      Thread.new{
        require 'socket'
        puts "Starting the socket server for larva..."
        
        server = TCPServer.new 3001 # Listenning from port 3001

        loop do
          Thread.start(server.accept) do |client|
            message = client.gets # Waiting for the message from the client
            puts "[LARVA - TIMER] message: " + message.to_s
            if message.include? "enable-posting"
              #Structure of the message '<user_id>;<action>'
              values = message.split(";")
              uid = values.at(0).to_i

              handl = Privacy::Handler.new
              # handl.delete_policy("Mentions",uid)
              handl.delete_policy("Location",uid)

              puts "Enabling mentions for user " + uid.to_s
            end

            client.puts message # Sending the answer
            client.close # Closing the connection
          end
        end
      }      
    end
  end
end
