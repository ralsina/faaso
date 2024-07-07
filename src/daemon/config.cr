require "cr-config"
require "kemal-basic-auth"

class Config
  include CrConfig

  option password : String, default: "admin"

  def self.load
    builder = Config.new_builder
    builder.providers do
      [
        CrConfig::Providers::SimpleFileProvider.new("config/faaso.yml"),
        CrConfig::Providers::EnvVarProvider.new,
      ]
    end
    config = builder.build
    Config.set_instance config
  end
end

class ConfigAuthHandler < Kemal::BasicAuth::Handler
  def initialize
    # Ignored, just make the compiler happy
    @credentials = Kemal::BasicAuth::Credentials.new({"foo" => "bar"})
  end

  def authorize?(value) : String?
    username, password = Base64.decode_string(value[BASIC.size + 1..-1]).split(":")
    if username == "admin" && password == Config.instance.password
      username
    else
      nil
    end
  end
end

# Tie auth to config

add_handler ConfigAuthHandler.new
