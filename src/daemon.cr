require "docr"
require "kemal"

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

  proxy_config = %(
Port 8888
Listen 0.0.0.0
Timeout 600
Allow 0.0.0.0/0
ReverseOnly Yes
ReverseMagic Yes
ReversePath "/admin/" "http://127.0.0.1:3000/"
) + funkos.map { |funko| %(ReversePath "/faaso/#{funko}/" "http://#{funko}:3000/") }.join("\n")

  File.open("tinyproxy.conf", "w") do |file|
    file << proxy_config
  end
  proxy_config
end

Kemal.run
