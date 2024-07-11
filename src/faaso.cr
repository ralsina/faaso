require "./commands/build.cr"
require "./commands/deploy.cr"
require "./commands/export.cr"
require "./commands/login.cr"
require "./commands/new.cr"
require "./commands/scale.cr"
require "./commands/secret.cr"
require "./commands/status.cr"
require "./funko.cr"
require "crest"
require "docr"
require "docr/utils.cr"
require "json"
require "uuid"

# Functions as a Service, Ops!
module Faaso
  VERSION = "0.1.0"

  # Ensure the faaso-net network exists
  def self.setup_network
    docker_api = Docr::API.new(Docr::Client.new)
    docker_api.networks.create(Docr::Types::NetworkConfig.new(
      name: "faaso-net",
      check_duplicate: false,
      driver: "bridge"
    ))
  rescue ex : Docr::Errors::DockerAPIError
    raise ex if ex.status_code != 409 # Network already exists
  end

  # Compare version with server's
  def self.check_version
    user, password = Config.auth
    server_version = Crest.get(
      "#{Config.server}version/", \
         user: user, password: password).body

    local_version = "#{version}"

    if server_version != local_version
      Log.warn { "Server is version #{server_version} and client is #{local_version}" }
    end
  end

  def self.rpc_call(args : Array(String))
    user, password = Config.auth
    Crest.post(
      "#{Config.server}rpc/",
      {"args" => args},
      user: user, password: password,
      json: true) do |response|
      IO.copy(response.body_io, STDOUT)
    end
  end
end
