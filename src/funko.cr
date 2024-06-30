require "yaml"

# A funko, built from its source metadata
class Funko
  include YAML::Serializable

  # Required, the name of the funko. Must be unique across FaaSO
  property name : String

  # if Nil, it has no template whatsoever
  property runtime : (String | Nil)? = nil

  # Port of the funko process (optional, default is 3000)
  property port : UInt32? = 3000

  # Extra packages, passed as EXTRA_PACKAGES argument
  # to the Dockerfile, use it for installing things in
  # the SHIPPED docker image
  property extra_packages : Array(String)?

  # Extra packages, passed as DEVEL_PACKAGES argument
  # to the Dockerfile, use it for installing things in
  # the docker stage used to build the code
  property devel_packages : Array(String)?

  # Where this is located in the filesystem
  @[YAML::Field(ignore: true)]
  property path : String = ""

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

  # Return a list of image IDs for this funko, most recent first
  def image_history
    docker_api = Docr::API.new(Docr::Client.new)
    begin
      docker_api.images.history(
        name: name
      ).sort { |i, j| j.@created <=> i.@created }.map(&.@id)
    rescue ex : Docr::Errors::DockerAPIError
      puts "Error: #{ex}"
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
  def create_container( autostart : Bool = true) : String
    conf = Docr::Types::CreateContainerConfig.new(
      image: "#{name}:latest",
      hostname: name,
      # Port in the container side
      # FIXME: Maybe don't need this now we are using the proxy
      exposed_ports: {"#{port}/tcp" => {} of String => String},
      host_config: Docr::Types::HostConfig.new(
        network_mode: "faaso-net",
        # Also probably not needed anymore
        port_bindings: {"#{port}/tcp" => [Docr::Types::PortBinding.new(
          host_port: "",        # Host port, empty means random
          host_ip: "127.0.0.1", # Host IP
        )]}
      )
    )

    docker_api = Docr::API.new(Docr::Client.new)
    response = docker_api.containers.create(name: "faaso-#{name}", config: conf)
    response.@warnings.each { |msg| puts "Warning: #{msg}" }
    docker_api.containers.start(response.@id) if autostart 
    response.@id
  end
end
