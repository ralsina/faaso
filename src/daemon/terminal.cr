module Terminal
  extend self

  @@terminal_process : Process | Nil = nil

  def start_terminal(_args = ["bash"], readonly = false)
    args = ["-p", "7681", "-c", "admin:admin", "-o"]
    args += ["-W"] unless readonly
    args += _args 
    # We have a process there, kill it
    @@terminal_process.as(Process).terminate if !@@terminal_process.nil?
    @@terminal_process = Process.new(
      command: "/usr/bin/ttyd",
      args: args)
    Log.info {"Terminal started on port 7681"}
  end
end


Terminal.start_terminal