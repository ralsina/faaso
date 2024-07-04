require "./funko.cr"
require "./proxyconf.cr"
require "./secrets.cr"
require "compress/gzip"
require "crystar"
require "docr"
require "kemal-basic-auth"
require "kemal"
require "uuid"

# FIXME: make configurable
basic_auth "admin", "admin"

get "/" do |env|
  env.redirect "index.html"
end

Kemal.run
