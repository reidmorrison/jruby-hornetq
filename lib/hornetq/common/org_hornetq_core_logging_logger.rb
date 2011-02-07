# Extend HornetQ Logger class to respond to standard Rails/Ruby log methods
#   
# The following methods are already implemented by the java class
#   initialize
#   delegate
#   
# The following methods are being replaced so that they can support blocks
#   trace
#   debug
#   info
#   warn
#   error
#   fatal
#   
# The following methods are new
#   trace?
#   debug?
#   info?
#   warn?
#   error?
#   fatal?
#   

# This has to be a "mix-in" because the class can return instances of itself
class org.hornetq.core.logging::Logger
  # DRY, generate a method for each required log level
  ['debug', 'error', 'fatal', 'info', 'trace', 'warn'].each do |level|
    eval <<LOG_LEVEL_METHOD
  def #{level}?
    #{level}_enabled?
  end
  
  # Support logging with block parameters that only get evaluated if the 
  # matching log level is enabled
  def #{level}(message=nil, &block)
    if #{level}?
      if block
        java_send :#{level}, block.call
      else
        java_send :#{level}, message        
      end
    end
  end
LOG_LEVEL_METHOD
  end
  
  private
  # Implement since not implemented by Logger
  def error_enabled?
    true
  end
  def fatal_enabled?
    true
  end
  def warn_enabled?
    true
  end
end