require "docr"
require "kemal"
require "../funko.cr"

module Funko
  extend self

  get "/funkos/" do |env|
    funkos = Funko.from_docker
    funkos.sort! { |a, b| a.name <=> b.name }
    result = [] of Hash(String, String)

    funkos.each do |funko|
      state = ""
      case funko
      when .running?
        state = "running"
      when .paused?
        state = "paused"
      else
        state = "stopped"
      end

      result << {
        "name"   => funko.name,
        "state"  => state,
        "status" => funko.status,
      }
    end

    if env.params.query.fetch("format", "json") == "html"
      render "src/views/funkos.ecr"
    else
      result.to_json
    end
  end
end
