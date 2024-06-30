require "./funko.cr"
require "commander"
require "crest"
require "docr"
require "docr/utils.cr"
require "json"
require "uuid"

# API if you just ran faaso-daemon
FAASO_SERVER = ENV.fetch("FAASO_SERVER", "http://localhost:3000/")

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
        local = @options.@bool["local"]

        if local
          funkos.each do |funko|
            # Create temporary build location
            tmp_dir = Path.new("tmp", UUID.random.to_s)
            Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir
            funko.prepare_build tmp_dir

            Log.info { "Building function... #{funko.name} in #{tmp_dir}" }
            funko.build tmp_dir
          end
        else # Running against a server
          funkos.each do |funko|
            # Create a tarball for the funko
            buf = IO::Memory.new
            Compress::Gzip::Writer.open(buf) do |gzip|
              Crystar::Writer.open(gzip) do |tw|
                Dir.glob("#{funko.path}/**/*").each do |path|
                  next unless File.file? path
                  rel_path = Path[path].relative_to funko.path
                  file_info = File.info(path)
                  hdr = Crystar::Header.new(
                    name: rel_path.to_s,
                    mode: file_info.permissions.to_u32,
                    size: file_info.size,
                  )
                  tw.write_header(hdr)
                  tw.write(File.read(path).to_slice)
                end
              end
            end

            tmp = File.tempname
            File.open(tmp, "w") do |outf|
              outf << buf
            end

            url = "#{FAASO_SERVER}funko/build/"

            begin
              Log.info { "Uploading funko to #{FAASO_SERVER}" }
              response = Crest.post(
                url,
                {"funko.tgz" => File.open(tmp), "name" => "funko.tgz"},
                user: "admin", password: "admin"
              )
              Log.info { "Build finished successfully." }
              body = JSON.parse(response.body)
              Log.info { body["stdout"] }
            rescue ex : Crest::InternalServerError
              Log.error { "Error building funko #{funko.name} from #{funko.path}" }
              body = JSON.parse(ex.response.body)
              Log.info { body["stdout"] }
              Log.error { body["stderr"] }
              exit 1
            end
          end
        end
      end
    end

    # Bring up one or more funkos by name.
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
        funkos = Funko.from_names(@arguments)
        funkos.each do |funko|
          local = @options.@bool["local"]

          if !local
            begin
              response = Crest.get("#{FAASO_SERVER}funko/#{funko.name}/up/",
                user: "admin", password: "admin")
              body = JSON.parse(response.body)
              Log.info { body["stdout"] }
              next
            rescue ex : Crest::InternalServerError
              Log.error { "Error bringing up #{funko.name}" }
              body = JSON.parse(ex.response.body)
              Log.info { body["stdout"] }
              Log.error { body["stderr"] }
              exit 1
            end
          end

          if funko.image_history.empty?
            Log.error { "Error: no images available for #{funko.name}:latest" }
            exit 1
          end

          case funko
          when .running?
            # If it's already up, do nothing
            # FIXME: bring back out-of-date warning
            Log.info { "#{funko.name} is already up" }
          when .paused?
            # If it is paused, unpause it
            Log.info { "Resuming existing paused container" }
            funko.unpause
          when .exited?
            Log.info { "Starting function #{funko.name}" }
            Log.info { "Restarting existing exited container" }
            funko.start
          else
            # Only have an image, deploy from scratch
            Faaso.setup_network # We need it
            Log.info { "Creating and starting new container" }
            funko.create_container(autostart: true)

            (1..5).each { |_|
              break if funko.running?
              sleep 0.1.seconds
            }
            if !funko.running?
              Log.warn { "Container for #{funko.name} is not running yet" }
              next
            end
            Log.info { "Container for #{funko.name} is running" }
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
            Log.error { "#{dst_path} already exists, not exporting #{funko.path}" }
            next
          end
          Log.info { "Exporting #{funko.path} to #{dst_path}" }
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
          Log.info { "Stopping funko... #{arg}" }
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
          Log.info { "Deploying funko... #{arg}" }
          # TODO: Everything
        end
      end
    end
  end
end
