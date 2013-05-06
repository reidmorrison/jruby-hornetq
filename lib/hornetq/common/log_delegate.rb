module HornetQ
  # Internal use only class for delegating HornetQ logging into the Rails or Ruby
  # loggers
  #
  private

  # HornetQ requires a connection from which it can create a logger per thread and/or class
  class LogDelegateFactory
    include Java::org.hornetq.spi.core.logging::LogDelegateFactory

    def createDelegate(klass)
      LogDelegate.new(klass.name)
    end
  end

  # Delegate HornetQ log calls to Rails, Ruby or custom logger
  class LogDelegate
    include Java::org.hornetq.spi.core.logging::LogDelegate

    # TODO: Carry class_name over into logging entries depending on implementation
    def initialize(class_name)
      @class_name = class_name
    end

    # DRY, generate a method for each required log level
    ['debug', 'error', 'fatal', 'info', 'trace', 'warn'].each do |level|
      eval <<LOG_LEVEL_METHOD
    def #{level}(message, t=nil)
      logger =  HornetQ::logger
      if logger.#{level}?
        if t
          logger.#{level}("[\#{@class_name}] \#{message}. \#{t.toString}")
          logger.#{level}(t.stack_trace.toString)
        else
          logger.#{level}{"[\#{@class_name}] \#{message}"}
        end
      end
    end

    def is#{level.capitalize}Enabled
      HornetQ::logger.#{level}?
    end

LOG_LEVEL_METHOD
    end

  end
end