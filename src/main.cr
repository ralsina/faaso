require "./faaso.cr"
require "colorize"
require "docopt"

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
    string "#{@entry.message}".colorize(@@colors[@entry.severity.label])
  end

  def self.setup(verbosity)
    Colorize.on_tty_only!
    if verbosity < 3
      _verbosity = [
        Log::Severity::Fatal,
        Log::Severity::Error,
        Log::Severity::Warn,
      ][[verbosity, 2].min]
      Log.setup(
        _verbosity,
        Log::IOBackend.new(io: STDERR, formatter: LogFormat)
      )
    end

    _verbosity = [Log::Severity::Info,
                  Log::Severity::Debug,
                  Log::Severity::Trace,
    ][[verbosity - 3, 3].min]
    Log.setup(
      _verbosity,
      Log::IOBackend.new(io: STDOUT, formatter: LogFormat)
    )
  end
end

doc = <<-DOC
FaaSO CLI tool.

Usage:
  faaso build  FOLDER ...           [-v <level>] [-l]
  faaso export SOURCE DESTINATION   [-v <level>]
  faaso new -r runtime FOLDER       [-v <level>]
  faaso scale FUNKO [SCALE]         [-v <level>] [-l]
  faaso secret (-d|-a) FUNKO SECRET [-v <level>] [-l]
  faaso status FUNKO                [-v <level>] [-l]
  faaso version

Options:
  -a --add         Add
  -d --delete      Delete
  -h --help        Show this screen
  -l --local       Run commands locally instead of against a FaaSO server
  -r runtime       Runtime for the new funko (use -r list for examples)
  -v level         Control the logging verbosity, 0 to 5 [default: 3]
DOC

ans = Docopt.docopt(doc, ARGV)
LogFormat.setup(ans["-v"].to_s.to_i)
Log.debug { ans }

case ans
when .fetch("build", false)
  Faaso::Commands::Build.new.run(ans, ans["FOLDER"].as(Array(String)))
when .fetch("export", false)
  Faaso::Commands::Export.new.run(ans, ans["SOURCE"].as(String), ans["DESTINATION"].as(String))
when .fetch("new", false)
  Faaso::Commands::New.new.run(ans, ans["FOLDER"].as(Array(String))[0])
when .fetch("scale", false)
  Faaso::Commands::Scale.new.run(ans, ans["FUNKO"].as(String), ans["SCALE"])
when .fetch("secret", false)
  Faaso::Commands::Secret.new.run(ans, ans["FUNKO"].as(String), ans["SECRET"].as(String))
when .fetch("status", false)
  Faaso::Commands::Status.new.run(ans, ans["FUNKO"].as(String))
end
