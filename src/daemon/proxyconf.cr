require "docr"
require "funko"
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
    config = <<-CONFIG
{
  http_port 8888
  https_port 8887
  local_certs
  admin off
}

http://localhost:8888 {
  handle_path /admin/terminal/* {
    reverse_proxy /* http://127.0.0.1:7681
  }
  handle_path /admin/* {
    reverse_proxy /* http://127.0.0.1:3000
  }


CONFIG

    funkos = Funko::Funko.from_docker
    funkos.each do |funko|
      next if funko.name == "proxy"
      containers = funko.containers
      next if containers.empty?
      funko_urls = containers.map { |container|
        "http://#{container.names[0].lstrip("/")}:3000"
      }
      config += %(
      handle_path /faaso/#{funko.name}/* {
        reverse_proxy /* #{funko_urls.join(" ")} {
          health_uri /ping
          fail_duration 30s
        }
      }
      )
    end
    config += "\n}"

    if @@current_config != config
      Log.info { "Updating proxy config" }
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
