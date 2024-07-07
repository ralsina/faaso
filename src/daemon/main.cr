require "./config.cr"
require "./funko.cr"
require "./proxy.cr"
require "./secrets.cr"
require "./terminal.cr"
require "compress/gzip"
require "crystar"
require "docr"
require "kemal-basic-auth"
require "kemal"
require "uuid"

Config.load

basic_auth "admin", Config.instance.password

macro version
  "{{ `grep version shard.yml | cut -d: -f2` }}".strip()
end

get "/" do |env|
  env.redirect "/index.html"
end

get "/version" do
  "#{version}"
end

Kemal.run
