require "crinja"
require "file_utils"
require "yaml"

# A funko, built from its source metadata
module Funko
  extend self

  struct Status
    property name : String = ""
    property scale : Int32 = 0
    property containers : Array(Docr::Types::ContainerSummary) = [] of Docr::Types::ContainerSummary
    property images : Array(Docr::Types::ImageSummary) = [] of Docr::Types::ImageSummary

    def initialize(name, scale, containers, images)
      @name = name
      @scale = scale
      @containers = containers
      @images = images
    end
  end

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

    # Scale: how many instances of this funko should be running
    @[YAML::Field(ignore: true)]
    property scale = 0

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

    # Get the number of running instances of this funko
    def scale
      docker_api = Docr::API.new(Docr::Client.new)
      docker_api.containers.list.select { |container|
        container.@state == "running"
      }.count { |container|
        container.@names.any?(&.starts_with?("/faaso-#{name}-"))
      }
    end

    # Set the number of running instances of this funko
    def scale(new_scale : Int)
      docker_api = Docr::API.new(Docr::Client.new)
      current_scale = self.scale
      return if current_scale == new_scale

      Log.info { "Scaling #{name} from #{current_scale} to #{new_scale}" }
      if new_scale > current_scale
        (current_scale...new_scale).each {
          Log.info { "Adding instance" }
          id = create_container
          start(id)
          sleep 0.1.seconds
        }
      else
        containers.select { |container| container.@state == "running" }.sort! { |i, j|
          i.@created <=> j.@created
        }.each { |container|
          Log.info { "Removing instance" }
          docker_api.containers.stop(container.@id)
          current_scale -= 1
          break if current_scale == new_scale
          sleep 0.1.seconds
        }
      end

      # And now, let's kill all the containers that are NOT running
      containers.select { |container| container.@state != "running" }.each { |container|
        Log.info { "Pruning dead instance" }
        docker_api.containers.delete(container.@id)
      }
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

    def images
      docker_api = Docr::API.new(Docr::Client.new)
      docker_api.images.list.select { |image|
        false if image.@repo_tags.nil?
        true if image.@repo_tags.as(Array(String)).any?(&.starts_with?("faaso-#{name}:"))
      }
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
      docker_api.containers.list(all: true).select { |container|
        container.@names.any?(&.starts_with?("/faaso-#{name}-"))
      }
    end

    # A comprehensive status for the funko:
    def docker_status
      Status.new(
        name: name,
        containers: containers,
        images: images,
        scale: scale,
      )
    end

    # Start container with given id
    def start(id : String)
      docker_api = Docr::API.new(Docr::Client.new)
      begin
        docker_api.containers.start(id)
      rescue ex : Docr::Errors::DockerAPIError
        Log.error { "#{ex}" } unless ex.status_code == 304 # This just happens
      end
    end

    # Start exited container with the newer image
    # or unpause paused container
    def start
      if self.exited?
        docker_api = Docr::API.new(Docr::Client.new)
        images = self.image_history
        exited = self.containers.select { |container|
          container.@state == "exited"
        }.sort! { |i, j|
          (images.index(j.@image_id) || 9999) <=> (images.index(i.@image_id) || 9999)
        }
        docker_api.containers.restart(exited[0].@id) unless exited.empty?
      elsif self.paused?
        self.unpause
      end
    end

    # Stop container with the newer image
    def stop
      docker_api = Docr::API.new(Docr::Client.new)
      images = self.image_history
      containers = self.containers.sort! { |i, j|
        (images.index(j.@image_id) || 9999) <=> (images.index(i.@image_id) || 9999)
      }
      return docker_api.containers.stop(containers[0].@id) unless containers.empty?
      nil
    end

    # Wait up to `t` seconds for the funko to reach the requested `state`
    def wait_for(new_scale : Int, t)
      channel = Channel(Nil).new
      spawn do
        loop do
          channel.send(nil) if scale == new_scale
          sleep 0.2.seconds
        end
      end

      select
      when channel.receive
        Log.info { "Funko #{name} reached scale #{new_scale}" }
      when timeout(t.seconds)
        Log.error { "Funko #{name} did not reach scale #{new_scale} in #{t} seconds" }
      end
    end

    # Create a container for this funko
    def create_container(autostart : Bool = true) : String
      secrets_mount = "#{Dir.current}/secrets/#{name}"
      Dir.mkdir_p(secrets_mount)
      conf = Docr::Types::CreateContainerConfig.new(
        image: "faaso-#{name}:latest",
        hostname: "#{name}",
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
      response = docker_api.containers.create(name: "faaso-#{name}-#{randstr}", config: conf)
      response.@warnings.each { |msg| Log.warn { msg } }
      docker_api.containers.start(response.@id) if autostart
      response.@id
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
      names = [] of String

      # Get all containers that look like funkos
      docker_api.containers.list(
        all: true,
      ).each { |container|
        container.@names.each { |name|
          names << name.split("-", 3)[1].lstrip("/") if name.starts_with?("/faaso-")
        }
      }

      # Now get all images that look like funkos, since
      # we can start them just fine.
      docker_api.images.list.each { |image|
        next if image.@repo_tags.nil?
        image.@repo_tags.as(Array(String)).each { |tag|
          names << tag.split("-", 2)[1].split(":", 2)[0] if tag.starts_with?("faaso-")
        }
      }
      from_names(names.to_set.to_a.sort!)
    end
  end
end

def randstr(length = 6) : String
  chars = "abcdefghijklmnopqrstuvwxyz0123456789"
  String.new(Bytes.new(chars.to_slice.sample(length).to_unsafe, length))
end
