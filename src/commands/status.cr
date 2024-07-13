module Faaso
  module Commands
    struct Status < Command
      @@doc : String = <<-DOC
FaaSO CLI tool, status command.

Prints a description of the current status for a funko and the instances
it's running.

Usage:
    faaso status FUNKO                [-v <level>] [-l]

Options:
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def run : Int32
        if !options["--local"]
          return Faaso.rpc_call(ARGV)
        end
        name = options["FUNKO"].as(String)
        funko = Funko::Funko.from_names([name])[0]
        status = funko.docker_status

        if status.images.size == 0
          Log.error { "Unkown funko: #{name}" }
          return 1
        end

        Log.info { "Name: #{status.@name}" }
        Log.info { "Scale: #{status.scale}" }

        Log.info { "Containers: #{status.containers.size}" }
        status.containers.each do |container|
          Log.info { "  #{container.@names[0]} #{container.status}" }
        end

        Log.info { "Images: #{status.images.size}" }
        status.images.each do |image|
          Log.info { "  #{image.repo_tags} #{Time.unix(image.created)}" }
        end
        0
      end
    end
  end
end

Faaso::Commands::COMMANDS["status"] = Faaso::Commands::Status
