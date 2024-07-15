require "json"
require "kemal"
require "pg"

# get credentials from secrets

USER = "postgres"  #File.read("/secrets/user").strip
PASS = "postgres" #File.read("/secrets/pass").strip

# Connect to the database and get information about
# the requested names
get "/" do |env|
  # Names are query parameters
  names = env.params.query["names"].split(",")
  # Connect using credentials provided

  results = [] of Array(String)
  results << ["Año"] + names
  (1922..2016).each do |anio|
    results << [anio.to_s]
  end
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres") do |cursor|
    # Get the information for each name
    names.map do |name|
      cursor.query("
      SELECT anio::integer, contador::integer
        FROM nombres WHERE nombre = $1
      ORDER BY anio", name) do |result_set|
        result_set.each do
          anio, contador = {result_set.read(Int32), result_set.read(Int32)}
          results[anio - 1921] << contador.to_s
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
