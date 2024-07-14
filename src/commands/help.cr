module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct Help < Command
      @@doc : String = <<-DOC
  FaaSO CLI tool, help command.

  Gives help about how to use the FaaSO CLI tool.

  Usage:
    faaso help
    faaso help COMMAND
  DOC

      def run : Int32
        if !options["COMMAND"]
          Log.info { "Usage: faaso help COMMAND" }
          Log.info { "  COMMAND is one of the following:" }
          Faaso::Commands::COMMANDS.keys.each { |name|
            Log.info { "  #{name}" }
          }
          return 1
        end

        cmdname = options["COMMAND"].as(String)
        raise Exception.new("Unknown command: #{cmdname}") unless Faaso::Commands::COMMANDS.has_key? cmdname
        Log.info { Faaso::Commands::COMMANDS[cmdname].doc }
        1
      end
    end
  end
end

Faaso::Commands::COMMANDS["help"] = Faaso::Commands::Help