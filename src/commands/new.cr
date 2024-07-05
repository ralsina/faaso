require "rucksack"

module Faaso
  module Commands
    # Creates a new empty funko out of a given runtime
    struct New
      @@known : Array(String) = {{`find ./runtimes -type d -mindepth 1`.split('\n').reject(&.empty?)}}

      def run(options, folder)
        if options["-r"].as(String) == "list"
          Log.info { "Crystal has some included runtimes:\n" }
          @@known.each do |runtime|
            Log.info { "  * #{Path[runtime].basename}" }
          end
          Log.info { "\nOr if you have your own, use a folder name" }
          return 0
        end
      end
    end
  end
end

# Embed runtimes in the binary using rucksack
{% for name in `find ./runtimes -type f`.split('\n') %}
  rucksack({{name}})
{% end %}
