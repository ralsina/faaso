require "cr-config"

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
