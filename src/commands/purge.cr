module Faaso
  module Commands
    struct Purge < Command
      @@doc : String = <<-DOC
FaaSO CLI tool, purge command.

Stops and deletes all containers for the given funkos,
and deletes all associated images.

Usage:
  faaso purge FUNKO...              [-v <level>] [-l]

Options:
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def run : Int32
        if !options["--local"]
          return Faaso.rpc_call(ARGV)
        end

        funkos = [] of Funko::Funko
        if options["FUNKO"].as(Array(String)).empty?
          Log.info { "No funko specified, doing nothing" }
          return 0
        else
          Log.info { "Purging..." }
          funkos = Funko::Funko.from_names(options["FUNKO"].as(Array(String)))
        end

        funkos.each do |funko|
          Log.info { "  #{funko.name}" }
          Log.info { "    Stopping..." }
          funko.scale(0)
          funko.wait_for(0, 30)
          Log.info { "    Removing all containers..." }
          funko.remove_all_containers
          Log.info { "    Removing all images..." }
          funko.remove_all_images
        end
        0
      end
    end
  end
end

Faaso::Commands::COMMANDS["purge"] = Faaso::Commands::Purge
