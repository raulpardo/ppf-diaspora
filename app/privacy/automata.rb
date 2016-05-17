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
        puts("Larva response: " + sock.gets)
        sock.close
      else
        puts "The communication to the LARVA monitor is disabled"
      end
    end
  end
end
