require "../runtime.cr"

module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct New
      def run(options, folder) : Int32
        runtime = options["-r"].as(String)
        # Give a list of known runtimes
        if runtime == "list"
          Runtime.list
          return 0
        end

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
