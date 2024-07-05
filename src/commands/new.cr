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

        # Get runtime template files list
        template_base = "" 
        template_files = [] of String
        if @@known.includes? "./runtimes/#{runtime}"
          Log.info { "Using known runtime #{runtime}" }
          template_base = "./runtimes/#{runtime}/template"
          template_files = @@filelist.select { |f| f.starts_with? template_base }
        elsif File.exists? runtime
          Log.info { "Using directory #{runtime} as runtime" }
          template_base = "#{runtime}/template"
          template_files = Dir.glob("#{template_base}/**/*")
        else
          Log.error { "Can't find runtime #{runtime}" }
          return 1
        end

        pp! template_files

        # Create new folder
        if Dir.exists? folder
          Log.error { "Folder #{folder} already exists" }
          return 1
        end

        Dir.mkdir_p folder

        template_files.each do |f|
          content = IO::Memory.new
          # We need to use RUCKSACK_MODE=0 so it
          # fallbacks to the filesystem
          rucksack(f).read(content)
          if content.nil?
            Log.error { "Can't find file #{f}" }
            return 1
          end

          # f is like "#{template_base}/foo"
          # dst is like #{folder}/foo
          dst = Path[folder] / Path[f].relative_to(template_base)
          # Render templated files
          if f.ends_with? ".j2"
            dst = dst.sibling(dst.stem)
            Log.info { "Creating file #{dst} from #{f}" }
            File.open(dst, "w") do |file|
              file << Crinja.render(content.to_s, {"name" => Path[folder].basename})
            end
          else  # Just copy the file
            Log.info { "Creating file #{dst} from #{f}" }
            File.open(dst, "w") do |file|
              file << content.to_s
            end
          end
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
