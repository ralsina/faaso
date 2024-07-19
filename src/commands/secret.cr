require "../utils.cr"

module Faaso
  module Commands
    struct Secret < Command
      @@doc : String = <<-DOC
Manage server-side secrets.

Secret called SECRET for a funko called FUNKO are
made available in runtime for the FUNKO container in a file
called /secrets/SECRET

You can use this command to add/delete those secrets.

Usage:
  faaso secret (-d|-a) FUNKO SECRET [-v <level>] [-l]

Options:
  -a --add         Add new secret
  -d --delete      Delete existing secret
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def local(funko, name, secret) : Int32
        if options["--add"]
          dst_dir = "secrets/#{funko}"
          Dir.mkdir_p(dst_dir) unless Dir.exists?(dst_dir)
          File.write("#{dst_dir}/#{name}", secret)
        elsif options["--delete"]
          File.delete("secrets/#{funko}/#{name}")
        end
        0
      end

      def remote(funko, name, secret) : Int32
        # Can't use generic RPC because it needs to process terminal input
        Faaso.check_version
        user, password = Config.auth
        if options["--add"]
          Crest.post(
            "#{Config.server}secrets/",
            {
              "funko" => funko,
              "name"  => name,
              "value" => secret,
            }, user: user, password: password)
          Log.info { "Secret created" }
        elsif options["--delete"]
          Crest.delete(
            "#{Config.server}secrets/#{funko}/#{name}",
            user: user, password: password)
        end
        0
      rescue ex : Crest::RequestFailed
        Log.error { "Error #{ex.response.status_code}" }
        1
      end

      def run : Int32
        funko = options["FUNKO"].as(String)
        name = options["SECRET"].as(String)
        if options["--add"]
          if STDIN.tty?
            Log.info { "Enter the secret, end with Ctrl-D" }
            sleep 0.1.seconds
          end
          secret = Utils.get_secret(echo_stars: true, one_line: false)
        else
          secret = ""
        end

        if options["--local"]
          return local(funko, name, secret)
        end
        remote(funko, name, secret)
      end
    end
  end
end

Faaso::Commands::COMMANDS["secret"] = Faaso::Commands::Secret
