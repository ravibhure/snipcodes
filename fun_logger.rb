#!/usr/bin/env ruby
#  both logs studio out into file and stdout
#  snip code from internet 

require 'logger'

class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end

log_file = File.open("logfiel.log", "a")

logger = Logger.new MultiIO.new(STDOUT, log_file)

#logger.level = Logger::INFO
logger.formatter = proc { |severity, datetime, progname, msg|
    % [severity[0..0], format_datetime(time), $$, severity, progname,
            msg2str(msg)]
}

class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end

logger.info "你是ssss"
