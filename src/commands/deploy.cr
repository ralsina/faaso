module Faaso
  module Commands
    struct Deploy < Command
      @@name = "deploy"
      @@doc : String = <<-DOC
Make funko instances up-to-date.

Looks at the current number of running containers for a funko and if any
are out of date (running an image that is not the latest) it will scale
up with new containers, wait for them to be healthy, then scale back down
to the original number of containers.

Usage:
  faaso deploy FUNKO                [-v <level>] [-l]

Options:
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def run : Int32
        funko_name = options["FUNKO"].as(String)
        Log.info { "Deploying #{funko_name}" }

        return Faaso.rpc_call(ARGV) unless options["--local"]

        funko = Funko::Funko.from_names([funko_name])[0]
        # Get scale, check for out-of-date containers
        current_scale = funko.scale
        latest_image = funko.latest_image
        containers = funko.containers
        out_of_date = containers.count { |container| container.image_id != latest_image }
        if out_of_date == 0
          Log.info { "All containers are up-to-date" }
          return 0
        end
        Log.info { "Need to update #{out_of_date} containers" }
        Log.info { "Scaling from #{current_scale} to #{current_scale + out_of_date}" }
        # Increase scale to get enough up-to-date containers
        new_containers = funko.scale(current_scale + out_of_date)

        # Wait for them to be healthy
        begin
          Log.info { "Waiting for #{current_scale + out_of_date} containers to be healthy" }
          funko.wait_for(current_scale + out_of_date, 120, healthy: true)
        rescue ex : Exception
          # Failed to start, rollback
          Log.error(exception: ex) { "Failed to scale, rolling back" }
          docker_api = Docr::API.new(Docr::Client.new)
          new_containers.each do |container_id|
            docker_api.containers.stop(container_id)
            docker_api.containers.delete(container_id)
          end
          return 1
        end

        Log.info { "Scaling down to #{current_scale}" }
        # Decrease scale to the desired amount
        funko.scale(current_scale)
        funko.wait_for(current_scale, 30)
        Log.info { "Deployed #{funko_name}" }
        0
      end
    end
  end
end

Faaso::Commands::Deploy.register
