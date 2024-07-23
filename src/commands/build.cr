require "./command.cr"
require "base58"

module Faaso
  module Commands
    # Build images for one or more funkos from source
    struct Build < Command
      @@name = "build"
      @@doc : String = <<-DOC
Builds docker images out of source folders.

The source folders must contain a funko.yml that may reference
a runtime to make the source buildable by providing extra files.

Usage:
  faaso build  FOLDER ...           [-v <level>] [-l] [--no-runtime][--no-cache]

Options:
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
  --no-cache       Don't use the docker cache when building the funko
  --no-runtime     Don't merge a runtime into the funko before building
DOC

      def run : Int32
        folders = options["FOLDER"].as(Array(String))
        no_cache = !options["--no-cache"].nil?
        funkos = Funko::Funko.from_paths(folders)
        # Create temporary build location

        funkos.each do |funko|
          tmp_dir = Path.new(Dir.tempdir, Random.base58(8))
          Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir

          funko.runtime = nil if options["--no-runtime"]

          funko.prepare_build(path: tmp_dir)
          if options["--local"]
            Log.info { "Building function... #{funko.name} in #{tmp_dir}" }
            funko.build tmp_dir, no_cache
            FileUtils.rm_rf(tmp_dir)
            next
          end
          Faaso.check_version
          # Create a tarball for the funko
          buf = IO::Memory.new
          Compress::Gzip::Writer.open(buf) do |gzip|
            Crystar::Writer.open(gzip) do |tarball|
              Log.debug { "Adding files to tarball" }
              Dir.glob("#{tmp_dir}/**/*").each do |path|
                next unless File.file? path
                rel_path = Path[path].relative_to tmp_dir
                Log.debug { "Adding #{rel_path}" }
                file_info = File.info(path)
                hdr = Crystar::Header.new(
                  name: rel_path.to_s,
                  mode: file_info.permissions.to_i64,
                  size: file_info.size,
                )
                tarball.write_header(hdr)
                tarball.write(File.read(path).to_slice)
              end
            end
          end
          FileUtils.rm_rf(tmp_dir)
          tmp = File.tempname
          File.open(tmp, "w") do |outf|
            outf << buf
          end

          url = "#{Config.server}funkos/build/"

          user, password = Config.auth
          Log.info { "Uploading funko to #{Config.server}" }
          Log.info { "Starting remote build:" }
          Crest.post(
            url,
            {"funko.tgz" => File.open(tmp), "name" => "funko.tgz"},
            user: user, password: password
          ) do |response|
            IO.copy(response.body_io, STDOUT)
          end
          Log.info { "Build finished successfully." }
        rescue ex : Crest::InternalServerError
          Log.error(exception: ex) { "Error building funko #{funko.name} from #{funko.path}" }
          return 1
        end
        0
      end
    end
  end
end

Faaso::Commands::Build.register
