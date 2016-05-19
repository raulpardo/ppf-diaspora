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

    
    def startLarvaWeekendNotifier()
      #This thread will check from the Diaspora side the time so that the automaton does not have to use a clock.
      puts "Starting the weekend notifier"
      Thread.new{
        policy_handler = Privacy::Checker.new
        #It runs forever
        while true
          time = Time.new
          #We retreive all users with the weekend policy activated
          PrivacyPolicy.where(:shareable_type => "weekend-location").find_each do |policy|
            #If it is friday we notify the larva automaton
            if time.sec == 45
              puts "Friday has started for user "+policy.user_id.to_s+" activating policies"
              policy_handler.send_to_larva(policy.user_id,"friday")
            end
            #If it is monday we notify the larva automaton
            if time.sec == 15
              puts "Monday has started for user "+policy.user_id.to_s+" deactivating policies"
              policy_handler.send_to_larva(policy.user_id,"monday")
            end

            # Alternative to the 3 times per day, without timers
            # #If it is monday we notify the larva automaton
            # if time.hour == 0 && time.min == 0
            #   puts "A new day has started for user "+policy.user_id.to_s+" deactivating policies"
            #   policy_handler.send_to_larva(policy.user_id,"midnight")
            # end
          end
          sleep 1 # Delays of 3 seconds to not check to regularly
        end
      }

    end
    
  end # class
end # module
