module Faaso
  module Commands
    struct Export
      def run(options, source : String, destination : String) : Int32
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
