require "./funko.cr"
require "./proxy.cr"
require "./secrets.cr"
require "./terminal.cr"
require "compress/gzip"
require "crystar"
require "docr"
require "kemal"
require "uuid"

get "/" do |env|
  env.redirect "/index.html"
end

Kemal.run
