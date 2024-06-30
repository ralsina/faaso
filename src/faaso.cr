require "./funko.cr"
require "commander"
require "docr"
require "docr/utils.cr"
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
    # Build images for one or more funkos
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
          funko.prepare_build tmp_dir

          puts "Building function... #{funko.name} in #{tmp_dir}"
          funko.build tmp_dir
        end
      end
    end

    # Bring up one or more funkos.
    #
    # This doesn't guarantee that they will be running the latest
    # version, and it will try to recicle paused and exited containers.
    #
    # If there is no other way, it will create a brand new container with
    # the latest known image and start it.
    #
    # If there are no images for the funko, it will fail to bring it up.
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
            # Only have an image, deploy from scratch
            Faaso.setup_network # We need it
            puts "Creating and starting new container"
            funko.create_container(autostart: true)

            (1..5).each { |_|
              break if funko.running?
              sleep 0.1.seconds
            }
            if !funko.running?
              puts "Container for #{funko.name} is not running yet"
              next
            end
            puts "Container for #{funko.name} is running"
          end
        end
      end
    end

    class Export
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
          dst_path = Path.new("export", funko.name)
          if File.exists? dst_path
            puts "Error: #{dst_path} already exists, not exporting #{funko.path}"
            next
          end
          puts "Exporting #{funko.path} to #{dst_path}"
          Dir.mkdir_p(dst_path)
          funko.prepare_build dst_path
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
          puts "Stopping funko... #{arg}"
          # TODO: check if funko is running
          # TODO: stop funko container
          # TODO: delete funko container
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
          puts "Deploying funko... #{arg}"
          # TODO: Everything
        end
      end
    end
  end
end
