#
# HornetQ In VM Producer and consumer:
#   Example of how to produce and consume messages with the same Java VM
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Create and start an InVM HornetQ server instance
server = HornetQ::Server::Factory.create_server('hornetq://invm')
server.enable_shutdown_on_signal
server.start

HornetQ::Client::Factory.start(:connector=> {:uri => 'hornetq://invm'}) do |session|
  producer = session.create_producer('jms.queue.ExampleQueue')
  consumer = session.create_consumer('jms.queue.ExampleQueue')
  
  # Create a non-durable message to send
  message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
  message << "#{Time.now}: ### Hello, World ###"
  
  producer.send(message)
  
  
  # Receive a single message, return immediately if no message available
  if message = consumer.receive_immediate
    puts "Received:[#{message.body}]"
    message.acknowledge
  else
    puts "No message found"
  end
end
