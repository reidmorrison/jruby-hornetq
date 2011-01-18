module HornetQClient
  # Create a Server for receiving requests and replying
  #   to arbitrary queues
  # Create an instance of this class per thread
  class ClientServer
    def initialize(session, request_queue, timeout)
      @session = session
      @consumer = session.create_consumer(request_queue)
      @producer = session.create_producer
      @timeout = timeout
    end
  
    def run(&block)
      while request_message = @consumer.receive(@timeout)
        # Block should return a message reply object, pass in request
        # TODO: ensure..
        reply_message = block.call(request_message)
      
        # Send a reply?
        reply(request_message, reply_message) if request_message.request?
        request_message.acknowledge
      end
    end

    # Send a reply to the received request message
    #   request: is the message received
    #   reply:   is the message to send to the client
    def reply(request_message, reply_message)
      if request_message.request?
        # Reply should have same durability as request
        reply_message.durable = request_message.durable?
        reply_to = request_message.getSimpleStringProperty(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME);
        # Send request message id back in reply message for correlation purposes
        reply_message.user_id = request_message.user_id
        @producer.send(reply_to, reply_message)
        #puts "Sent reply to #{reply_to.to_s}: #{reply_message.inspect}"
      end
      request_message.acknowledge
    end
  
    # Close out resources
    def close
      @consumer.close if @consumer
      @producer.close if @producer
    end
  end
end