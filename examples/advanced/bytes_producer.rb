#
# HornetQ Producer:
#          Write binary/bytes messages to the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

HornetQ::Client::Connection.session('hornetq://localhost') do |session|
  # Create the non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)

  # Create Producer so that we can send messages to the Address 'jms.queue.ExampleQueue'
  session.producer('TestAddress') do |producer|

    # Create a non-durable bytes message to send
    message = session.create_message(HornetQ::Client::Message::BYTES_TYPE,false)
    message.body = "#{Time.now}: ### Hello, World ###"

    producer.send(message)
  end
end
