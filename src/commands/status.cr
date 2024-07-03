module Faaso
  module Commands
    struct Status
      def local(options, name)
        funko = Funko::Funko.from_names([name])[0]
        status = funko.docker_status

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
      end

      def remote(options, name)
        response = Crest.get(
          "#{FAASO_SERVER}funkos/#{name}/status/", \
             user: "admin", password: "admin")
        body = JSON.parse(response.body)
        Log.info { body["output"] }
      rescue ex : Crest::InternalServerError
        Log.error { "Error scaling funko #{name}" }
        body = JSON.parse(ex.response.body)
        Log.info { body["output"] }
        exit 1
      end

      def run(options, name)
        if options["--local"]
          return local(options, name)
        end
        remote(options, name)
      end
    end
  end
end