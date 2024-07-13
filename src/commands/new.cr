require "../runtime.cr"

module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct New < Command
      @@doc : String = <<-DOC
FaaSO CLI tool, new command.

Creates a new empty funko out of a given runtime. The runtime is
the template for the new funko. For example the "express" runtime
will create a new funko with a simple express server.

The runtime can be one of FaaSO's built-in runtimes or a custom
one (a folder). To see a list of known runtimes, use '-r list'.

Usage:
  faaso new -r runtime FOLDER     [-v <level>]
  faaso new -r list

Options:
  -r runtime       Runtime for the new funko (use -r list for examples)
  -h --help        Show this screen
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

def run : Int32
        runtime = options["-r"].as(String)
        # Give a list of known runtimes
        if runtime == "list"
          Runtime.list
          return 0
        end

        folder = options["FOLDER"].as(String)
        # Create new folder
        if Dir.exists? folder
          Log.error { "Folder #{folder} already exists" }
          return 1
        end

        # Get runtime template files list
        template_base, template_files = Runtime.template_files(runtime)

        Runtime.copy_templated(
          template_base,
          template_files,
          folder,
          {"name"    => Path[folder].basename,
           "runtime" => runtime}
        )
        0
      end
    end
  end
end

Faaso::Commands::COMMANDS["new"] = Faaso::Commands::New
