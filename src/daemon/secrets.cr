require "kemal"

module Secrets
  SECRETS     = Hash(String, String).new
  SECRET_PATH = "./secrets/"

  # TODO: sanitize all inputs

  # Store secrets in a tree of files
  def self.update_secrets
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

  # Gets a secret in form {"name": "funko_name-secret_name", "value": "secret_value"}
  post "/secrets/" do |env|
    name = env.params.json["name"].as(String)
    value = env.params.json["value"].as(String)
    SECRETS[name] = value
    Secrets.update_secrets
    halt env, status_code: 201, response: "Created"
  end

  # Deletes a secret from the disk and memory
  delete "/secrets/:name/" do |env|
    name = env.params.url["name"]
    SECRETS.delete(name)
    update_secrets
    halt env, status_code: 204, response: "Deleted"
  end
end
