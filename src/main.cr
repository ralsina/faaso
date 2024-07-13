require "./config.cr"
require "./faaso.cr"
require "colorize"
require "docopt"
require "rucksack"

macro version
  "{{ `grep version shard.yml | cut -d: -f2` }}".strip()
end

Oplog.setup(4) unless ENV.fetch("FAASO_SERVER_SIDE", nil)

if ARGV.empty? || !Faaso::Commands::COMMANDS.has_key?(ARGV[0])
  Log.info { "FaaSO CLI tool, version #{version}" }
  Log.info { "Usage: faaso COMMAND [ARGS]" }
  Log.info { "Try 'faaso help' for a list of commands." }
  Log.info { "Try 'faaso help COMMAND' for more information on a command." }
  exit 1
end

cmdname = ARGV[0]

options = Docopt.docopt(Faaso::Commands::COMMANDS[cmdname].doc, ARGV)

begin
  exit Faaso::Commands::COMMANDS[cmdname].new(options).run
rescue ex : Exception
  Log.error { ex.message }
  Log.debug { ex.backtrace.join("\n") } if ex.backtrace?
  exit 1
end
# TODO: version command
