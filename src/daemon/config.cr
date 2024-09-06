require "kemal-basic-auth"
require "yaml"
require "../funko"

class Config
  include YAML::Serializable

  @@instance : Config = Config.from_yaml(File.read("config/faaso.yml"))

  property password : String = "admin"
  property scale : Hash(String, Int32) = {} of String => Int32

  def self.instance : Config
    @@instance
  end

  def self.reload
    @@instance = Config.from_yaml(File.read("config/faaso.yml"))
    Funko::Funko.from_docker.each do |funko|
      next if funko.name == "proxy"
      self.instance.scale[funko.name] = funko.scale
    end
  end

  def save
    File.write("config/faaso.yml", to_yaml)
  end
end

class ConfigAuthHandler < Kemal::BasicAuth::Handler
  only ["/auth", "/auth/*"]

  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end

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
