require "./commands/build.cr"
require "./commands/export.cr"
require "./commands/scale.cr"
require "./commands/secret.cr"
require "./commands/status.cr"
require "./funko.cr"
require "crest"
require "docr"
require "docr/utils.cr"
require "json"
require "uuid"

# API if you just ran faaso-daemon
FAASO_SERVER = ENV.fetch("FAASO_SERVER", "http://localhost:3000/")

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

  module Commands
  end
end
