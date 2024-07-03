module Faaso
  module Commands
    struct Status
      def local(options, name)
        funko = Funko::Funko.from_names([name])[0]
        Log.info { "Name: #{funko.name}" }
        Log.info { "Scale: #{funko.scale}" }
        containers = funko.containers
        Log.info { "Containers: #{funko.containers.size}" }
        containers.each do |container|
          Log.info { "  #{container.@names[0]} #{container.status}" }
        end
        images = funko.images
        Log.info { "Images: #{images.size}" }
        images.each do |image|
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
