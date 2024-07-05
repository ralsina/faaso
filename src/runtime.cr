require "rucksack"

module Runtime
  extend self

  @@known : Array(String) = {{`find ./runtimes -type d -mindepth 1`.split('\n').reject(&.empty?)}}
  @@filelist : Array(String) = {{`find ./runtimes -type f -mindepth 1`.split('\n').reject(&.empty?)}}

  Log.debug { "@@known: #{@@known}" }
  Log.debug { "@@filelist: #{@@filelist}" }

  def list
    Log.info { "Crystal has some included runtimes:\n" }
    @@known.each do |i|
      Log.info { "  * #{Path[i].basename}" }
    end
    Log.info { "\nOr if you have your own, use a folder name" }
  end

  def self.runtime_files(runtime : String) : {String, Array(String)}
    runtime_base = ""
    runtime_files = [] of String
    if @@known.includes? "./runtimes/#{runtime}"
      Log.info { "Using known runtime #{runtime}" }
      runtime_base = "./runtimes/#{runtime}/"
      runtime_files = @@filelist.select(&.starts_with?(runtime_base))
    elsif File.exists? runtime
      Log.info { "Using directory #{runtime} as runtime" }
      runtime_base = "#{runtime}"
      runtime_files = Dir.glob("#{runtime_base}/**/*")
    else
      raise Exception.new("Can't find runtime #{runtime}")
    end
    {runtime_base, runtime_files.reject(&.starts_with? "#{runtime_base}template")}
  end

  def self.template_files(runtime : String) : {String, Array(String)}
    template_base = ""
    template_files = [] of String
    if @@known.includes? "./runtimes/#{runtime}"
      Log.info { "Using known runtime #{runtime}" }
      template_base = "./runtimes/#{runtime}/template"
      template_files = @@filelist.select(&.starts_with?(template_base))
    elsif File.exists? runtime
      Log.info { "Using directory #{runtime} as runtime" }
      template_base = "#{runtime}/template"
      template_files = Dir.glob("#{template_base}/**/*")
    else
      raise Exception.new("Can't find runtime #{runtime}")
    end
    {template_base, template_files}
  end

  # Copyes files from a runtime to a destination folder.
  # Files ending in .j2 are rendered as Jinja2 templates
  # using the provided context
  def copy_templated(
    base_path : String,
    files : Array(String),
    dst_path : String,
    context
  )
    Dir.mkdir_p dst_path
    files.each do |file|
      content = IO::Memory.new
      # We need to use RUCKSACK_MODE=0 so it
      # fallbacks to the filesystem. Read the
      # file into a buffer
      rucksack(file).read(content)
      if content.nil?
        raise Exception.new("Can't find file #{file}")
        return 1
      end

      # file is like "#{base}/foo"
      # dst is like #{dst_path}/foo
      dst = Path[dst_path] / Path[file].relative_to(base_path)
      # Render templated files
      if file.ends_with? ".j2"
        dst = dst.sibling(dst.stem)
        Log.info { "  Creating file #{dst} from #{file}" }
        File.open(dst, "w") do |outf|
          outf << Crinja.render(content.to_s, context)
        end
      else # Just copy the file
        Log.info { "  Creating file #{dst} from #{file}" }
        File.open(dst, "w") do |outf|
          outf << content.to_s
        end
      end
    end
  end
end

# Embed runtimes in the binary using rucksack
{% for name in `find ./runtimes -type f`.split('\n') %}
  rucksack({{name}})
{% end %}