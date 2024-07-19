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
  names = env.params.query["names"].split(",").map(&.strip.capitalize)
  # Connect using credentials provided

  results = [] of Array(String)
  results << ["Año"] + names
  (1922..2015).each do |anio|
    results << [anio.to_s]
  end
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres") do |cursor|
    # Get the information for each name
    names.map do |name|
      # Normalize: remove diacritics etc.
      name = name.unicode_normalize(:nfkd)
        .chars.reject! { |character|
        !character.ascii_letter? && (character != ' ')
      }.join("").downcase

      counter_per_year = {} of Int32 => Int32
      cursor.query("
      SELECT anio::integer, contador::integer
        FROM nombres WHERE nombre = $1", name) do |result_set|
        result_set.each do
          counter_per_year[result_set.read(Int32)] = result_set.read(Int32)
        end
      end
      (1922..2015).each do |anio|
        results[anio - 1921] << counter_per_year.fetch(anio, 0).to_s
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
  DB.open("postgres://#{USER}:#{PASS}@database:5432/nombres").exec("SELECT 42")
  "OK"
end
