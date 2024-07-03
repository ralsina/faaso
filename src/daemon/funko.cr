require "docr"
require "kemal"
require "../funko.cr"

module Funko
  extend self

  get "/funkos/:name/pause/" do |env|
    funko = Funko.from_names([env.params.url["name"]])[0]
    funko.pause
    funko.wait_for("paused", 5)
  end

  get "/funkos/:name/unpause/" do |env|
    funko = Funko.from_names([env.params.url["name"]])[0]
    funko.unpause
    funko.wait_for("running", 5)
  end

  get "/funkos/:name/start/" do |env|
    funko = Funko.from_names([env.params.url["name"]])[0]
    funko.start
    funko.wait_for("running", 5)
  end

  get "/funkos/:name/stop/" do |env|
    funko = Funko.from_names([env.params.url["name"]])[0]
    begin
      funko.stop
      funko.wait_for("exited", 5)
    rescue ex : Docr::Errors::DockerAPIError
      halt env, status_code: 500, response: "Failed to stop container"
    end
  end

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
