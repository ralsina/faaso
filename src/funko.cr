require "crinja"
require "file_utils"
require "yaml"

# A funko, built from its source metadata
class Funko
  include YAML::Serializable

  # Required, the name of the funko. Must be unique across FaaSO
  property name : String

  # if Nil, it has no template whatsoever
  property runtime : (String | Nil)? = nil

  # Extra operating system packages shipped with the runtime's Docker image
  property ship_packages : Array(String) = [] of String

  # Extra operating system packages used only when *building* the funko
  property devel_packages : Array(String) = [] of String

  # Where this is located in the filesystem
  @[YAML::Field(ignore: true)]
  property path : String = ""

  # Healthcheck properties
  property healthcheck_options : String = "--interval=1m --timeout=2s --start-period=2s --retries=3"
  property healthcheck_command : String = "curl --fail http://localhost:3000/ping || exit 1"

  def _to_context
    {
      "name"                => name,
      "ship_packages"       => ship_packages,
      "devel_packages"      => devel_packages,
      "healthcheck_options" => healthcheck_options,
      "healthcheck_command" => healthcheck_command,
    }
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field("name", name)
      json.field("ship_packages", ship_packages)
      json.field("devel_packages", devel_packages)
      json.field("healthcheck_options", healthcheck_options)
      json.field("healthcheck_command", healthcheck_command)
    end
  end

  # Create an Array of funkos from an Array of folders containing definitions
  def self.from_paths(paths : Array(String | Path)) : Array(Funko)
    paths.map { |path| Path.new(path, "funko.yml") }
      .select { |path| File.exists?(path) }
      .map { |path|
        f = Funko.from_yaml(File.read(path.to_s))
        f.path = path.parent.to_s
        f
      }
  end

  # Create an array of funkos just from names. These are limited in function
  # and can't call `prepare_build` or some other functionality
  def self.from_names(names : Array(String)) : Array(Funko)
    names.map { |name|
      Funko.from_yaml("name: #{name}")
    }
  end

  # Get all the funkos docker knows about.
  def self.from_docker : Array(Funko)
    docker_api = Docr::API.new(Docr::Client.new)
    names = Set(String).new
    docker_api.images.list(all: true).select { |i|
      next if i.@repo_tags.nil? 
      i.@repo_tags.as(Array(String)).each { |tag|
        names << tag.split(":", 2)[0].split("-", 2)[1] if tag.starts_with?("faaso-")
      }
    }
    pp! names
    from_names(names.to_a)
  end

  # Setup the target directory `path` with all the files needed
  # to build a docker image
  def prepare_build(path : Path)
    # Copy runtime if requested
    if !runtime.nil?
      runtime_dir = Path.new("runtimes", runtime.as(String))
      raise Exception.new("Error: runtime #{runtime} not found for funko #{name} in #{path}") unless File.exists?(runtime_dir)
      Dir.glob("#{runtime_dir}/*").each { |src|
        FileUtils.cp_r(src, path)
      }
      # Replace templates with processed files
      context = _to_context
      Dir.glob("#{path}/**/*.j2").each { |template|
        dst = template[..-4]
        File.open(dst, "w") do |file|
          file << Crinja.render(File.read(template), context)
        end
        File.delete template
      }
    end

    # Copy funko
    raise Exception.new("Internal error: empty funko path for #{name}") if self.path.empty?
    Dir.glob("#{self.path}/*").each { |src|
      FileUtils.cp_r(src, path)
    }
  end

  # Build image using docker in path previously prepared using `prepare_build`
  def build(path : Path)
    docker_api = Docr::API.new(Docr::Client.new)
    docker_api.images.build(
      context: path.to_s,
      tags: ["faaso-#{name}:latest"]) { |x| Log.info { x } }
  end

  # Return a list of image IDs for this funko, most recent first
  def image_history
    docker_api = Docr::API.new(Docr::Client.new)
    begin
      docker_api.images.history(
        name: "faaso-#{name}"
      ).sort { |i, j| j.@created <=> i.@created }.map(&.@id)
    rescue ex : Docr::Errors::DockerAPIError
      Log.error { "#{ex}" }
      [] of String
    end
  end

  # Get all containers related to this funko
  def containers
    docker_api = Docr::API.new(Docr::Client.new)
    docker_api.containers.list(
      all: true,
      filters: {"name" => ["faaso-#{name}"]}
    )
  end

  # Is any instance of this funko running?
  def running?
    self.containers.any? { |container|
      container.@state == "running"
    }
  end

  # Is any instance of this funko paused?
  def paused?
    self.containers.any? { |container|
      container.@state == "paused"
    }
  end

  # Unpause paused container with the newer image
  def unpause
    docker_api = Docr::API.new(Docr::Client.new)
    images = self.image_history
    paused = self.containers.select { |container|
      container.@state == "paused"
    }.sort! { |i, j|
      (images.index(j.@image_id) || 9999) <=> (images.index(i.@image_id) || 9999)
    }
    docker_api.containers.unpause(paused[0].@id) unless paused.empty?
  end

  # Is any instance of this funko exited?
  def exited?
    self.containers.any? { |container|
      container.@state == "exited"
    }
  end

  # Restart exited container with the newer image
  def start
    # FIXME refactor DRY with unpause
    docker_api = Docr::API.new(Docr::Client.new)
    images = self.image_history
    exited = self.containers.select { |container|
      container.@state == "exited"
    }.sort! { |i, j|
      (images.index(j.@image_id) || 9999) <=> (images.index(i.@image_id) || 9999)
    }
    docker_api.containers.restart(exited[0].@id) unless exited.empty?
  end

  # Create a container for this funko
  def create_container(autostart : Bool = true) : String
    secrets_mount = "#{Dir.current}/secrets/#{name}"
    Dir.mkdir_p(secrets_mount)
    conf = Docr::Types::CreateContainerConfig.new(
      image: "faaso-#{name}:latest",
      hostname: name,
      # Port in the container side
      host_config: Docr::Types::HostConfig.new(
        network_mode: "faaso-net",
        mounts: [
          Docr::Types::Mount.new(
            source: secrets_mount,
            target: "/secrets",
            type: "bind"
          ),
        ]
      )
    )

    docker_api = Docr::API.new(Docr::Client.new)
    response = docker_api.containers.create(name: "faaso-#{name}", config: conf)
    response.@warnings.each { |msg| Log.warn { msg } }
    docker_api.containers.start(response.@id) if autostart
    response.@id
  end
end
