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
    _verbosity = [
      Log::Severity::Fatal,
      Log::Severity::Error,
      Log::Severity::Warn,
      Log::Severity::Info,
      Log::Severity::Debug,
      Log::Severity::Trace,
    ][[verbosity, 5].min]
    Log.setup(
      _verbosity,
      Log::IOBackend.new(io: STDERR, formatter: LogFormat)
    )
  end
end

doc = <<-DOC
FaaSO CLI tool.

Usage:
  faaso build FOLDER ... [-l] [-v=<level>]
  faaso scale FUNKO_NAME [SCALE] [-l] [-v=<level>]
  faaso status FUNKO_NAME [-l] [-v=<level>]
  faaso export SOURCE DESTINATION   [-v=<level>]

Options:
  -l --local       Run commands locally instead of against a FaaSO server.
  -h --help        Show this screen.
  --version        Show version.
  -v=level         Control the logging verbosity, 0 to 5 [default: 3]
DOC

ans = Docopt.docopt(doc, ARGV)
LogFormat.setup(ans["-v"].to_s.to_i)

case ans
when .fetch("build", false)
  Faaso::Commands::Build.new.run(ans, ans["FOLDER"].as(Array(String)))
when .fetch("export", false)
  Faaso::Commands::Export.new.run(ans, ans["SOURCE"].as(String), ans["DESTINATION"].as(String))
when .fetch("scale", false)
  Faaso::Commands::Scale.new.run(ans, ans["FUNKO_NAME"].as(String), ans["SCALE"])
when .fetch("status", false)
  Faaso::Commands::Status.new.run(ans, ans["FUNKO_NAME"].as(String))
end
