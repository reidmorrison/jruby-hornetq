module HornetQ::Client
  # Manages a collection of sessions which would typically be created per thread.
  # This class provides a single place where close can be called which will call
  # close on all managed sessions.
  #
  # Parameters:
  #   see regular session parameters from: HornetQ::Client::Factory::create_session
  #
  # Example:
  #   session_pool = factory.create_session_pool(config)
  #   session_pool.session do |session|
  #      ....
  #   end
  class SessionManager
    def initialize(factory, params={})
      @factory = factory
      # Save Session params since it will be used every time a new session is
      # created in the pool
      @params = params.nil? ? {} : params.dup
      # Mutex for synchronizing pool access
      @mutex = Mutex.new
      @list = []
    end

    # Create a session f and pass it to the supplied block
    # The session is automatically added to the list of managed sessions and removed
    # when the block is complete.
    def session(&block)
      s = @factory.create_session(@params)
      s.start
      @mutex.synchronize do
        @list << s
      end
      yield s
    ensure
      if s
        @mutex.synchronize do
          s.close
          @list.delete(s)
        end
      end
    end

    # Close all managed sessions
    def close
      @mutex.synchronize do
        @list.each {|session| session.close}
      end
    end
  end
end