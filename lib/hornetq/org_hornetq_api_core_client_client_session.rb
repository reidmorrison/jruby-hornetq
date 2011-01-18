# Add methods to Session Interface
module Java::org.hornetq.api.core.client::ClientSession
  
  # To be consistent create Requestor from Session
  def create_requestor(request_address)
    #Java::org.hornetq.api.core.client::ClientRequestor.new(self, request_address);
    HornetQClient::ClientRequestor.new(self, request_address)
  end
  
  # Create a server handler for receiving requests and responding with
  # replies to the supplied address
  def create_server(input_queue, timeout=0)
    HornetQClient::ClientServer.new(self, input_queue, timeout)
  end
end

