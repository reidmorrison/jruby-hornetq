# For each thread that will be processing messages concurrently a separate
# session is required.
#
# Interface org.hornetq.api.core.client.ClientSession
#
# See: http://hornetq.sourceforge.net/docs/hornetq-2.1.0.Final/api/index.html?org/hornetq/api/core/client/ClientSession.html
#
# Other methods still directly accessible through this class:
#
# add_failure_listener(SessionFailureListener listener)
#   Adds a FailureListener to the session which is notified if a failure occurs on the session
#
# binding_query(SimpleString address)
#  Queries information on a binding
#
# close()
#  Closes this session
#
# commit()
#   Commits the current transaction
#
# ClientMessage   create_message(boolean durable)
#          Creates a ClientMessage.
# ClientMessage   create_message(byte type, boolean durable)
#          Creates a ClientMessage.
# ClientMessage   create_message(byte type, boolean durable, long expiration, long timestamp, byte priority)
#          Creates a ClientMessage.
#
# ClientProducer   create_producer()
#          Creates a producer with no default address.
# ClientProducer   create_producer(SimpleString address)
#          Creates a producer which sends messages to the given address
# ClientProducer   create_producer(SimpleString address, int rate)
#          Creates a producer which sends messages to the given address
# ClientProducer   create_producer(String address)
#          Creates a producer which sends messages to the given address
#
# void   create_queue(String address, String queueName)
#          Creates a non-temporary queue non-durable queue.
# void   create_queue(String address, String queueName, boolean durable)
#          Creates a non-temporary queue.
# void   create_queue(String address, String queueName, String filter, boolean durable)
#          Creates a non-temporaryqueue.
#
# void   create_temporary_queue(String address, String queueName)
#          Creates a temporary queue.
# void   create_temporary_queue(String address, String queueName, String filter)
#          Creates a temporary queue with a filter.
#
# void   delete_queue(String queueName)
#          Deletes the queue.
# int   version()
#          Returns the server's incrementingVersion.
#
# XAResource   xa_resource()
#          Returns the XAResource associated to the session.
#
# auto_commit_acks?
#          Returns whether the session will automatically commit its transaction every time a message is acknowledged by a ClientConsumer created by this session, false else
# auto_commit_sends?
#          Returns whether the session will automatically commit its transaction every time a message is sent by a ClientProducer created by this session, false else
# block_on_acknowledge?
#          Returns whether the ClientConsumer created by the session will block when they acknowledge a message
# closed?
#          Returns whether the session is closed or not.
# rollback_only?
#          Returns true if the current transaction has been flagged to rollback, false else
# xa?
#          Return true if the session supports XA, false else
#
# ClientSession.QueueQuery   queue_query(SimpleString queueName)
#          Queries information on a queue
#
# boolean   removeFailureListener(SessionFailureListener listener)
#          Removes a FailureListener to the session
#
# void   rollback()
#          Rolls back the current transaction
# void   rollback(boolean considerLastMessageAsDelivered)
#          Rolls back the current transaction
#
# void   set_send_acknowledgement_handler(SendAcknowledgementHandler handler)
#          Sets a SendAcknowledgementHandler for this session
#
# void   start()
#          Starts the session
# void   stop()
#          Stops the session

