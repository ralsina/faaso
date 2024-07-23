require "log"
require "oplog"
require "polydocopt"

module Faaso
  module Commands
    # Base for command structs
    abstract struct Command < Polydocopt::Command
      def initialize(@options)
        Oplog.setup(@options.fetch("-v", 4).to_s.to_i) unless ENV.fetch("FAASO_SERVER_SIDE", nil)
      end

      def run : Int32
        raise Exception.new("Not implemented")
      end
    end
  end
end
