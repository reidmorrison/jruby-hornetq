#
# HornetQ Consumer:
#      Reply to a request
#      Implements the Server Pattern
#      The reply message is sent back to the reply to address supplied by the
#      requestor
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# By default the server will shutdown after 60 seconds, set to 0 to never shutdown
timeout = (ARGV[0] || 60000).to_i

HornetQ::Client::Connection.start_session(:connection=> {:uri => 'hornetq://localhost'}) do |session|
  # Create a non-durable ServerQueue to receive messages sent to the ServerAddress
  session.create_queue_ignore_exists('ServerAddress', 'ServerQueue', false)

  session.server('ServerQueue', timeout) do |server|
    puts "Waiting for Requests..."
    server.run do |request_message|
      puts "Received:[#{request_message.inspect}]"

      # Create Reply Message
      reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
      reply_message.body = "Echo [#{request_message.body}]"

      # The result of this block is the message to be sent back to the requestor (client)
      # Or, nil if no response should be sent back
      reply_message
    end
  end

end
