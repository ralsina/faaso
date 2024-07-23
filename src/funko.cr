require "./runtime.cr"
require "crinja"
require "file_utils"
require "uname"
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

    property options : Hash(String, String | Array(String)) = {} of String => String | Array(String)

    # Where this is located in the filesystem
    @[YAML::Field(ignore: true)]
    property path : String = ""

    # Scale: how many instances of this funko should be running
    @[YAML::Field(ignore: true)]
    property scale = 0

    private def to_context
      {
        "name"    => name,
        "runtime" => runtime,
        "options" => options,
      }
    end

    def after_initialize
      raise Exception.new("Invalid funko name: #{name}") unless valid?
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
      containers.size
    end

    # Set the number of running instances of this funko
    # Returns the list of IDs started or stopped
    def scale(new_scale : Int) : Array(String)
      docker_api = Docr::API.new(Docr::Client.new)
      current_scale = self.scale
      result = [] of String

      if current_scale == new_scale
        Log.info { "Funko #{name} already at scale #{new_scale}" }
        return result
      end

      Log.info { "Scaling #{name} from #{current_scale} to #{new_scale}" }
      if new_scale > current_scale
        (current_scale...new_scale).each {
          Log.info { "Adding instance" }
          result << (id = create_container)
          Log.debug { "Started container #{id}" }
          start(id)
          sleep 0.1.seconds
        }
      else
        # Sort them older to newer, so we stop the oldest
        containers.sort! { |i, j|
          i.@created <=> j.@created
        }.each { |container|
          Log.info { "Removing instance" }
          docker_api.containers.stop(container.@id)
          result << container.@id
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

      result
    end

    # Setup the target directory `path` with all the files needed
    # to build a docker image
    def prepare_build(path : Path)
      # Copy runtime if requested
      if !runtime.nil?
        # Get runtime files list
        runtime_base, runtime_files = Runtime.runtime_files(runtime.as(String))

        Runtime.copy_templated(
          runtime_base,
          runtime_files,
          path.to_s,
          to_context
        )
      end

      # Copy funko on top of runtime
      raise Exception.new("Internal error: empty funko path for #{name}") if self.path.empty?
      Dir.glob("#{self.path}/*").each { |src|
        Log.debug { "Copying #{src} to #{path}" }
        FileUtils.cp_r(src, path)
      }
    end

    # Build image using docker in path previously prepared using `prepare_build`
    def build(path : Path, no_cache : Bool = false)
      Log.info { "Building image for #{name} in #{path}" }
      docker_api = Docr::API.new(Docr::Client.new)
      tags = ["faaso-#{name}:latest", "faaso-#{name}:#{Time.utc.to_unix}"]
      Log.info { "   Tags: #{tags}" }
      docker_api.images.build(
        context: path.to_s,
        build_args: {"BUILDPLATFORM" => System.machine},
        tags: tags,
        version: "1",
        pull: false,
        platform: System.machine,
        no_cache: no_cache) { |x| Log.info { x } }
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

    def latest_image
      return image_history.first unless image_history.empty?
      "Unknown"
    end

    # Get all containers related to this funko in the desired state
    def containers(status : String | Nil = "running")
      docker_api = Docr::API.new(Docr::Client.new)
      containers = docker_api.containers.list(all: true).select { |container|
        container.@names.any?(&.starts_with?("/faaso-#{name}-"))
      } || [] of Docr::Types::ContainerSummary

      if status
        containers = containers.select { |container|
          container.@state == status
        }
      end
      containers
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

    def wait_for_container_started(id : String, t : Int)
      docker_api = Docr::API.new(Docr::Client.new)
      channel = Channel(Nil).new
      spawn do
        loop do
          begin
            details = docker_api.containers.inspect(id)
            channel.send(nil) if details.state.as(Docr::Types::ContainerState).status == "running"
          rescue ex : Docr::Errors::DockerAPIError
            Log.error { "#{ex}" } unless ex.status_code == 304 # This just happens
          end
          sleep 1.seconds
        end
      end

      select
      when channel.receive
        Log.info { "Container #{id[..8]} is running" }
      when timeout(t.seconds)
        raise Exception.new("Container #{id[..8]} did not start in #{t} seconds")
      end
    end

    # Wait up to `t` seconds for the funko to reach the desired scale
    # If `healthy` is true, it will wait for the container to be declared
    # healthy by the healthcheck
    def wait_for(new_scale : Int, t : Int, healthy : Bool = false)
      docker_api = Docr::API.new(Docr::Client.new)
      channel = Channel(Nil).new
      spawn do
        loop do
          if healthy
            healthy_count = containers.count { |container|
              begin
                details = docker_api.containers.inspect(container.@id)
                details.state.try &.as(Docr::Types::ContainerState).health.try &.as(Docr::Types::Health).status == "healthy"
              rescue ex : Docr::Errors::DockerAPIError
                Log.error { "#{ex}" } unless ex.status_code == 304 # This just happens
                false
              end
            }
            Log.info { "Funko #{name} has #{healthy_count}/#{new_scale} healthy containers" }
            channel.send(nil) if healthy_count == new_scale
          else
            Log.info { "Funko #{name} has #{scale}/#{new_scale} running containers" }
            channel.send(nil) if scale == new_scale
          end
          sleep 1.seconds
        end
      end

      select
      when channel.receive
        Log.info { "Funko #{name} reached scale #{new_scale}" }
      when timeout(t.seconds)
        raise Exception.new("Funko #{name} did not reach scale #{new_scale} in #{t} seconds")
      end
    end

    # Remove all containers related to this funko
    def remove_all_containers
      docker_api = Docr::API.new(Docr::Client.new)
      docker_api.containers.list(all: true).select { |container|
        container.@names.any?(&.starts_with?("/faaso-#{name}-"))
      }.each { |container|
        begin
          docker_api.containers.stop(container.@id) if container.status != "exited"
        rescue ex : Docr::Errors::DockerAPIError
          Log.error { "#{ex}" } unless ex.status_code == 304 # This just happens
        end
        docker_api.containers.delete(container.@id)
      }
    end

    # Remove all images related to this funko
    def remove_all_images
      docker_api = Docr::API.new(Docr::Client.new)
      docker_api.images.list.select { |image|
        return false if image.@repo_tags.nil?
        true if image.@repo_tags.as(Array(String)).any?(&.starts_with?("faaso-#{name}:"))
      }.each { |image|
        Log.debug { "Removing image #{image.@id}" }
        (image.@repo_tags || [] of String).each { |tag|
          Log.debug { "  #{tag}" }
          docker_api.images.delete(tag)
        }
      }
    end

    # Create a container for this funko
    def create_container : String
      # The path to secrets is tricky. On the server it will be in
      # ./secrets/ BUT when you call on the Docker API you need to
      # pass the path in the HOST SYSTEM WHERE DOCKER IS RUNNING
      # so allow for a FAASO_SECRET_PATH override which will
      # be set for the proxy container
      secrets_src = Path[ENV.fetch(
        "FAASO_SECRET_PATH",
        "#{Dir.current}/secrets/"
      ), name].to_s
      secrets_dst = "/secrets"
      secrets_local = Path["secrets/", name].to_s
      Dir.mkdir_p(secrets_local)
      conf = Docr::Types::CreateContainerConfig.new(
        image: "faaso-#{name}:latest",
        hostname: "#{name}",
        # Port in the container side
        host_config: Docr::Types::HostConfig.new(
          network_mode: "faaso-net",
          auto_remove: true,
          mounts: [
            Docr::Types::Mount.new(
              source: secrets_src,
              target: secrets_dst,
              type: "bind"
            ),
          ]
        )
      )

      docker_api = Docr::API.new(Docr::Client.new)
      response = docker_api.containers.create(name: "faaso-#{name}-#{Random.base58(6)}", config: conf)
      response.@warnings.each { |msg| Log.warn { msg } }
      docker_api.containers.start(response.@id)
      wait_for_container_started(response.@id, 10)
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

    def valid? : Bool
      (name =~ /^[A-Za-z0-9]+$/) == 0
    end
  end
end
