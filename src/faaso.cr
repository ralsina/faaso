require "commander"
require "docr"
require "docr/utils.cr"
require "file_utils"
require "uuid"

# TODO: Write documentation for `Faaso`
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
        @arguments.each do |arg|
          # A function is a folder with stuff in it
          # TODO: decide template based on file extensions or other metadata
          template = "templates/crystal"
          tmp_dir = "tmp/#{UUID.random}"
          slug = arg.gsub("/", "_").strip("_")
          repo = "localhost:5000"
          tag = "#{repo}/#{slug}:latest"
          puts "Building function... #{arg} in #{tmp_dir}"
          Dir.mkdir_p("tmp") unless File.exists? "tmp"
          FileUtils.cp_r(template, tmp_dir)
          Dir.glob(arg + "/**/*").each do |file|
            FileUtils.cp(file, tmp_dir)
          end
          docker_api = Docr::API.new(Docr::Client.new)
          docker_api.images.build(context: tmp_dir, tags: [tag, "#{slug}:latest"]) { }
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
        @arguments.each do |arg|
          slug = arg.gsub("/", "_").strip("_")
          repo = "localhost:5000"
          tag = "#{repo}/#{slug}:latest"
          docker_api = Docr::API.new(Docr::Client.new)
          # Pull image from registry
          docker_api.images.create(image: tag)
          # TODO: Start a container with the image
          containers = docker_api.containers.list(all: true)
          pp! containers
          # If it's running, do nothing
          if (containers.any? { |c|
               c.@image == tag && c.@state == "running"
             })
            puts "#{arg} is already running"
            return 0
          end

          # If it is exited, start it
          existing = containers.select { |c|
            c.@image == tag && c.@state == "exited"
          }

          puts "Starting function #{arg}"
          if (existing.size > 0)
            puts "Restarting existing exited container"
            docker_api.containers.start(existing[0].@id)
          else
            conf = Docr::Types::CreateContainerConfig.new(
              image: tag,
              hostname: "foo",
              host_config: Docr::Types::HostConfig.new
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
