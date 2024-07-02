require "docr"
require "kemal"
require "../funko.cr"

module Funkos
  get "/funkos/" do |env|
    funkos : Array(Funko) = Funko.from_docker

    funkos.sort! { |a, b| a.name <=> b.name }

    if env.params.query.fetch("format", "json") == "html"
      render "src/views/funkos.ecr"
    else
      funkos.to_json
    end
  end
end
