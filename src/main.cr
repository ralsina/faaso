require "./faaso.cr"
require "colorize"
require "commander"

# Log formatter for
struct LogFormat < Log::StaticFormatter
  @@colors = {
    "FATAL" => :red,
    "ERROR" => :red,
    "WARN"  => :yellow,
    "INFO"  => :green,
    "DEBUG" => :blue,
    "TRACE" => :light_blue,
  }

  def run
    string "[#{Time.local}] #{@entry.severity.label}: #{@entry.message}".colorize(@@colors[@entry.severity.label])
  end

  def self.setup(quiet : Bool, verbosity)
    if quiet
      _verbosity = Log::Severity::Fatal
    else
      _verbosity = [
        Log::Severity::Fatal,
        Log::Severity::Error,
        Log::Severity::Warn,
        Log::Severity::Info,
        Log::Severity::Debug,
        Log::Severity::Trace,
      ][[verbosity, 5].min]
    end
    Log.setup(
      _verbosity,
      Log::IOBackend.new(io: STDERR, formatter: LogFormat)
    )
  end
end

cli = Commander::Command.new do |cmd|
  cmd.use = "faaso"
  cmd.long = "Functions as a Service, Open"

  cmd.flags.add do |flag|
    flag.name = "local"
    flag.short = "-l"
    flag.long = "--local"
    flag.description = "Run commands locally instead of against a FaaSO server."
    flag.default = false
    flag.persistent = true
  end

  cmd.flags.add do |flag|
    flag.name = "quiet"
    flag.short = "-q"
    flag.long = "--quiet"
    flag.description = "Don't log anything"
    flag.default = false
    flag.persistent = true
  end

  cmd.flags.add do |flag|
    flag.name = "verbosity"
    flag.short = "-v"
    flag.long = "--verbosity"
    flag.description = "Control the logging verbosity, 0 to 5 "
    flag.default = 3
    flag.persistent = true
  end

  cmd.commands.add do |command|
    command.use = "build"
    command.short = "Build a funko"
    command.long = "Build a funko's Docker image and upload it to registry"
    command.run do |options, arguments|
      LogFormat.setup(options.@bool["quiet"], options.@int["verbosity"])
      Faaso::Commands::Build.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "up"
    command.short = "Ensure funkos are running"
    command.long = "Start/unpause/create containers for requested funkos and ensure they are up."
    command.run do |options, arguments|
      LogFormat.setup(options.@bool["quiet"], options.@int["verbosity"])
      Faaso::Commands::Up.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "deploy"
    command.short = "Deploy latest images"
    command.long = "Update containers for all funkos to latest image."
    command.run do |options, arguments|
      LogFormat.setup(options.@bool["quiet"], options.@int["verbosity"])
      Faaso::Commands::Deploy.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "down"
    command.short = "Stop a funko"
    command.long = "Stop a funko in a container"
    command.run do |options, arguments|
      LogFormat.setup(options.@bool["quiet"], options.@int["verbosity"])
      Faaso::Commands::Down.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "export"
    command.short = "Export a funko to a directory"
    command.long = "Exports a funko as a self-contained directory."
    command.run do |options, arguments|
      LogFormat.setup(options.@bool["quiet"], options.@int["verbosity"])
      Faaso::Commands::Export.new(options, arguments).run
    end
  end
end

Commander.run(cli, ARGV)
