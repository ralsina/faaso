require "./commands/build.cr"
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

  def self.server : String
    url = ENV.fetch("FAASO_SERVER", nil)
    if url.nil?
      Log.warn { "FAASO_SERVER not set" }
      url = "http://localhost:3000/"
    end
    url += "/" unless url.ends_with? "/"
    Log.info { "Using server #{url}" }
    url
  end

  # Compare version with server's
  def self.check_version
    server_version = Crest.get(
      "#{self.server}version/", \
         user: "admin", password: "admin").body

    local_version = "#{version}"

    if server_version != local_version
      Log.warn { "Server is version #{server_version} and client is #{local_version}" }
    end
  end
end
