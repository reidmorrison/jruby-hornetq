#
# HornetQ Producer:
#          Write messages to the queue
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'hornetq'

# Using Connect.session since a session does not have to be started in order
# to produce messages
HornetQ::Client::Connection.session('hornetq://localhost') do |session|
  # Create a non-durable TestQueue to receive messages sent to the TestAddress
  session.create_queue_ignore_exists('TestAddress', 'TestQueue', false)

  # Using the Producer pattern send messages to the Address 'TestAddress'
  session.producer('TestAddress') do |producer|
    # Create a non-durable message
    message = session.create_message(false)
    # Mark message as text
    message.type_sym = :text
    # Always set the message type prior to setting the body so that the message
    # is correctly created for you
    message.body = "#{Time.now}: ### Hello, World ###"

    producer.send(message)

    puts "Sent Message: #{message.inspect}"
  end
end
