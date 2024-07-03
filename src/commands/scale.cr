module Faaso
  module Commands
    # Bring up one or more funkos by name.
    #
    # This doesn't guarantee that they will be running the latest
    # version, and it will try to recicle paused and exited containers.
    #
    # If there is no other way, it will create a brand new container with
    # the latest known image and start it.
    #
    # If there are no images for the funko, it will fail to bring it up.
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

        #     case self
        #     when .running?
        #       # If it's already up, do nothing
        #       # FIXME: bring back out-of-date warning
        #       Log.info { "#{funko.name} is already up" }
        #     when .paused?
        #       # If it is paused, unpause it
        #       Log.info { "Resuming existing paused container" }
        #       funko.unpause
        #     when .exited?
        #       Log.info { "Starting function #{funko.name}" }
        #       Log.info { "Restarting existing exited container" }
        #       funko.start
        #     else
        #       # Only have an image, deploy from scratch
        #       Faaso.setup_network # We need it
        #       Log.info { "Creating and starting new container" }
        #       funko.create_container(autostart: true)

        #       (1..5).each { |_|
        #         break if funko.running?
        #         sleep 0.1.seconds
        #       }
        #       if !funko.running?
        #         Log.warn { "Container for #{funko.name} is not running yet" }
        #         next
        #       end
        #       Log.info { "Container for #{funko.name} is running" }
        #     end
      end
    end
  end
end
