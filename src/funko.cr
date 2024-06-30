require "yaml"

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

  # Is this funko running?
  def running?
    self.containers.any? { |container|
      container.@state == "running"
    }
  end
end
