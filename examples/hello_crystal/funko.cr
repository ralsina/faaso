require "kemal"
 
# This is a kemal app, you can add handlers, middleware, etc.
 
# A basic hello world get endpoint
get "/" do
  "Hello World Crystal!"
end

# The `/ping/` endpoint is configured in the container as a healthcheck
# You can make it better by checking that your database is responding
# or whatever checks you think are important
# 
get "/ping/" do
  "OK"
end
