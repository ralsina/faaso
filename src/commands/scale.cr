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
      def local(options, name, scale) : Int32
        funko = Funko::Funko.from_names([name])[0]
        # Asked about scale
        if !scale
          Log.info { "Funko #{name} has a scale of #{funko.scale}" }
          return 0
        end
        # Asked to set scale
        if funko.image_history.empty?
          Log.error { "Error: no images available for #{funko.name}:latest" }
          return 1
        end
        funko.scale(scale.as(String).to_i)
        0
      end

      def remote(options, name, scale) : Int32
        Faaso.check_version
        if !scale
          Crest.get(
            "#{FAASO_SERVER}funkos/#{name}/scale/", \
               user: "admin", password: "admin") do |response|
            loop do
              Log.info { response.body_io.gets }
              break if response.body_io.closed?
            end
          end
        else
          Crest.post(
            "#{FAASO_SERVER}funkos/#{name}/scale/",
            {"scale" => scale}, user: "admin", password: "admin") do |response|
            loop do
              Log.info { response.body_io.gets }
              break if response.body_io.closed?
            end
          end
        end
        0
      rescue ex : Crest::InternalServerError
        Log.error(exception: ex) { "Error scaling funko #{name}" }
        1
      end

      def run(options, name, scale) : Int32
        if options["--local"]
          return local(options, name, scale)
        end
        remote(options, name, scale)
      end
    end
  end
end
