module Faaso
  module Commands
    # Controls a funko's scale
    #
    # Scale is how many instances are running.
    #
    # If it's increased, more instances are created.
    # It it's decreased, instances are destroyed.
    #
    # In both cases stopped instances after the required
    # scale is reached are deleted.
    struct Scale
      def local(options, name, scale)
        funko = Funko::Funko.from_names([name])[0]
        # Asked about scale
        if !scale
          Log.info { "Funko #{name} has a scale of #{funko.scale}" }
          return 0
        end
        # Asked to set scale
        if funko.image_history.empty?
          Log.error { "Error: no images available for #{funko.name}:latest" }
          exit 1
        end
        funko.scale(scale.as(String).to_i)
      end

      def remote(options, name, scale)
        if !scale
          response = Crest.get(
            "#{FAASO_SERVER}funkos/#{name}/scale/", \
               user: "admin", password: "admin")
        else
          response = Crest.post(
            "#{FAASO_SERVER}funkos/#{name}/scale/",
            {"scale" => scale}, user: "admin", password: "admin")
        end
        body = JSON.parse(response.body)
        Log.info { body["output"] }
      rescue ex : Crest::InternalServerError
        Log.error { "Error scaling funko #{name}" }
        body = JSON.parse(ex.response.body)
        Log.info { body["output"] }
        exit 1
      end

      def run(options, name, scale)
        if options["--local"]
          return local(options, name, scale)
        end
        remote(options, name, scale)
      end
    end
  end
end
