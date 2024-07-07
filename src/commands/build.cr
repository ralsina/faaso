module Faaso
  module Commands
    # Build images for one or more funkos from source
    struct Build
      def run(options, folders : Array(String)) : Int32
        funkos = Funko::Funko.from_paths(folders)
        # Create temporary build location

        funkos.each do |funko|
          tmp_dir = Path.new("tmp", UUID.random.to_s)
          Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir

          funko.runtime = nil if options["--no-runtime"]

          funko.prepare_build(path: tmp_dir)
          if options["--local"]
            Log.info { "Building function... #{funko.name} in #{tmp_dir}" }
            funko.build tmp_dir
          else # Running against a server
            Faaso.check_version
            # Create a tarball for the funko
            buf = IO::Memory.new
            Compress::Gzip::Writer.open(buf) do |gzip|
              Crystar::Writer.open(gzip) do |tw|
                Log.debug { "Adding files to tarball" }
                Dir.glob("#{tmp_dir}/**/*").each do |path|
                  next unless File.file? path
                  rel_path = Path[path].relative_to tmp_dir
                  Log.debug { "Adding #{rel_path}" }
                  file_info = File.info(path)
                  hdr = Crystar::Header.new(
                    name: rel_path.to_s,
                    mode: file_info.permissions.to_u32,
                    size: file_info.size,
                  )
                  tw.write_header(hdr)
                  tw.write(File.read(path).to_slice)
                end
              end
            end

            tmp = File.tempname
            File.open(tmp, "w") do |outf|
              outf << buf
            end

            url = "#{Faaso.server}funkos/build/"

            begin
              Log.info { "Uploading funko to #{Faaso.server}" }
              Log.info { "Starting remote build:" }
              Crest.post(
                url,
                {"funko.tgz" => File.open(tmp), "name" => "funko.tgz"},
                user: "admin", password: "admin"
              ) do |response|
                loop do
                  Log.info { response.body_io.gets }
                  break if response.body_io.closed?
                end
              end
              Log.info { "Build finished successfully." }
            rescue ex : Crest::InternalServerError
              Log.error(exception: ex) { "Error building funko #{funko.name} from #{funko.path}" }
              return 1
            end
          end
        end
        0
      end
    end
  end
end
