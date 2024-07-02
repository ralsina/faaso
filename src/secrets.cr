module Secrets
  extend self
  SECRETS     = Hash(String, String).new
  SECRET_PATH = "./secrets/"

  # TODO: sanitize all inputs

  # Store secrets in a tree of files
  def update_secrets
    # Save new secrets
    SECRETS.map do |_name, value|
      funko, name = _name.split("-", 2)
      funko_dir = Path.new(SECRET_PATH, funko)
      Dir.mkdir_p(funko_dir)
      File.write(Path.new(funko_dir, name), value)
    end
    # Delete secrets not in the hash
    Dir.glob(Path.new(SECRET_PATH, "*")).each do |funko_dir|
      funko = File.basename(funko_dir)
      Dir.glob(Path.new(funko_dir, "*")).each do |secret_file|
        name = File.basename(secret_file)
        unless SECRETS.has_key?("#{funko}-#{name}")
          File.delete(secret_file)
        end
      end
    end
  end

  # Load secrets from the disk
  def load_secrets
    Dir.glob(Path.new(SECRET_PATH, "*")).each do |funko_dir|
      funko = File.basename(funko_dir)
      Dir.glob(Path.new(funko_dir, "*")).each do |secret_file|
        name = File.basename(secret_file)
        value = File.read(secret_file)
        SECRETS["#{funko}-#{name}"] = value
      end
    end
  end
end

Secrets.load_secrets
