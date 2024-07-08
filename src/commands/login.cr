module Faaso
  module Commands
    struct Login
      def run(options) : Int32
        server = Config.server
        Log.info { "Enter password for #{server}" }
        if STDIN.tty?
          password = (STDIN.noecho &.gets.try &.chomp).to_s
        else
          password = STDIN.gets.to_s
        end
        # Testing with auth/ which is guaranteed locked
        Crest.get(
          "#{server}auth/", \
             user: "admin", password: password).body
        # If we got here the password is ok
        CONFIG.hosts[server] = {"admin", password}
        Config.save
        0
      rescue ex : Crest::Unauthorized
        Log.error { "Wrong password" }
        1
      rescue ex : Socket::ConnectError
        Log.error { "Connection refused" }
        1
      end
    end
  end
end
