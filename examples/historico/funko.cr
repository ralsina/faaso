require "json"
require "kemal"
require "pg"

# get credentials from secrets

USER = File.read("/secrets/user").strip
PASS = File.read("/secrets/pass").strip

# Connect to the database and get information about
# the requested names
get "/" do |env|
  # Names are query parameters
  names = env.params.query["names"].split(",")
  # Connect using credentials provided

  results = {} of String => Array({Int32, Int32})
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres") do |cursor|
    # Get the information for each name
    names.map do |name|
      results[name] = Array({Int32, Int32}).new
      cursor.query("
      SELECT anio::integer, contador::integer
        FROM nombres WHERE nombre = $1
      ORDER BY anio", name) do |result_set|
        result_set.each do
          anio, contador = {result_set.read(Int32), result_set.read(Int32)}
          results[name] << {anio, contador}
        end
      end
    end
  end
  results.to_json
end

# The `/ping/` endpoint is configured in the container as a healthcheck
# You can make it better by checking that your database is responding
# or whatever checks you think are important
#
get "/ping/" do
  "OK"
end
