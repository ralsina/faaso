require "./config.cr"
require "./faaso.cr"
require "colorize"
require "docopt"

macro version
  "{{ `grep version shard.yml | cut -d: -f2` }}".strip()
end

Oplog.setup(4) unless ENV.fetch("FAASO_SERVER_SIDE", nil)

exit Polydocopt.main("faaso", ["--help"]) if ARGV.empty?
cmdname = ARGV[0]

if cmdname == "version"
  Log.info { version }
  exit 0
end

begin
  exit Polydocopt.main("faaso", ARGV)
rescue ex : Exception
  Log.error { ex.message }
  Log.debug { ex.backtrace.join("\n") } if ex.backtrace?
  exit 1
end
