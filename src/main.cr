require "./config.cr"
require "./faaso.cr"
require "colorize"
require "docopt"
require "oplog"
require "rucksack"

macro version
  "{{ `grep version shard.yml | cut -d: -f2` }}".strip()
end

doc = <<-DOC
FaaSO CLI tool.

Usage:
  faaso build  FOLDER ...           [-v <level>] [-l] [--no-runtime]
  faaso deploy FUNKO                [-v <level>] [-l]
  faaso export SOURCE DESTINATION   [-v <level>]
  faaso login                       [-v <level>]
  faaso new -r runtime FOLDER       [-v <level>]
  faaso scale FUNKO [SCALE]         [-v <level>] [-l]
  faaso secret (-d|-a) FUNKO SECRET [-v <level>] [-l]
  faaso status FUNKO                [-v <level>] [-l]
  faaso version
  faaso help COMMAND

Options:
  -a --add         Add
  -d --delete      Delete
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  --no-runtime     Don't merge a runtime into the funko
  -r runtime       Runtime for the new funko (use -r list for examples)
  -v level         Control the logging verbosity, 0 to 6 [default: 4]
DOC

ans = Docopt.docopt(doc, ARGV)
Oplog.setup(ans["-v"].to_s.to_i) unless ENV.fetch("FAASO_SERVER_SIDE", nil)
Log.debug { ans }

case ans
when .fetch("build", false)
  exit Faaso::Commands::Build.new.run(ans, ans["FOLDER"].as(Array(String)))
when .fetch("deploy", false)
  exit Faaso::Commands::Deploy.new.run(ans, ans["FUNKO"].as(String)) if ans["--local"]
  Faaso.rpc_call(ARGV)
when .fetch("export", false)
  exit Faaso::Commands::Export.new.run(ans, ans["SOURCE"].as(String), ans["DESTINATION"].as(String))
when .fetch("login", false)
  exit Faaso::Commands::Login.new.run(ans)
when .fetch("new", false)
  exit Faaso::Commands::New.new.run(ans, ans["FOLDER"].as(Array(String))[0])
when .fetch("scale", false)
  exit Faaso::Commands::Scale.new.run(ans, ans["FUNKO"].as(String), ans["SCALE"]) if ans["--local"]
  Faaso.rpc_call(ARGV)
when .fetch("secret", false)
  exit Faaso::Commands::Secret.new.run(ans, ans["FUNKO"].as(String), ans["SECRET"].as(String))
when .fetch("status", false)
  exit Faaso::Commands::Status.new.run(ans, ans["FUNKO"].as(String)) if ans["--local"]
  Faaso.rpc_call(ARGV)
when .fetch("version", false)
  Log.info { "#{version}" }
end

exit 0
