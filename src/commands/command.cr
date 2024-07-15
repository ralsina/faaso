require "log"
require "oplog"

module Faaso
  module Commands
    # Base for command structs
    abstract struct Command
      property options : Hash(String, (Nil | String | Int32 | Bool | Array(String)))
      property name : String = "command"
      class_property doc : String = ""

      def initialize(@options)
        Oplog.setup(@options.fetch("-v", 4).to_s.to_i) unless ENV.fetch("FAASO_SERVER_SIDE", nil)
      end

      def run : Int32
        raise Exception.new("Not implemented")
      end
    end

    # Command class registry
    COMMANDS = {} of String => Command.class
  end
end
