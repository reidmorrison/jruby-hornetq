#
# HornetQ Consumer:
#          Read a single message from the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

HornetQ::Client::Connection.start(:connector=> {:uri => 'hornetq://localhost'}) do |session|
  consumer = session.create_consumer('jms.queue.ExampleQueue')
  
  # Receive a single message, return immediately if no message available
  if message = consumer.receive_immediate
    puts "Received:[#{message.body}]"
    message.acknowledge
  else
    puts "No message found"
  end
end
