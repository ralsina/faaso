require "./config.cr"
require "./faaso.cr"
require "./log.cr"
require "colorize"
require "docopt"
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
Logging.setup(ans["-v"].to_s.to_i)
Log.debug { ans }

status : Int32 = 0
case ans
when .fetch("build", false)
  status = Faaso::Commands::Build.new.run(ans, ans["FOLDER"].as(Array(String)))
when .fetch("deploy", false)
  status = Faaso::Commands::Deploy.new.run(ans, ans["FUNKO"].as(String))
when .fetch("export", false)
  status = Faaso::Commands::Export.new.run(ans, ans["SOURCE"].as(String), ans["DESTINATION"].as(String))
when .fetch("login", false)
  status = Faaso::Commands::Login.new.run(ans)
when .fetch("new", false)
  status = Faaso::Commands::New.new.run(ans, ans["FOLDER"].as(Array(String))[0])
when .fetch("scale", false)
  status = Faaso::Commands::Scale.new.run(ans, ans["FUNKO"].as(String), ans["SCALE"])
when .fetch("secret", false)
  status = Faaso::Commands::Secret.new.run(ans, ans["FUNKO"].as(String), ans["SECRET"].as(String))
when .fetch("status", false)
  status = Faaso::Commands::Status.new.run(ans, ans["FUNKO"].as(String))
when .fetch("version", false)
  Log.info { "#{version}" }
end

exit(status)
