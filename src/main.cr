require "commander"
require "./faaso.cr"

cli = Commander::Command.new do |cmd|
  cmd.use = "faaso"
  cmd.long = "Functions as a Service, Open"

  cmd.commands.add do |command|
    command.use = "build"
    command.short = "Build a function"
    command.long = "Build a function's Docker image and optionally upload it to registry"
    command.run do |options, arguments|
      Faaso::Commands::Build.new(options, arguments).run
    end
  end

  cmd.commands.add do |command|
    command.use = "up"
    command.short = "Start a function"
    command.long = "Start a function in a container"
    command.run do |options, arguments|
      Faaso::Commands::Up.new(options, arguments).run
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
