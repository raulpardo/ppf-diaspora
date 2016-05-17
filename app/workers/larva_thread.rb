require 'socket'

class LarvaThread
  include Sidekiq::Worker
  sidekiq_options :queue => :critical

  def perform()
    puts "Starting the socket server for larva..."
    
    server = TCPServer.new 3001 # Listenning from port 3001

    loop do
      Thread.start(server.accept) do |client|
        message = client.gets # Waiting for the message from the client
        puts "Clients message: " + message.to_s
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
  end
end

LarvaThread.perform_async
