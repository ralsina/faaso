module Faaso
  module Commands
    struct Secret
      def local(options, funko, name, secret) : Int32
        if options["--add"]
          dst_dir = "secrets/#{funko}"
          Dir.mkdir_p(dst_dir) unless Dir.exists?(dst_dir)
          File.write("#{dst_dir}/#{name}", secret)
        elsif options["--delete"]
          File.delete("secrets/#{funko}/#{name}")
        end
        0
      end

      def remote(options, funko, name, secret) : Int32
        if options["--add"]
          Crest.post(
            "#{FAASO_SERVER}secrets/",
            {
              "funko" => funko,
              "name"  => name,
              "value" => secret,
            }, user: "admin", password: "admin")
          Log.info { "Secret created" }
        elsif options["--delete"]
          Crest.delete(
            "#{FAASO_SERVER}secrets/#{funko}/#{name}",
            user: "admin", password: "admin")
        end
        0
      rescue ex : Crest::RequestFailed
        Log.error { "Error #{ex.response.status_code}" }
        1
      end

      def run(options, funko, name) : Int32
        if options["--add"]
          Log.info { "Enter the secret, end with Ctrl-D" } if STDIN.tty?
          secret = STDIN.gets_to_end
        else
          secret = ""
        end

        if options["--local"]
          return local(options, funko, name, secret)
        end
        remote(options, funko, name, secret)
      end
    end
  end
end
