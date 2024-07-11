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
      def run(options, name : String, scale) : Int32
        scale = scale.try &.to_s.to_i
        funko = Funko::Funko.from_names([name])[0]
        # Asked about scale
        if funko.image_history.empty?
          Log.error { "Unknown funko #{funko.name}" }
          return 1
        end
        if scale.nil?
          Log.info { "Funko #{name} has a scale of #{funko.scale}" }
          return 0
        end
        # Asked to set scale
        funko.scale(scale)
        0
      end
    end
  end
end
