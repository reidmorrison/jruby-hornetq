module HornetQ::Client

  # For internal use only
  class MessageHandler
    include Java::org.hornetq.api.core.client::MessageHandler

    # Parameters:
    #   :statistics Capture statistics on how many messages have been read
    #      true  : Capture statistics on the number of messages received
    #              and the time it took to process them.
    #              The timer starts when the listener instance is created and finishes when either the last message was received,
    #              or when Consumer::on_message_statistics is called. In this case on_message_statistics::statistics
    #              can be called several times during processing without affecting the end time.
    #              The start time and message count is never reset for this instance
    def initialize(params={}, &proc)
      @proc = proc

      if params[:statistics]
        @message_count = 0
        @start_time = Time.now
      end
    end

    # Method called for every message received on the queue
    # Per the specification, this method will be called sequentially for each message on the queue.
    # This method will not be called again until its prior invocation has completed.
    # Must be onMessage() since on_message() does not work for interface methods that must be implemented
    def onMessage(message)
      begin
        if @message_count
          @message_count += 1
          @last_time = Time.now
        end
        @proc.call message
      rescue SyntaxError, NameError => boom
        HornetQ::logger.error "Unhandled Exception processing Message. Doesn't compile: " + boom
        HornetQ::logger.error "Ignoring poison message:\n#{message.inspect}"
        HornetQ::logger.error boom.backtrace.join("\n")
      rescue StandardError => bang
        HornetQ::logger.error "Unhandled Exception processing Message. Doesn't compile: " + bang
        HornetQ::logger.error "Ignoring poison message:\n#{message.inspect}"
        HornetQ::logger.error boom.backtrace.join("\n")
      rescue => exc
        HornetQ::logger.error "Unhandled Exception processing Message. Exception occurred:\n#{exc}"
        HornetQ::logger.error "Ignoring poison message:\n#{message.inspect}"
        HornetQ::logger.error exc.backtrace.join("\n")
      end
    end

    # Return Statistics gathered for this listener
    # Note: These statistics are only useful if the queue is pre-loaded with messages
    #       since the timer start immediately and stops on the last message received
    def statistics
      raise "First call Consumer::on_message with :statistics=>true before calling MessageConsumer::statistics()" unless @message_count
      duration =(@last_time || Time.now) - @start_time
      {
        :count => @message_count,
        :duration => duration,
        :messages_per_second => (@message_count/duration).to_i
      }
    end
  end
end