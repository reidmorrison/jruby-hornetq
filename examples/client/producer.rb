#
# HornetQ Producer:
#          Write messages to the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

HornetQ::Client::Factory.create_session(:connector=> {:uri => 'hornetq://localhost'}) do |session|
  # Create Producer so that we can send messages to the Address 'jms.queue.ExampleQueue'
  producer = session.create_producer('jms.queue.ExampleQueue')
  
  # Create a non-durable message to send
  message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
  message << "#{Time.now}: ### Hello, World ###"
  
  producer.send(message)
end
