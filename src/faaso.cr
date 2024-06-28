require "commander"

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
          puts "Building function... #{arg}"
          # A function is a folder with stuff in it
          # TODO: decide template based on file extensions or other metadata
          # TODO: copy template and add function files to it
          # TODO: build Docker image
          # TODO: push Docker image to registry
          # TODO: return image name for testing
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
          puts "Starting function... #{arg}"
          # TODO: Check that we have an image for the function
          # TODO: Start a container with the image
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
