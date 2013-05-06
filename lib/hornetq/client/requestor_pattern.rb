module HornetQ::Client

  # Implements the Requestor Pattern
  #   Send a request to a server and wait for a reply
  # Parameters
  # * session
  #   The session to use processing this request
  #   Note: Sessions cannot be shared concurrently by multiple threads
  # * request_address
  #   Address to send requests to.
  #   It is expected that process listening to requests at this address has
  #   implemented the ServerPattern
  # * reply_address
  #   If supplied the reply_address must already exist and will be used for
  #   receiving responses
  #   If not supplied a temporary queue will be created and used by this instance
  #   of the RequestorPattern
  #   This optional parameter is normally not used
  # * reply_queue
  #   If a reply_address is supplied, the reply_queue name can be supplied if it
  #   differs from reply_address
  class RequestorPattern
    def initialize(session, request_address, reply_address=nil, reply_queue=nil)
      @session = session
      @producer = session.create_producer(request_address)
      if reply_address
        @reply_address = reply_address
        @reply_queue = reply_queue || reply_address
        @destroy_temp_queue = false
      else
        @reply_queue = @reply_address = "#{request_address}.#{Java::java.util::UUID.randomUUID.toString}"
        begin
          session.create_temporary_queue(@reply_address, @reply_queue)
          @destroy_temp_queue = true
        rescue NativeException => exc
          p exc
        end
      end
    end

    # Synchronous Request and wait for reply
    #
    # Returns the message received, or nil if no message was received in the
    # specified timeout.
    #
    # The supplied request_message is updated as follows
    # * The property JMSReplyTo is set to the name of the reply to address
    # * Creates and sets the message user_id if not already set
    # * #TODO: The expiry is set to the message timeout if not already set
    #
    # Note:
    # * The request will only look for a reply message with the same
    #   user_id (message id) as the message that was sent. This is critical
    #   since a previous receive may have timed out and we do not want
    #   to pickup the reponse to an earlier request
    #
    # To receive a message after a timeout, call wait_for_reply with a nil message
    # id to receive any message on the queue
    #
    # Use: submit_request & then wait_for_reply to break it into
    #      two separate calls
    def request(request_message, timeout)
      #TODO set message expiry to timeout if not already set
      message_id = submit_request(request_message)
      wait_for_reply(message_id, timeout)
    end

    # Asynchronous Request
    #  Use: submit_request & then wait_for_reply to break the request into
    #       two separate calls.
    #
    # For example, submit the request now, do some work, then later on
    # in the same thread wait for the reply.
    #
    # The supplied request_message is updated as follows
    # * The property JMSReplyTo is set to the name of the reply to address
    # * Creates and sets the message user_id if not already set
    # * #TODO: The expiry is set to the message timeout if not already set
    #
    # Returns Message id of the message that was sent
    def submit_request(request_message)
      request_message.reply_to_address = @reply_address
      request_message.generate_user_id unless request_message.user_id
      @producer.send(request_message)
      request_message.user_id
    end

    # Asynchronous wait for reply
    #
    # Parameters:
    #   user_id: the user defined id to correlate a response for
    #
    # Supply a nil user_id to receive any message from the queue
    #
    # Returns the message received
    #
    # Note: Call submit_request before calling this method
    def wait_for_reply(user_id, timeout)
      # We only want the reply to the supplied message_id, so set filter on message id
      filter = "#{Java::org.hornetq.api.core::FilterConstants::HORNETQ_USERID} = 'ID:#{user_id}'" if user_id
      @session.consumer(:queue_name => @reply_queue, :filter=>filter) do |consumer|
        consumer.receive(timeout)
      end
    end

    def close
      @session.delete_queue(@reply_queue) if @destroy_temp_queue
      @producer.close if @producer
    end
  end

end