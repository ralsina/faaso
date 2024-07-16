module Utils
  extend self

  # Gets a secret from STDIN, optionally echoing stars
  # ameba:disable Metrics/CyclomaticComplexity
  def get_secret(echo_stars = false, one_line = true) : String | Nil
    # Not a tty, no problem.
    if !STDIN.tty?
      password = STDIN.gets_to_end
      password = password.rstrip "\n" if one_line
      return password
    end

    # Fix for crystal bug
    STDIN.blocking = true
    final_password = ""

    # STDIN chars without buffering
    STDIN.raw do
      # Dont echo out to the terminal
      STDIN.noecho do
        while char = STDIN.read_char
          case char
          when '\r'
            break if one_line
            final_password += "\n"
          when '\u{7f}'
            # If we have a backspace
            # Move the cursor back 1 char
            if !final_password.empty?
              STDOUT << "\b \b"
              STDOUT.flush
              final_password = final_password[0...-1]
            end
            next
          when '\u{3}'
            # Control + C was pressed. Get outta here
            return nil
          when '\u{4}'
            # Control + D was pressed. Finished
            break
          when .ascii_control?
            # A Control + [] char was pressed. Not valid for a password
            next
          else
            STDOUT << "*" if echo_stars
            final_password += char
          end
          STDOUT.flush
        end
      end
    end
    final_password
  end
end
