require "./commands/*"
require "./funko.cr"
require "crest"
require "docr"
require "docr/utils.cr"
require "json"
require "uuid"

# Functions as a Service, Ops!
module Faaso
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  module Commands
    # Base for command structs
    struct Command
    end
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

  def self.rpc_call(args : Array(String)) : Int32
    user, password = Config.auth
    Crest.post(
      "#{Config.server}rpc/",
      {"args" => args},
      user: user, password: password,
      json: true) do |response|
      IO.copy(response.body_io, STDOUT)
    end
    0
  end
end
