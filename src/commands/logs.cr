module Faaso
  module Commands
    struct Logs < Command
      @@doc : String = <<-DOC
      Show logs for all instances of a funko.

      Given a funko name, this command will tail the logs of all containers
      associated with that funko.

      Usage:
        faaso logs FUNKO                  [-v <level>] [-l]

      Options:
        -h --help        Show this screen
        -l --local       Run commands locally instead of against a FaaSO server
        -v level         Control the logging verbosity, 0 to 6 [default: 4]
      DOC

      def run : Int32
        if !options["--local"]
          return Faaso.rpc_call(ARGV)
        end
        funko_name = options["FUNKO"].as(String)
        funko = Funko::Funko.from_names([funko_name])[0]
        containers = funko.containers.map { |container|
          {container.@id, container.@names[0].split("-", 2)[-1]}
        }

        channel = Channel(String).new
        containers.each do |id, name|
          spawn do
            docker_api = Docr::API.new(Docr::Client.new)
            body_io = docker_api.containers.logs(
              id,
              follow: true,
              stdout: true,
              stderr: true,
              tail: "10")
            while !body_io.closed?
              body_io.gets.try { |data| channel.send("#{name} >> #{data}") }
            end
          end
        end
        loop do
          select
          when data = channel.receive?
            Log.info { data }
          end
        end
      end
    end
  end
end

Faaso::Commands::COMMANDS["logs"] = Faaso::Commands::Logs
