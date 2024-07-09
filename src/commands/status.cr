module Faaso
  module Commands
    struct Status
      def local(options, name) : Int32
        funko = Funko::Funko.from_names([name])[0]
        status = funko.docker_status

        if status.images.size == 0
          Log.error { "Unkown funko: #{name}" }
          return 1
        end

        Log.info { "Name: #{status.@name}" }
        Log.info { "Scale: #{status.scale}" }

        Log.info { "Containers: #{status.containers.size}" }
        status.containers.each do |container|
          Log.info { "  #{container.@names[0]} #{container.status}" }
        end

        Log.info { "Images: #{status.images.size}" }
        status.images.each do |image|
          Log.info { "  #{image.repo_tags} #{Time.unix(image.created)}" }
        end
        0
      end

      def remote(options, name) : Int32
        Faaso.check_version
        user, password = Config.auth
        Crest.get(
          "#{Config.server}funkos/#{name}/status/", \
             user: user, password: password) do |response|
          IO.copy(response.body_io, STDOUT)
        end
        0
      rescue ex : Crest::InternalServerError
        Log.error(exception: ex) { "Error scaling funko #{name}" }
        1
      end

      def run(options, name) : Int32
        if options["--local"]
          return local(options, name)
        end
        remote(options, name)
      end
    end
  end
end
