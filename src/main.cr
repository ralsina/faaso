require "commander"
require "./faaso.cr"

cli = Commander::Command.new do |cmd|
  cmd.use = "faaso"
  cmd.long = "Functions as a Service, Open"

  cmd.commands.add do |command|
    command.use = "build"
    command.short = "Build a funko"
    command.long = "Build a funko's Docker image and upload it to registry"
    command.run do |options, arguments|
      Faaso::Commands::Build.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "up"
    command.short = "Ensure funkos are running"
    command.long = "Start/unpause/create containers for requested funkos and ensure they are up."
    command.run do |options, arguments|
      Faaso::Commands::Up.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "deploy"
    command.short = "Deploy latest images"
    command.long = "Update containers for all funkos to latest image."
    command.run do |options, arguments|
      Faaso::Commands::Deploy.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "down"
    command.short = "Stop a function"
    command.long = "Stop a function in a container"
    command.run do |options, arguments|
      Faaso::Commands::Down.new(options, arguments).run
    end
  end
end

Commander.run(cli, ARGV)
