require "rucksack"

module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct New
      @@known : Array(String) = {{`find ./runtimes -type d -mindepth 1`.split('\n').reject(&.empty?)}}
      @@filelist : Array(String) = {{`find ./runtimes -type f -mindepth 1`.split('\n').reject(&.empty?)}}

      def run(options, folder) : Int32
        Log.debug { "@@known: #{@@known}" }
        Log.debug { "@@filelist: #{@@filelist}" }

        runtime = options["-r"].as(String)
        # Give a list of known runtimes
        if runtime == "list"
          Log.info { "Crystal has some included runtimes:\n" }
          @@known.each do |i|
            Log.info { "  * #{Path[i].basename}" }
          end
          Log.info { "\nOr if you have your own, use a folder name" }
          return 0
        end

        # Create folder with a preconfigured funko for this runtime
        if @@known.includes? "./runtimes/#{runtime}"
          Log.info { "Using known runtime #{runtime}" }
        elsif File.exists? runtime
          Log.info { "Using directory #{runtime} as runtime" }
        else
          Log.error { "Can't find runtime #{runtime}" }
          return 1
        end
        0
      end
    end
  end
end

# Embed runtimes in the binary using rucksack
{% for name in `find ./runtimes -type f`.split('\n') %}
  rucksack({{name}})
{% end %}
