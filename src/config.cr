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
end
