require "kemal"
require "./funko.cr"

get "/ping/" do
  "OK"
end

Kemal.run
