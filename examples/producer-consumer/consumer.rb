#
# HornetQ Consumer:
#          Read a single message from the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Using Connect.start since a session must be started in order to consume messages
HornetQ::Client::Connection.start_session('hornetq://localhost') do |session|

  # Create the non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)

  session.consumer('TestQueue') do |consumer|
    # Receive a single message, return immediately if no message available
    if message = consumer.receive_immediate
      puts "Received:[#{message.body}]"
      message.acknowledge
    else
      puts "No message found"
    end
  end
end
