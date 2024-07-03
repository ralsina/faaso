module Faaso
  module Commands
    struct Status
      def local(options, name)
        funko = Funko::Funko.from_names([name])[0]
        status = funko.docker_status

        Log.info { "Name: #{status["name"]}" }
        Log.info { "Scale: #{status["scale"]}" }

        Log.info { "Containers: #{status["containers"].size}" }
        status["containers"].each do |container|
          Log.info { "  #{container.@names[0]} #{container.status}" }
        end

        Log.info { "Images: #{status["images"].size}" }
        status["images"].each do |image|
          Log.info { "  #{image.repo_tags} #{image.created}" }
        end
      end

      def remote(options, name)
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
