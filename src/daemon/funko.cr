require "docr"
require "kemal"
require "../funko.cr"

module Funko
  extend self

  # Get the funko's status
  get "/funkos/:name/status/" do |env|
    name = env.params.url["name"]
    response = run_faaso(["status", name])

    if response["exit_code"] != 0
      halt env, status_code: 500, response: response.to_json
    else
      response.to_json
    end
  end

  # Get the funko's scale
  get "/funkos/:name/scale/" do |env|
    name = env.params.url["name"]
    response = run_faaso(["scale", name])

    if response["exit_code"] != 0
      halt env, status_code: 500, response: response.to_json
    else
      response.to_json
    end
  end

  # Set the funko's scale
  post "/funkos/:name/scale/" do |env|
    name = env.params.url["name"]
    scale = env.params.body["scale"].as(String)
    response = run_faaso(["scale", name, scale])
    if response["exit_code"] != 0
      Log.error { response }
      halt env, status_code: 500, response: response.to_json
    else
      Log.info { response }
      response.to_json
    end
  end

  # Build image for funko received as "funko.tgz"
  # TODO: This may take a while, consider using something like
  # mosquito-cr/mosquito to make it a job queue
  post "/funkos/build/" do |env|
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

  get "/funkos/" do |env|
    funkos = Funko.from_docker
    funkos.sort! { |a, b| a.name <=> b.name }
    result = [] of Hash(String, String)

    funkos.each do |funko|
      result << {
        "name"       => funko.name,
        "scale"      => funko.scale.to_s,
        "containers" => funko.containers.size.to_s,
        "images"     => funko.images.size.to_s,
      }
    end

    if env.params.query.fetch("format", "json") == "html"
      render "src/views/funkos.ecr"
    else
      result.to_json
    end
  end

  def run_faaso(args : Array(String))
    Log.info { "Running faaso [#{args.join(", ")}, -l]" }
    output = IO::Memory.new
    status = Process.run(
      command: "faaso",
      args: args + ["-l"], # Always local in the server
      output: output,
      error: output,
    )
    result = {
      "exit_code" => status.exit_code,
      "output"    => output.to_s,
    }
    result
  end
end
