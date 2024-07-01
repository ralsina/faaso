require "./daemon-secrets.cr"
require "compress/gzip"
require "crystar"
require "docr"
require "kemal-basic-auth"
require "kemal"
require "uuid"

# FIXME: make configurable
basic_auth "admin", "admin"

current_config = File.read("tinyproxy.conf")

# Get current proxy config
get "/proxy/" do
  current_config
end

# Bump proxy config to current docker state, returns
# new proxy config
patch "/proxy/" do
  Log.info { "Updating routing" }
  # Get all the funkos, create routes for them all
  docker_api = Docr::API.new(Docr::Client.new)
  containers = docker_api.containers.list(all: true)

  funkos = [] of String
  containers.each { |container|
    names = container.names.select &.starts_with? "/faaso-"
    next if names.empty?
    funkos << names[0][7..]
  }

  funkos.sort!

  proxy_config = %(
Port 8888
Listen 0.0.0.0
Timeout 600
Allow 0.0.0.0/0
ReverseOnly Yes
ReverseMagic Yes
ReversePath "/admin/" "http://127.0.0.1:3000/"
) + funkos.map { |funko| %(ReversePath "/faaso/#{funko}/" "http://#{funko}:3000/") }.join("\n")

  if current_config != proxy_config
    File.open("tinyproxy.conf", "w") do |file|
      file << proxy_config
    end
    # Reload config
    Process.run(command: "/usr/bin/killall", args: ["-USR1", "tinyproxy"])
    current_config = proxy_config
  end
  proxy_config
end

# Bring up the funko
get "/funko/:name/up/" do |env|
  name = env.params.url["name"]
  response = run_faaso(["up", name])

  if response["exit_code"] != 0
    halt env, status_code: 500, response: response.to_json
  else
    response.to_json
  end
end

# Build image for funko received as "funko.tgz"
# TODO: This may take a while, consider using something like
# mosquito-cr/mosquito to make it a job queue
post "/funko/build/" do |env|
  # Create place to build funko
  tmp_dir = Path.new("tmp", UUID.random.to_s)
  Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir

  # Expand tarball in there
  file = env.params.files["funko.tgz"].tempfile
  Compress::Gzip::Reader.open(file) do |gzip|
    Crystar::Reader.open(gzip) do |tar|
      tar.each_entry do |entry|
        File.open(Path.new(tmp_dir, entry.name), "w") do |dst|
          IO.copy entry.io, dst
        end
      end
    end
  end

  # Build the thing
  response = run_faaso(["build", tmp_dir.to_s])

  if response["exit_code"] != 0
    halt env, status_code: 500, response: response.to_json
  else
    response.to_json
  end
end

def run_faaso(args : Array(String))
  stderr = IO::Memory.new
  stdout = IO::Memory.new
  status = Process.run(
    command: "faaso",
    args: args + ["-l"], # Always local in the server
    output: stdout,
    error: stderr,
  )
  {
    "exit_code" => status.exit_code,
    "stdout"    => stdout.to_s,
    "stderr"    => stderr.to_s,
  }
end

Kemal.run
