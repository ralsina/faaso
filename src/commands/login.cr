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
        # This is tricky. If the service is running behind a reverse proxy
        # then /version is locked, but if it's not, only /auth is locked.
        # So we try /version first without a password, and if it succeeds
        # we try /auth with the password. If /version fails, we try /version
        # with the password
        #
        begin
          # Version without password.
          Crest.get("#{server}version/")
          # Auth with password
          begin
            Crest.get("#{server}auth/", user: "admin", password: password)
          rescue ex : Crest::Unauthorized
            # Failed with auth/
            Log.error { "Wrong password" }
            return 1
          end
        rescue ex : Crest::Unauthorized
          # Version with password
          Crest.get("#{server}version/", user: "admin", password: password)
        end

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
