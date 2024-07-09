require "./funko.cr"
require "docr"
require "kemal"

module Proxy
  CADDY_CONFIG_PATH = "config/Caddyfile"
  CADDY_CONFIG_FUNKOS = "config/funkos"
  @@current_config = File.read(CADDY_CONFIG_FUNKOS)

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

  def self.update_proxy_config : Nil
    docker_api = Docr::API.new(Docr::Client.new)
    containers = docker_api.containers.list(all: true)

    config = ""
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

    if @@current_config != config
      Log.info { "Updating proxy config" }
      File.open(CADDY_CONFIG_FUNKOS, "w") do |file|
        file << config
      end
      # Reload config
      @@current_config = config
      Process.run(command: "caddy", args: ["reload", "--config", CADDY_CONFIG_PATH])
    end
  end
end

# Update proxy config every 1 second (if changed)
spawn do
  loop do
    Proxy.update_proxy_config
    sleep 1.second
  end
end
