# Consumer Class

# For the HornetQ Java documentation for this class see:
#  http://hornetq.sourceforge.net/docs/hornetq-2.1.0.Final/api/index.html?org/hornetq/api/core/client/ClientConsumer.html
#
# Other methods still directly accessible through this class:
#
# void   close()
#          Closes the consumer
#
# boolean   closed?
#          Returns whether the consumer is closed or not
#
# Note: receive can be used directly, but it is recommended to use #each where possible
#
# ClientMessage   receive()
#          Receives a message from a queue
#          Wait forever until a message is received
# ClientMessage   receive(long timeout)
#          Receives a message from a queue
#          Returns nil if no message was received after timeout milliseconds
# ClientMessage   receive_immediate()
#          Receives a message from a queue
#          Return immediately if no message is available on the queue
#          Returns nil if no message available
#
class Java::org.hornetq.core.client.impl::ClientConsumerImpl

  # For each message available to be consumed call the block supplied
  #
  # Returns the statistics gathered when :statistics => true, otherwise nil
  #
  # Parameters:
  #   :timeout How to timeout waiting for messages
  #     -1 : Wait forever
  #      0 : Return immediately if no message is available (default)
  #      x : Wait for x milli-seconds for a message to be received from the server
  #           Note: Messages may still be on the queue, but the server has not supplied any messages
  #                 in the time interval specified
  #      Default: 0
  #
  #   :statistics Capture statistics on how many messages have been read
  #      true  : This method will capture statistics on the number of messages received
  #              and the time it took to process them.
  #              Statistics are cumulative between calls to ::each and will only be
  #              reset when ::each is called again with :statistics => true
  def each(params={}, &proc)
    raise "Consumer::each requires a code block to be executed for each message received" unless proc

    message_count = nil
    start_time = nil
    timeout = (params[:timeout] || 0).to_i

    if params[:statistics]
      message_count = 0
      start_time = Time.now
    end

    # Receive messages according to timeout
    while message = receive_with_timeout(timeout) do
      proc.call(message)
      message_count += 1 if message_count
    end

    unless message_count.nil?
      duration = Time.now - start_time
      { :count => message_count,
        :duration => duration,
        :messages_per_second => (message_count/duration).to_i}
    end
  end

  # Receive messages in a separate thread when they arrive
  # Allows messages to be received in a separate thread. I.e. Asynchronously
  # This method will return to the caller before messages are processed.
  # It is then the callers responsibility to keep the program active so that messages
  # can then be processed.
  #
  # Parameters:
  #   :statistics Capture statistics on how many messages have been read
  #      true  : This method will capture statistics on the number of messages received
  #              and the time it took to process them.
  #              The timer starts when each() is called and finishes when either the last message was received,
  #              or when Destination::statistics is called. In this case MessageConsumer::statistics
  #              can be called several times during processing without affecting the end time.
  #              Also, the start time and message count is not reset until MessageConsumer::each
  #              is called again with :statistics => true
  #
  #              The statistics gathered are returned when :statistics => true and :async => false
  #
  def on_message(params={}, &proc)
    raise "Consumer::on_message requires a code block to be executed for each message received" unless proc

    @listener = HornetQ::Client::MessageHandler.new(params, &proc)
    setMessageHandler @listener
  end

  # Return the current statistics for a running ::on_message
  def on_message_statistics
    stats = @listener.statistics if @listener
    raise "First call Consumer::on_message with :statistics=>true before calling Consumer::statistics()" unless stats
    stats
  end

  private
  def receive_with_timeout(timeout)
    if timeout == -1
      self.receive
    elsif timeout == 0
      self.receive_immediate
    else
      self.receive(timeout)
    end
  end
end