# Add methods to Session Interface
module Java::org.hornetq.api.core.client::ClientSession
  
  # To be consistent create Requestor from Session
  def create_requestor(request_address)
    #Java::org.hornetq.api.core.client::ClientRequestor.new(self, request_address);
    HornetQ::Client::Requestor.new(self, request_address)
  end
  
  # Create a server handler for receiving requests and responding with
  # replies to the supplied address
  def create_server(input_queue, timeout=0)
    HornetQ::Client::Server.new(self, input_queue, timeout)
  end

  def create_queue_ignore_exists(address, queue, durable)
    begin
      create_queue(address, queue, durable)
    rescue Java::org.hornetq.api.core.HornetQException => e
      raise unless e.cause.code == Java::org.hornetq.api.core.HornetQException::QUEUE_EXISTS
    end
  end
end

