require "yaml"

CONFIG = Config.load

class Config
  include YAML::Serializable

  property hosts : Hash(String, {String, String}) = Hash(String, {String, String}).new

  def initialize
    @hosts = {} of String => {String, String}
  end

  def self.load : Config
    if File.file? ".faaso.yml"
      return Config.from_yaml(File.read(".faaso.yml"))
    end
    Config.new
  end

  def self.save
    File.open(".faaso.yml", "w") do |outf|
      outf << CONFIG.to_yaml
    end
  end

  @@already_reported = false

  def self.server : String
    url = ENV.fetch("FAASO_SERVER", nil)
    if url.nil?
      Log.error { "FAASO_SERVER not set." }
      exit 1
    end
    url += "/" unless url.ends_with? "/"
    Log.info { "Using server #{url}" } unless @@already_reported
    @@already_reported = true
    url
  end

  def self.auth : {String, String}
    CONFIG.hosts.fetch(server, {"admin", ""})
  end
end
