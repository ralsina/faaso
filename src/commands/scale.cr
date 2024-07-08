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
      def local(options, name : String, scale : Int) : Int32
        funko = Funko::Funko.from_names([name])[0]
        # Asked about scale
        if funko.image_history.empty?
          Log.error { "Unknown funko #{funko.name}" }
          return 1
        end
        if !scale
          Log.info { "Funko #{name} has a scale of #{funko.scale}" }
          return 0
        end
        # Asked to set scale
        funko.scale(scale)
        0
      end

      def remote(options, name : String, scale : Int) : Int32
        user, password = Config.auth
        Faaso.check_version
        if !scale
          response = Crest.get(
            "#{Config.server}funkos/#{name}/scale/", \
               user: user, password: password)
          Log.info { " => " + response.body }
        else
          response = Crest.post(
            "#{Config.server}funkos/#{name}/scale/",
            {"scale" => scale}, user: user, password: password)
          Log.info { " => " + response.body }
        end
        0
      rescue ex : Crest::InternalServerError
        Log.error(exception: ex) { "Error scaling funko #{name}" }
        1
      end

      def run(options, name : String, scale : Int) : Int32
        if options["--local"]
          return local(options, name, scale)
        end
        remote(options, name, scale)
      end
    end
  end
end
