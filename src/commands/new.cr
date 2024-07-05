module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct New
      def run(options, folder)
        if options["RUNTIME"].as(String) == "list"
            Log.info {"Known runtimes:"} 
        end
      end
    end
  end
end