module Java::org.hornetq.api.core.client::ClientSession

  # Creates a ClientConsumer to consume or browse messages matching the filter
  # from the queue with the given name, calls the supplied block, then close the
  # consumer
  #
  # If the parameter is a String, then it must be the queue name to consume
  # messages from. Otherwise, the parameters can be supplied in a Hash
  #
  # The parameters for creating the consumer are as follows:
  #   :queue_name  => The name of the queue to consume messages from. Mandatory
  #   :filter      => Only consume messages matching the filter: Default: nil
  #   :browse_only => Whether to just browse the queue or consume messages
  #                   true | false. Default: false
  #   :window_size => The consumer window size.
  #   :max_rate    => The maximum rate to consume messages.
  #
  #   Note: If either :window_size or :max_rate is supplied, then BOTH are required
  #
  # Returns the result from the block
  #
  # Example
  #   session.consumer('my_queue') do |consumer|
  #     msg = consumer.receive_immediate
  #     p msg
  #     msg.acknowledge
  #   end
  #
  # Example
  #   # Just browse the messages without consuming them
  #   session.consumer(:queue_name => ##'my_queue', :browse_only => true) do |consumer|
  #     msg = consumer.receive_immediate
  #     p msg
  #     msg.acknowledge
  #   end
  def consumer(params={}, &block)
    raise "Missing mandatory code block" unless block
    consumer = nil
    begin
      consumer = create_consumer_from_params(params)
      block.call(consumer)
    ensure
      consumer.close if consumer
    end
  end

  # Consume or browse all messages matching the filter from the queue with the
  # given name, calls the supplied block for every message received from the
  # queue. Once the timeout has been reached it closes the consumer
  #
  # Parameters:
  #   :timeout How to timeout waiting for messages
  #     -1 : Wait forever
  #      0 : Return immediately if no message is available (default)
  #      x : Wait for x milli-seconds for a message to be received from the server
  #           Note: Messages may still be on the queue, but the server has not supplied any messages
  #                 in the time interval specified
  #      Default: 0
  #   :queue_name  => The name of the queue to consume messages from. Mandatory
  #   :filter      => Only consume messages matching the filter: Default: nil
  #   :browse_only => Whether to just browse the queue or consume messages
  #                   true | false. Default: false
  #   :window_size => The consumer window size.
  #   :max_rate    => The maximum rate to consume messages.
  #
  #   :statistics Capture statistics on how many messages have been read
  #      true  : This method will capture statistics on the number of messages received
  #              and the time it took to process them.
  #              Statistics are cumulative between calls to ::each and will only be
  #              reset when ::each is called again with :statistics => true
  #
  #   Note: If either :window_size or :max_rate is supplied, then BOTH are required
  #
  # Returns the statistics gathered when :statistics => true, otherwise nil
  #
  # Example
  #   session.consume(:queue_name => 'my_queue', :timeout => 1000) do |message|
  #     p message
  #     message.acknowledge
  #   end
  #
  # Example
  #   # Just browse the messages without consuming them
  #   session.consume(:queue_name => 'my_queue', :timeout => 1000, :browse_only => true) do |message|
  #     p message
  #     message.acknowledge
  #   end
  def consume(params, &block)
    raise "Missing mandatory code block" unless block
    c = self.create_consumer_from_params(params)
    begin
      c.each(params, &block)
    ensure
      c.close
    end
  end

  # Create a consumer using named parameters. The following Java create_consumer
  # methods are still directly accessible:
  #   create_consumer(String queueName)
  #          Creates a ClientConsumer to consume messages from the queue with the given name
  #   create_consumer(String queueName, boolean browseOnly)
  #          Creates a ClientConsumer to consume or browse messages from the queue with the given name.
  #   create_consumer(String queueName, String filter)
  #          Creates a ClientConsumer to consume messages matching the filter from the queue with the given name.
  #   create_consumer(String queueName, String filter, boolean browseOnly)
  #          Creates a ClientConsumer to consume or browse messages matching the filter from the queue with the given name.
  #   create_consumer(String queueName, String filter, int windowSize, int maxRate, boolean browseOnly)
  #          Creates a ClientConsumer to consume or browse messages matching the filter from the queue with the given name.
  #
  # The parameters for creating the consumer are as follows:
  #   :queue_name  => The name of the queue to consume messages from. Mandatory
  #   :filter      => Only consume messages matching the filter: Default: nil
  #   :browse_only => Whether to just browse the queue or consume messages
  #                   true | false. Default: false
  #   :window_size => The consumer window size.
  #   :max_rate    => The maximum rate to consume messages.
  #
  #   Note: If either :window_size or :max_rate is supplied, then BOTH are required
  #
  # Returns a new Consumer that can be used for consuming messages from
  # the queue
  def create_consumer_from_params(params={})
    if params.kind_of?(Hash)
      raise("Missing mandatory parameter :queue_name") unless queue_name = params[:queue_name]

      if params[:max_rate] || params[:window_size]
        self.create_consumer(
          queue_name,
          params[:filter],
          params[:window_size],
          params[:max_rate],
          params.fetch(:browse_only, false))
      else
        self.create_consumer(
          queue_name,
          params[:filter],
          params.fetch(:browse_only, false))
      end
    else
      self.create_consumer(params)
    end
  end

  # Creates a ClientProducer to send messages, calls the supplied block,
  # then close the consumer
  #
  # If the parameter is a String, then it must be the address to send messages to
  # Otherwise, the parameters can be supplied in a Hash
  #
  # The parameters for creating the consumer are as follows:
  #   :address     => The address to which to send messages. If not supplied here,
  #                   then the destination address must be supplied with every message
  #   :rate        => The producer rate
  #
  # Returns the result from the block
  #
  # Example
  #   session.producer('MyAddress') do |producer|
  #     msg = session.create_message
  #     msg.type = :text
  #     producer.send(msg)
  #   end
  #
  # Example
  #   # Send to a different address with each message
  #   session.producer do |producer|
  #     msg = session.create_message
  #     msg.type = :text
  #     producer.send('Another address', msg)
  #   end
  def producer(params=nil, &block)
    address = nil
    rate = nil
    if params.kind_of?(Hash)
      address = params[:address]
      rate = params[:rate]
    else
      address = params
    end

    producer = nil
    begin
      producer = if rate
        self.create_producer(address, rate)
      elsif address
        self.create_producer(address)
      else
        self.create_producer
      end
      block.call(producer)
    ensure
      producer.close if producer
    end
  end

  # To be consistent create Requestor from Session
  def create_requestor(request_address, reply_address=nil, reply_queue=nil)
    HornetQ::Client::RequestorPattern.new(self, request_address, reply_address, reply_queue)
  end

  # Creates a RequestorPattern to send a request and to synchronously wait for
  # the reply, call the supplied block, then close the requestor
  # Returns the result from the block
  def requestor(request_address, reply_address=nil, reply_queue=nil, &block)
    begin
      requestor = self.create_requestor(request_address, reply_address, reply_queue)
      block.call(requestor)
    ensure
      requestor.close if requestor
    end
  end

  # Create a server handler for receiving requests and responding with
  # replies to the supplied address
  def create_server(input_queue, timeout=0)
    HornetQ::Client::ServerPattern.new(self, input_queue, timeout)
  end

  # Creates a ServerPattern to send messages to consume messages and send
  # replies, call the supplied block, then close the server
  # Returns the result from the block
  def server(input_queue, timeout=0, &block)
    begin
      server = self.create_server(input_queue, timeout)
      block.call(server)
    ensure
      server.close if server
    end
  end

  # Create a queue if it doesn't already exist
  def create_queue_ignore_exists(address, queue, durable)
    begin
      create_queue(address, queue, durable)
    rescue Java::org.hornetq.api.core.HornetQException => e
      raise unless e.cause.code == Java::org.hornetq.api.core.HornetQException::QUEUE_EXISTS
    end
  end

end

