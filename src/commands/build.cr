module Faaso
  module Commands
    # Build images for one or more funkos from source
    struct Build
      def run(options, folders : Array(String))
        funkos = Funko::Funko.from_paths(folders)

        if options["--local"]
          funkos.each do |funko|
            # Create temporary build location
            tmp_dir = Path.new("tmp", UUID.random.to_s)
            Dir.mkdir_p(tmp_dir) unless File.exists? tmp_dir
            funko.prepare_build tmp_dir

            Log.info { "Building function... #{funko.name} in #{tmp_dir}" }
            funko.build tmp_dir
          end
        else # Running against a server
          funkos.each do |funko|
            # Create a tarball for the funko
            buf = IO::Memory.new
            Compress::Gzip::Writer.open(buf) do |gzip|
              Crystar::Writer.open(gzip) do |tw|
                Dir.glob("#{funko.path}/**/*").each do |path|
                  next unless File.file? path
                  rel_path = Path[path].relative_to funko.path
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

            url = "#{FAASO_SERVER}funkos/build/"

            begin
              Log.info { "Uploading funko to #{FAASO_SERVER}" }
              response = Crest.post(
                url,
                {"funko.tgz" => File.open(tmp), "name" => "funko.tgz"},
                user: "admin", password: "admin"
              )
              Log.info { "Build finished successfully." }
              body = JSON.parse(response.body)
              Log.info { body["stdout"] }
            rescue ex : Crest::InternalServerError
              Log.error { "Error building funko #{funko.name} from #{funko.path}" }
              body = JSON.parse(ex.response.body)
              Log.info { body["stdout"] }
              Log.error { body["stderr"] }
              exit 1
            end
          end
        end
      end
    end
  end
end
