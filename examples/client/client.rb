#
# HornetQ Requestor:
#      Submit a request and wait for a reply
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

timeout = (ARGV[0] || 5000).to_i

HornetQ::Client::Factory.start(:connector=> {:uri => 'hornetq://localhost'}) do |session|
  requestor = session.create_requestor('jms.queue.ExampleQueue')

  # Create non-durable message
  message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
  message.body = "Request Current Time"
  
  # Send message to the queue
  puts "Send request message and wait for Reply"
  if reply = requestor.request(message, timeout)
    puts "Received Response: #{reply.inspect}"
    puts "  Message: #{reply.body.inspect}"
  else
    puts "Time out, No reply received after #{timeout/1000} seconds"
  end
  
  requestor.close
end
