require "kemal"

module Proxy
  @@current_config = File.read("tinyproxy.conf")

  # Get current proxy config
  get "/proxy/" do
    @@current_config
  end

  # Bump proxy config to current docker state, returns
  # new proxy config
  patch "/proxy/" do
    Log.info { "Updating routing" }
    # Get all the funkos, create routes for them all
    update_proxy_config
  end

  def self.update_proxy_config
    docker_api = Docr::API.new(Docr::Client.new)
    containers = docker_api.containers.list(all: true)

    funkos = [] of String
    containers.each { |container|
      names = container.names.select &.starts_with? "/faaso-"
      next if names.empty?
      funkos << names[0][7..]
    }
    funkos.sort!

    config = %(
  Port 8888
  Listen 0.0.0.0
  Timeout 600
  Allow 0.0.0.0/0
  ReverseOnly Yes
  ReverseMagic Yes
  ReversePath "/admin/" "http://127.0.0.1:3000/"
  ) + funkos.map { |funko| %(ReversePath "/faaso/#{funko}/" "http://#{funko}:3000/") }.join("\n")

    if @@current_config != config
      File.open("tinyproxy.conf", "w") do |file|
        file << config
      end
      # Reload config
      Process.run(command: "/usr/bin/killall", args: ["-USR1", "tinyproxy"])
      @@current_config = config
    end
    config
  end
end

# Update proxy config once a second
spawn do
  loop do
    Proxy.update_proxy_config
    sleep 1.second
  end
end
