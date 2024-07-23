module Faaso
  module Commands
    struct Scale < Command
      @@name = "scale"
      @@doc : String = <<-DOC
Start or stop funko instances.

A funko's scale is how many instances are running.

* Given a funko name, it will print the current scale.
* Given a funko name and a number, it will start or stop instances
  to reach that new scale.

Usage:
  faaso scale FUNKO [SCALE]         [-v <level>] [-l]

Options:
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def run : Int32
        if !options["--local"]
          return Faaso.rpc_call(ARGV)
        end
        scale = options["SCALE"].try &.to_s.to_i
        name = options["FUNKO"].as(String)
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

Faaso::Commands::Scale.register()
