require "commander"
require "docr"
require "docr/utils.cr"
require "file_utils"
require "uuid"
require "./funko.cr"

# FIXME make it configurable
REPO = "localhost:5000"

# Functions as a Service, Ops!
module Faaso
  VERSION = "0.1.0"

  module Commands
    class Build
      @arguments : Array(String) = [] of String
      @options : Commander::Options

      def initialize(options, arguments)
        @options = options
        @arguments = arguments
      end

      def run
        funkos = Funko.from_paths(@arguments)
        funkos.each do |funko|
          # Create temporary build location
          tmp_dir = Path.new("tmp", UUID.random.to_s)
          Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir

          # Copy runtime if requested
          if !funko.runtime.nil?
            runtime_dir = Path.new("runtimes", funko.runtime.to_s)
            if !File.exists? runtime_dir
              puts "Error: runtime #{funko.runtime} not found"
              next
            end
            Dir.glob("#{runtime_dir}/*").each { |src|
              FileUtils.cp_r(src, tmp_dir)
            }
          end

          # Copy funko
          if funko.path.empty?
            puts "Internal error: empty funko path for #{funko.name}"
            next
          end
          Dir.glob("#{funko.path}/*").each { |src|
            FileUtils.cp_r(src, tmp_dir)
          }

          puts "Building function... #{funko.name} in #{tmp_dir}"

          slug = funko.name

          # FIXME: this should be configurable
          repo = REPO
          tag = "#{repo}/#{funko.name}:latest"

          docker_api = Docr::API.new(Docr::Client.new)
          docker_api.images.build(
            context: tmp_dir.to_s,
            tags: [tag, "#{funko.name}:latest"]) { }

          puts "Pushing to repo as #{tag}"
          docker_api.images.tag(repo: repo, name: slug, tag: "latest")
          # FIXME: pushing is broken because my test registry has no auth
          # docker_api.images.push(name: slug, tag: "latest", auth: "")
        end
      end
    end

    class Up
      @arguments : Array(String) = [] of String
      @options : Commander::Options

      def initialize(options, arguments)
        @options = options
        @arguments = arguments
      end

      def run
        funkos = Funko.from_paths(@arguments)
        funkos.each do |funko|
          repo = REPO
          tag = "#{repo}/#{funko.name}:latest"
          docker_api = Docr::API.new(Docr::Client.new)
          # Pull image from registry
          docker_api.images.create(image: tag)

          containers = docker_api.containers.list(all: true)
          # If it's running, do nothing
          if containers.any? { |container|
               container.@image == tag && container.@state == "running"
             }
            puts "#{funko.name} is already running"
            next
          end

          # If it is paused, unpause it
          paused = containers.select { |container|
            container.@image == tag && container.@state == "paused"
          }
          if paused.size > 0
            puts "Resuming existing paused container"
            docker_api.containers.unpause(paused[0].@id)
            next
          end

          # If it is exited, start it
          existing = containers.select { |container|
            container.@image == tag && container.@state == "exited"
          }

          puts "Starting function #{funko.name}"
          if existing.size > 0
            puts "Restarting existing exited container"
            docker_api.containers.start(existing[0].@id)
            next
          end

          # Creating from scratch
          puts "Creating new container"
          conf = Docr::Types::CreateContainerConfig.new(
            image: tag,
            hostname: funko.name,
            # Port in the container side
            exposed_ports: {"#{funko.port}/tcp" => {} of String => String},
            host_config: Docr::Types::HostConfig.new(
              port_bindings: {"#{funko.port}/tcp" => [Docr::Types::PortBinding.new(
                host_port: "",        # Host port, empty means random
                host_ip: "127.0.0.1", # Host IP
              )]}
            )
          )

          # FIXME: name should be unique
          response = docker_api.containers.create(name: "fungus", config: conf)
          docker_api.containers.start(response.@id)
        end
        # TODO: Run test for healthcheck
        # TODO: Map route in reverse proxy to function
        # TODO: Return function URL for testing
      end
    end

    class Down
      @arguments : Array(String) = [] of String
      @options : Commander::Options

      def initialize(options, arguments)
        @options = options
        @arguments = arguments
      end

      def run
        @arguments.each do |arg|
          puts "Stopping function... #{arg}"
          # TODO: check if function is running
          # TODO: stop function container
          # TODO: delete function container
          # TODO: remove route from reverse proxy
        end
      end
    end
  end
end
