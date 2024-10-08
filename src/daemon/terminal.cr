module Terminal
  extend self

  @@terminal_process : Process | Nil = nil

  def start_terminal(_args = ["sh"], readonly = true)
    args = ["-p", "7681", "-o"]
    args += ["-W"] unless readonly
    args += _args
    # We have a process there, kill it
    begin
      @@terminal_process.as(Process).terminate if !@@terminal_process.nil?
    rescue e : RuntimeError
      Log.error { "Error terminating terminal process: #{e.message}" }
    end
    @@terminal_process = Process.new(
      command: "/usr/bin/ttyd",
      args: args)
    Log.info { "Terminal started on port 7681" }
  end
end
