require "docr"
require "kemal"

module Proxy
  @@current_config = File.read("Caddyfile")

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
{
  https_port 8888
  http_port 8887
  local_certs
}

localhost:8888 {
  handle_path /admin/terminal/* {
    reverse_proxy /* http://127.0.0.1:7681
  }
  handle_path /admin/* {
    reverse_proxy /* http://127.0.0.1:3000
  }
) + funkos.map { |funko| %(
  handle_path /faaso/#{funko.split("-")[0]}/* {
    reverse_proxy /* http://#{funko}:3000
  }
) }.join("\n") + "}"

    if @@current_config != config
      File.open("Caddyfile", "w") do |file|
        file << config
      end
      # Reload config
      Process.run(command: "/usr/bin/killall", args: ["-USR1", "caddy"])
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
