#
# Processor:
#    Process requests submitted by Resque Worker and reply
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Let server shutdown on its own after 5 minutes of inactivity. Set to 0 to wait forever
timeout = (ARGV[0] || 300000).to_i

q_name = 'processor'

HornetQ::Client::Connection.start_session('hornetq://localhost') do |session|
  begin
    # Create durable queue with matching address
    session.create_queue(q_name, q_name, true)
  rescue
    # Ignore when queue already exists
  end

  server = session.create_server(q_name, timeout)

  puts "Waiting for Requests..."
  server.run do |request_message|
    print "."

    # Create Reply Message
    reply_message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, false)
    reply_message.body = "Echo [#{request_message.body}]"

    # The result of the block is the message to be sent back, or nil if no reply
    reply_message
  end

  # Server will stop after timeout period after no messages received. Set to 0 to wait forever
  server.close
end
