require "./funko.cr"
require "commander"
require "docr"
require "docr/utils.cr"
require "file_utils"
require "uuid"

# Functions as a Service, Ops!
module Faaso
  VERSION = "0.1.0"

  # Ensure the faaso-net network exists
  def self.setup_network
    docker_api = Docr::API.new(Docr::Client.new)
    docker_api.networks.create(Docr::Types::NetworkConfig.new(
      name: "faaso-net",
      check_duplicate: false,
      driver: "bridge"
    ))
  rescue ex : Docr::Errors::DockerAPIError
    raise ex if ex.status_code != 409 # Network already exists

  end

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

          docker_api = Docr::API.new(Docr::Client.new)
          docker_api.images.build(
            context: tmp_dir.to_s,
            tags: ["#{funko.name}:latest"]) { }
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
          container_name = "faaso-#{funko.name}"
          docker_api = Docr::API.new(Docr::Client.new)

          if funko.image_history.empty?
            puts "Error: no images available for #{funko.name}:latest"
            next
          end

          case funko
          when .running?
            # If it's already up, do nothing
            # FIXME: bring back out-of-date warning
            puts "#{funko.name} is already up"
          when .paused?
            # If it is paused, unpause it
            puts "Resuming existing paused container"
            funko.unpause
          when .exited?
            puts "Starting function #{funko.name}"
            puts "Restarting existing exited container"
            funko.start
          else
            # FIXME: move into Funko class
            # Deploy from scratch
            Faaso.setup_network # We need it
            puts "Creating new container"
            conf = Docr::Types::CreateContainerConfig.new(
              image: "#{funko.name}:latest",
              hostname: funko.name,
              # Port in the container side
              exposed_ports: {"#{funko.port}/tcp" => {} of String => String},
              host_config: Docr::Types::HostConfig.new(
                network_mode: "faaso-net",
                port_bindings: {"#{funko.port}/tcp" => [Docr::Types::PortBinding.new(
                  host_port: "",        # Host port, empty means random
                  host_ip: "127.0.0.1", # Host IP
                )]}
              )
            )

            response = docker_api.containers.create(name: container_name, config: conf)
            response.@warnings.each { |msg| puts "Warning: #{msg}" }
            docker_api.containers.start(response.@id)
            containers = docker_api.containers.list(
              all: true,
              filters: {"name" => [container_name]}
            )

            (1..5).each { |_|
              break if containers[0].state == "running"
              sleep 0.1.seconds
            }
            if containers[0].state != "running"
              puts "Container for #{funko.name} is not running yet"
              next
            end
            puts "Container for #{funko.name} is running"
          end
        end
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

    class Deploy
      @arguments : Array(String) = [] of String
      @options : Commander::Options

      def initialize(options, arguments)
        @options = options
        @arguments = arguments
      end

      def run
        @arguments.each do |arg|
          puts "Stopping function... #{arg}"
          # TODO: Everything
        end
      end
    end
  end
end
