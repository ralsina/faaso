require "baked_file_system"

module Runtime
  extend self

  class FileStorage
    extend BakedFileSystem
    bake_folder "runtimes", "."
  end

  @@known : Array(String) = {{
                              `find runtimes -mindepth 1 -maxdepth 1 -type d`
                                .split('\n')
                                .reject(&.empty?).map { |x| x.split("/")[-1] }
                            }}
  @@filelist : Array(String) = {{
                                 `find runtimes -mindepth 1 -type f`
                                   .split('\n')
                                   .reject(&.empty?)
                               }}

  Log.debug { "@@known: #{@@known}" }
  Log.debug { "@@filelist: #{@@filelist}" }

  def list
    Log.info { "FaaSO has some included runtimes:\n" }
    @@known.each do |i|
      Log.info { "  * #{Path[i].basename}" }
    end
    Log.info { "\nOr if you have your own, use a folder name" }
  end

  def self.runtime_files(runtime : String) : {String, Array(String)}
    runtime_base = ""
    runtime_files = [] of String

    if @@known.includes? runtime
      # Embeedded runtime
      Log.info { "Using known runtime #{runtime}" }
      runtime_base = "runtimes/#{runtime}/"
      runtime_files = @@filelist.select(&.starts_with?(runtime_base)).map { |path|
        Path[path].normalize.to_s
      }
    elsif File.exists? runtime
      # External runtime
      Log.info { "Using directory #{runtime} as runtime" }
      runtime_base = "#{runtime}"
      runtime_files = Dir.glob("#{runtime_base}/**/*").select { |file| File.file?(file) }
      runtime_files = runtime_files.map { |file| Path[file].normalize.to_s }
    else
      raise Exception.new("Can't find runtime #{runtime}")
    end
    {runtime_base, runtime_files.reject(&.starts_with? Path[runtime_base, "template"].normalize.to_s)}
  end

  def self.template_files(runtime : String) : {String, Array(String)}
    template_base = ""
    template_files = [] of String
    if @@known.includes? runtime
      # Embeedded runtime
      Log.info { "Using known runtime #{runtime}" }
      template_base = "runtimes/#{runtime}/template"
      template_files = @@filelist.select(&.starts_with?(template_base))
    elsif File.exists? runtime
      # External runtime
      Log.info { "Using directory #{runtime} as runtime" }
      template_base = "#{runtime}/template"
      template_files = Dir.glob("#{template_base}/**/*").select { |file| File.file?(file) }
      template_files = template_files.map { |file| Path[file].normalize.to_s }
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

      # Try FileStorage first
      begin
        # Paths in FileStorage are like "/crystal/template/foo.j2
        # and `file` is runtime/crystal/template/foo.j2
        # so, convert to that
        handle = FileStorage.get(file[8..])
      rescue ex : BakedFileSystem::NoSuchFileError
        handle = File.open(file)
      end
      content << handle.gets_to_end
      if content.nil?
        raise Exception.new("Can't find file #{file}")
        return 1
      end

      # file is like "#{base}/foo"
      # dst is like #{dst_path}/foo
      dst = Path[dst_path] / Path[file].relative_to(base_path)
      # Make sure we have dest dir
      Dir.mkdir_p dst.dirname unless File.directory? dst.dirname
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
