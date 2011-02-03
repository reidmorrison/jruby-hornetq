# Add methods to Session Interface
# For more information on methods, see:
# http://hornetq.sourceforge.net/docs/hornetq-2.1.0.Final/api/index.html?org/hornetq/api/core/client/ClientSession.html
module Java::org.hornetq.api.core.client::ClientSession
  
  # Document Methods from Java Docs:
  # create_queue(address, queue_name, durable?)

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
  #   session.consumer(:queue_name => 'my_queue', :browse_only => true) do |consumer|
  #     msg = consumer.receive_immediate
  #     p msg
  #     msg.acknowledge
  #   end
  def consumer(params={}, &block)
    queue_name = params.kind_of?(Hash) ? params[:queue_name] : params
    raise("Missing mandatory parameter :queue_name") unless queue_name
    
    consumer = nil
    begin
      consumer = if params[:max_rate] || params[:window_size]
        self.create_consumer(
          queue_name, 
          params[:filter], 
          params[:window_size],
          params[:max_rate],
          params[:browse_only].nil? ? false : params[:browse_only])
      else
        self.create_consumer(
          queue_name, 
          params[:filter], 
          params[:browse_only].nil? ? false : params[:browse_only])
      end
      block.call(consumer)
    ensure
      consumer.close if consumer
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
  def create_requestor(request_address)
    #Java::org.hornetq.api.core.client::ClientRequestor.new(self, request_address);
    HornetQ::Client::RequestorPattern.new(self, request_address)
  end
  
  # Creates a RequestorPattern to send a request and to synchronously wait for
  # the reply, call the supplied block, then close the requestor
  # Returns the result from the block
  def requestor(request_address)
    requestor = nil
    begin
      requestor = self.create_requestor(request_address)
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
    server = nil
    begin
      server = self.create_server(input_queue, timeout)
      block.call(server)
    ensure
      server.close if server
    end
  end
  
end

