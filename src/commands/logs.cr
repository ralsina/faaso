module Faaso
  module Commands
    struct Logs
      def run(options, funko_name : String) : Int32
        funko = Funko::Funko.from_names([funko_name])[0]
        containers = funko.containers.map { |c|
          p! c.@names
          {c.@id, c.@names[0].split("-",2)[-1]}
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
              body_io.gets.try { |s| channel.send("#{name} >> #{s}") }
            end
          end
        end
        loop do
          select
          when data = channel.receive?
            puts data
          end
        end
      end
    end
  end
end
