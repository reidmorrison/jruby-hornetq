#
# HornetQ Requestor (Client):
#      Submit a request and wait for a reply
#      Uses the Requestor Pattern
#      The Server (server.rb) must be running first, otherwise this example
#      program will eventually timeout
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

timeout = (ARGV[0] || 5000).to_i

# Using Connect.start since a session must be started in order to consume messages
HornetQ::Client::Connection.start_session('hornetq://localhost') do |session|

  # Create a non-durable ServerQueue to receive messages sent to the ServerAddress
  session.create_queue_ignore_exists('ServerAddress', 'ServerQueue', false)

  # Use Requestor (Client) Pattern to do a "RPC like" call to a server
  # Under the covers the requestor creates a temporary dynamic reply to queue
  # for the server to send the reply message to
  session.requestor('ServerAddress') do |requestor|
    # Create non-durable message
    message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
    message.body = "Some request data"

    # Send message to the address
    puts "Send request message and wait for Reply"
    if reply = requestor.request(message, timeout)
      puts "Received Response: #{reply.inspect}"
    else
      puts "Time out, No reply received after #{timeout/1000} seconds"
    end

  end
end
