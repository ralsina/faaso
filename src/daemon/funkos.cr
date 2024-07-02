require "docr"
require "kemal"

module Funkos
  struct Funko
    include JSON::Serializable
    property name : String

    def initialize(@name : String)
    end
  end

  get "/funkos/" do |env|
    docker_api = Docr::API.new(Docr::Client.new)
    containers = docker_api.containers.list(all: true)

    funkos = [] of Funko
    containers.each { |container|
      names = container.names.select &.starts_with? "/faaso-"
      next if names.empty?
      funkos << Funko.new(name: names[0][7..])
    }
    funkos.sort! { |a, b| a.name <=> b.name }

    if env.params.query.fetch("format", "json") == "html"
        render "src/views/funkos.ecr"
    else
      funkos.to_json
    end
  end
end