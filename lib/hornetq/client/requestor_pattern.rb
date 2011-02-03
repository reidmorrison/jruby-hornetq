module HornetQ::Client

  # Implements the Requestor Pattern 
  #   Send a request to a server and wait for a reply  
  class RequestorPattern
    def initialize(session, request_address)
      @session = session
      @producer = session.create_producer(request_address)
      reply_queue = "#{request_address}.#{Java::java.util::UUID.randomUUID.toString}"
      begin
        session.create_temporary_queue(reply_queue, reply_queue)
      rescue NativeException => exc
        p exc
      end
      @consumer = session.create_consumer(reply_queue)
    end
  
    def request(request_message, timeout)
      request_message.putStringProperty(Java::OrgHornetqCoreClientImpl::ClientMessageImpl::REPLYTO_HEADER_NAME, @consumer.queue_name);
      @producer.send(request_message)
      @consumer.receive(timeout)
    end
    
    def close
      @producer.close if @producer
      @consumer.close if @consumer
      @session.delete_queue(@consumer.queue_name)
    end
  end
  
end