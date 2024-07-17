module Faaso
  module Commands
    struct Status < Command
      @@doc : String = <<-DOC
FaaSO CLI tool, status command.

Prints a description of the current status for a funko and the instances
it's running.

Usage:
  faaso status FUNKO...              [-v <level>] [-l]
  faaso status -a                    [-v <level>] [-l]

Options:
  -a --all         Show status for all funkos
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

      def run : Int32
        if !options["--local"]
          return Faaso.rpc_call(ARGV)
        end

        funkos = [] of Funko::Funko
        if options["--all"]
          funkos = Funko::Funko.from_docker
        else
          funkos = Funko::Funko.from_names(options["FUNKO"].as(Array(String)))
        end

        funkos = funkos.reject { |funko| funko.name == "proxy" } # Not a funko

        funkos.each do |funko|
          Log.info { "" }
          status = funko.docker_status

          if status.images.size == 0
            Log.error { "Unkown funko: #{name}" }
            return 1
          end

          Log.info { "Name: #{status.@name}" }
          Log.info { "Scale: #{status.scale}" }

          latest = funko.latest_image
          Log.info { "Containers: #{status.containers.size}" }
          status.containers.each do |container|
            out_of_date = container.@image_id == latest ? "(Current)" : "(Out of date)"
            Log.info { "  #{container.@names[0]} #{container.status} #{out_of_date}" }
          end

          Log.info { "Images: #{status.images.size}" }
          status.images.each do |image|
            Log.info { "  #{image.repo_tags} #{Time.unix(image.created)}" }
          end
        end
        0
      end
    end
  end
end

Faaso::Commands::COMMANDS["status"] = Faaso::Commands::Status
