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
#   debug?
#   info_enabled?
#   trace_enabled?

# This has to be a "mix-in" because the class can return instances of itself
class org.hornetq.core.logging::Logger
  def debug?
    debug_enabled?
  end
  
end