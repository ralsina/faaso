require "docr"
require "kemal"
require "kemal-basic-auth"

# FIXME: make configurable
basic_auth "admin", "admin"

current_config = ""

get "/" do
  "Updating routing"
  # Get all the funkos, create routes for them all
  docker_api = Docr::API.new(Docr::Client.new)
  containers = docker_api.containers.list(all: true)

  funkos = [] of String
  containers.each { |container|
    names = container.names.select &.starts_with? "/faaso-"
    next if names.empty?
    funkos << names[0][7..]
  }

  funkos.sort!

  proxy_config = %(
Port 8888
Listen 0.0.0.0
Timeout 600
Allow 0.0.0.0/0
ReverseOnly Yes
ReverseMagic Yes
ReversePath "/admin/" "http://127.0.0.1:3000/"
) + funkos.map { |funko| %(ReversePath "/faaso/#{funko}/" "http://#{funko}:3000/") }.join("\n")

  if current_config != proxy_config
    File.open("tinyproxy.conf", "w") do |file|
      file << proxy_config
    end
    # Reload config
    Process.run(command: "/usr/bin/killall", args: ["-USR1", "tinyproxy"])
    current_config = proxy_config
  end
  proxy_config
end

Kemal.run
