require "docr"
require "kemal"
require "../funko.cr"

module Funko
  extend self

  # Get the funko's status
  get "/funkos/:name/status/" do |env|
    name = env.params.url["name"]
    run_faaso(["status", name], env)
  end

  # Get the funko's scale
  get "/funkos/:name/scale/" do |env|
    name = env.params.url["name"]
    run_faaso(["scale", name], env)
  end

  # Set the funko's scale
  post "/funkos/:name/scale/" do |env|
    name = env.params.url["name"]
    scale = env.params.body["scale"].as(String)
    run_faaso(["scale", name, scale], env)
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
          dst = Path.new(tmp_dir, entry.name)
          Dir.mkdir_p dst.dirname
          File.open(Path.new(tmp_dir, entry.name), "w") do |outf|
            IO.copy entry.io, outf
          end
        end
      end
    end

    # Build the thing
    run_faaso(["build", tmp_dir.to_s, "--no-runtime"], env)
  end

  # Endpoints for the web frontend

  # General status for the front page
  get "/funkos/" do |env|
    funkos = Funko.from_docker
    funkos.sort! { |a, b| a.name <=> b.name }
    result = [] of Hash(String, String | Array(Docr::Types::ContainerSummary))

    funkos.each do |funko|
      result << {
        "name"         => funko.name,
        "scale"        => funko.scale.to_s,
        "containers"   => funko.containers,
        "latest_image" => funko.latest_image,
      }
    end

    if env.params.query.fetch("format", "json") == "html"
      render "src/views/funkos.ecr"
    else
      result.to_json
    end
  end
  # Stop => scale to 0
  get "/funkos/:name/stop" do |env|
    name = env.params.url["name"]
    funko = Funko.from_names([name])[0]
    funko.scale(0)
    funko.wait_for(0, 1)
  end

  # Start => scale to 1
  get "/funkos/:name/start" do |env|
    name = env.params.url["name"]
    funko = Funko.from_names([name])[0]
    if funko.scale == 0
      funko.scale(1)
      funko.wait_for(1, 1)
    end
  end

  # Restart => scale to 0, then 1
  get "/funkos/:name/restart" do |env|
    name = env.params.url["name"]
    funko = Funko.from_names([name])[0]
    funko.scale(0)
    funko.wait_for(0, 1)
    funko.scale(1)
    funko.wait_for(1, 1)
  end

  # Delete => scale to 0, remove all containers and images
  delete "/funkos/:name/" do |env|
    name = env.params.url["name"]
    funko = Funko.from_names([name])[0]
    funko.scale(0)
    funko.wait_for(0, 1)
    funko.remove_all_containers
    funko.remove_all_images
  end

  # Return an iframe that shows the container's logs
  get "/funkos/terminal/logs/:instance/" do |env|
    instance = env.params.url["instance"]
    Terminal.start_terminal(["docker", "logs", "-f", instance])
    "<iframe src='terminal/' width='100%' height='100%'></iframe>"
  end

  # Get an iframe with a shell into the container
  get "/funkos/terminal/shell/:instance/" do |env|
    instance = env.params.url["instance"]
    Terminal.start_terminal(["docker", "exec", "-ti", instance, "/bin/sh"], readonly: false)
    "<iframe src='terminal/' width='100%' height='100%'></iframe>"
  end

  # Helper to run faaso locally and respond via env
  def run_faaso(args : Array(String), env) : Bool
    Log.info { "Running faaso [#{args.join(", ")}, -l, 2>&1]" }
    Process.run(
      command: "faaso",
      args: args + ["-l", "2>&1"], # Always local in the server
      shell: true,
    ) do |process|
      loop do
        env.response.print process.output.gets(chomp: false)
        env.response.flush
        Fiber.yield
        break if process.terminated?
      end
      true
    end
    # FIXME: find a way to raise an exception on failure
    # of the faaso process
  end
end
