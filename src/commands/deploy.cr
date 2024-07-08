module Faaso
  module Commands
    struct Deploy
      # FIXME: local only for now
      def run(options, funko_name : String) : Int32
        Log.info { "Deploying #{funko_name}" }
        funko = Funko::Funko.from_names([funko_name])[0]
        # Get scale, check for out-of-date containers
        current_scale = funko.scale
        latest_image = funko.latest_image
        containers = funko.containers
        out_of_date = containers.count { |container| container.image_id != latest_image }
        Log.info { "Need to update #{out_of_date} containers" }
        Log.info { "Scaling from #{current_scale} to #{current_scale + out_of_date}" }
        # Increase scale to get enough up-to-date containers
        new_containers = funko.scale(current_scale + out_of_date)

        # Wait for them to be healthy
        begin
          funko.wait_for(current_scale + out_of_date, 120, healthy: true)
        rescue ex : Exception
          # Failed to start, rollback
          Log.error(exception: ex) { "Failed to scale, rolling back" }
          docker_api = Docr::API.new(Docr::Client.new)
          new_containers.each do |container|
            docker_api.containers.stop(container.id)
            docker_api.containers.delete(container.id)
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
