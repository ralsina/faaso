require "./config.cr"
require "./funko.cr"
require "./proxy.cr"
require "./secrets.cr"
require "./terminal.cr"
require "compress/gzip"
require "crystar"
require "docr"
require "kemal"
require "uuid"

macro version
  "{{ `grep version shard.yml | cut -d: -f2` }}".strip()
end

get "/" do |env|
  env.redirect "/index.html"
end

get "/version" do
  "#{version}"
end

get "/auth" do
end

get "/reload" do
  Log.info { "Reloading configuration" }
  Config.reload
  "Config reloaded"
end

def main
  # Scale funkos to required size
  Funko::Funko.from_docker.each do |funko|
    next if funko.name == "proxy"
    scale = Config.instance.scale.fetch(funko.name, nil) || 0
    Log.info { "Scaling #{funko.name} to #{scale}" }
    funko.scale(scale)
  end
  Kemal.run
end

main
