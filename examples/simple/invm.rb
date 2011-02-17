#
# HornetQ In VM Producer and consumer:
#   Example of how to produce and consume messages with the same Java VM
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Create and start an InVM HornetQ server instance
HornetQ::Server.start('hornetq://invm') do |server|
  # Allow a CTRL-C to stop this process
  server.enable_shutdown_on_signal

  HornetQ::Client::Connection.start_session('hornetq://invm') do |session|
    session.create_queue("MyAddress","MyQueue", nil, false)

    producer = session.create_producer('MyAddress')
    consumer = session.create_consumer('MyQueue')

    # Create a non-durable message to send
    message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
    message.body = "#{Time.now}: ### Hello, World ###"

    producer.send(message)

    # Receive a single message, return immediately if no message available
    if message = consumer.receive_immediate
      puts "Received:[#{message.body}]"
      message.acknowledge
    else
      puts "No message found"
    end
  end
end