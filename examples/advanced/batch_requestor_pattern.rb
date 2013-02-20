#
# HornetQ Batch Requestor Pattern:
#      Submit a batch of requests and wait for replies
#
# This is an advanced use case where the client submits requests in a controlled
# fashion. The alternative would be just to submit all requests at the same time,
# however then it becomes extremely difficult to pull back submitted requests
# if say 80% of the first say 100 requests fail.
#
# This sample sends a total of 100 requests in batches of 10.
# One thread sends requests and the other processes replies.
# Once 80% of the replies are back, it will send the next batch
#
# Maybe one day this pattern can make it out of examples and into the product :)
#
require 'sync'

class BatchRequestorPattern

  attr_accessor :batch_size, :window_size, :completion_ratio
  attr_reader :reply_address, :reply_count, :send_count

  #
  # Returns a new BatchRequestorPattern
  #
  # Parameters:
  # * connection: The HornetQ connection. Used for creating sessions for the
  #               pattern to run
  # * server_address: The address to send requests to
  # * An optional block can be passed in that will be called with every reply
  #   It can be used to perform specialized handling such as:
  # ** Aborting a batch process
  # ** Moving the response to another queue for re-queuing later
  #
  # Implementation:
  #
  # Creates a temporary reply to queue for receiving responses from the server
  #   Consists of the server_address following by a '.' and a UUID
  #
  # Uses Connection#on_message to process replies in a separate thread
  #
  # If the connection is started, it will start consuming replies immediately,
  # otherwise it will only start processing replies once the connection has
  # been started.
  #
  # Sending of messages should be done by only one thread at a time since
  # this pattern shares the same session and producer for sending messages
  #
  # Parameters
  # * :connection Connection to create session and response queue with
  # * :server_address Address to send requests to
  # * :completion_ratio Percentage of responses to wait for before sending
  #                     further requests
  #                     Must be a number between 0 and 1 inclusive
  #                     Default: 0.8
  #
  def initialize(params, &reply_block)
    params            = params.dup
    connection        = params.delete(:connection)
    server_address    = params.delete(:server_address)
    @completion_ratio = params.delete(:completion_ratio).to_f

    raise "Invalid :completion_ratio of #{@completion_ratio}. Must be between 0 and 1 inclusive" unless @completion_ratio.between?(0,1)

    @session = connection.create_session
    @producer = @session.create_producer(server_address)
    @reply_address = "#{server_address}.#{Java::java.util::UUID.randomUUID.toString}"
    @session.create_temporary_queue(@reply_address, @reply_address)
    @reply_count_sync = Sync.new
    @reply_count = 0
    @send_count = 0
    @reply_block = reply_block

    # Start consuming replies. The Address and Queue names are the same
    connection.on_message(:queue_name => @reply_address) {|message| process_reply(message) }
  end

  # Return the current message count
  def reply_count
    @reply_count_sync.synchronize(:SH) { @reply_count }
  end

  # Send a message to the server, setting the reply to address to the temporary
  # address created by this pattern
  #
  # Sending of messages should be done by only one thread at a time since
  # this pattern shares the same session and producer for sending messages
  #
  # Returns the total number of messages sent so far in this batch
  def send(message)
    message.reply_to_address = @reply_address
    @producer.send(message)
    @send_count += 1
  end

  # Retry Sending a message to the server, setting the reply to address to the
  # temporary address created by this pattern
  #
  # Only call this method when a reply is received and we want to resend a
  # previous request
  #
  # Note: This method will decrement the number of messages received by 1
  #       and will Not increment the number of messages sent, since it is
  #       considered to have already been sent
  #
  # ReSending and Sending of messages should be done by only one thread at a time since
  # this pattern shares the same session and producer for sending messages
  # #TODO Should we rather just add a Sync around the producer?
  #       What if a resend is being done in the reply handler?
  #
  # Returns the total number of messages sent so far in this batch
  def resend(message)
    message.reply_to_address = @reply_address

    # Decrement Reply Message counter
    @reply_count_sync.synchronize(:EX) { @reply_count -= 1 }
    @producer.send(message)
  end

  # Receive Reply messages, calling the supplied reply handler block to support
  # custom error handling
  #
  # Returns result of reply block supplied to constructor
  def process_reply(message)
    # Increment reply message counter
    @reply_count_sync.synchronize(:EX) { @reply_count += 1 }

    result = @reply_block.call(message) if @reply_block
    message.acknowledge
    result
  end

  # Release resources used by this pattern
  def close
    @producer.close
    @session.close
  end

  # Wait for replies from server until the required number of responses has been
  # received based on the completion ratio
  #
  # For example a completion ration of 0.8 will wait for at least 80% of replies
  # to be received. So if 10 requests were sent this method would only return
  # once 8 or more replies have been received
  #
  # #TODO Need a Timeout here
  def wait_for_outstanding_replies
    while self.reply_count >= self.completion_ratio * self.send_count
      sleep 0.1
    end
  end

  # Wait for replies from server until the required number of responses has been
  # received based on the completion ratio
  #
  # #TODO Need a Timeout here
  def wait_for_all_outstanding_replies
    while self.reply_count >= self.send_count
      sleep 0.1
    end
  end

end
