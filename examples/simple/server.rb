#
# HornetQ Consumer:
#      Reply to a request
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

timeout = (ARGV[0] || 60000).to_i

HornetQ::Client::Factory.start(:connector=> {:uri => 'hornetq://localhost'}) do |session|
  server = session.create_server('jms.queue.ExampleQueue', timeout)

  puts "Waiting for Requests..."  
  server.run do |request_message|
    puts "Received:[#{request_message.body}]"
    
    # Create Reply Message
    reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
    reply_message.body = "Echo [#{request_message.body}]"
    
    # The result of the block is the message to be sent back
    reply_message
  end

  # Server will stop after timeout period after no messages received. Set to 0 to wait foreve
  server.close
end
