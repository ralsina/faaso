module Faaso
  module Commands
    struct Export < Command
      @@name = "export"
      @@doc : String = <<-DOC
      Export a funko as a ready-to-build dockerized app.

      Takes a funko definition and exports it to a destination folder.
      As part of the export process, all information from the funko's
      runtime is merged into the funko.

      The result is a folder that can be used to build a docker image
      without requiring any part of FaaSO.

      Usage:
        faaso export SOURCE DESTINATION   [-v <level>]

      Options:
        -h --help        Show this screen
        -v level         Control the logging verbosity, 0 to 6 [default: 4]
      DOC

      def run : Int32
        source = options["SOURCE"].as(String)
        destination = options["DESTINATION"].as(String)
        funko = Funko::Funko.from_paths([source])[0]
        # Create temporary build location
        dst_path = destination
        if File.exists? dst_path
          Log.error { "#{dst_path} already exists, not exporting #{funko.path}" }
          return 1
        end
        Log.info { "Exporting #{funko.path} to #{dst_path}" }
        Dir.mkdir_p(dst_path)
        funko.prepare_build Path[dst_path]
        0
      end
    end
  end
end

Faaso::Commands::Export.register
