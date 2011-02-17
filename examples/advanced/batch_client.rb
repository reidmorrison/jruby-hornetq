#
# HornetQ Batch Requestor:
#      Submit a batch of requests and wait for replies
#
# This is an advanced use case where the client submits requests in a controlled
# fashion. The alternative would be just to submit all requests at the same time,
# however then it becomes extremely difficult to pull back submitted requests
# if say 80% of the first say 100 requests fail.
#
# This sample sends a total of 100 requests in batches of 10.
# One thread sends requests and the other processes replies.
# Once 80% of the replies are back, it will send the next batch

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'
require 'sync'

total_count = (ARGV[0] || 100).to_i
batching_size = (ARGV[1] || 10).to_i

request_address = 'ServerAddress'
config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

class BatchClientPattern
  def initialize(connection, request_address)
    @session = connection.create_session
    @producer = @session.create_producer(request_address)
    @reply_queue = "#{request_address}.#{Java::java.util::UUID.randomUUID.toString}"
    @session.create_temporary_queue(@reply_queue, @reply_queue)
    @counter_sync = Sync.new
    @counter = 0
    
    # Start consuming replies
    connection.on_message(:queue_name => @reply_queue) {|message| process_reply(message) }
  end
  
  # Increment Message Counter
  def inc_counter(total_count=1)
    @counter_sync.synchronize(:EX) { @counter += total_count }
  end

  # Decrement Message counter
  def dec_counter(total_count=1)
    @counter_sync.synchronize(:EX) { @counter -= total_count }
  end
  
  # Return the current message count
  def counter
    @counter_sync.synchronize(:SH) { @counter }
  end
  
  # Send x messages
  def send(total_count)
    #print "Sending #{total_count} messages"
    start_time = Time.now
    total_count.times do |i|
      message = @session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
      message.reply_to_queue_name = @reply_queue
      message.body = "Request Current Time. #{i}"
      @producer.send(message)
      print "."
      #puts "Sent:#{message}"
    end
    duration = Time.now - start_time
    #printf "\nSend %5d msg, %5.2f s, %10.2f msg/s\n", total_count, duration, total_count/duration
  end
  
  # Receive Reply messages
  def process_reply(message)
    print '@'
    inc_counter(1)
    message.acknowledge
  end
  
  def close
    @producer.close
    @session.close
  end
end

# Create a HornetQ session
HornetQ::Client::Connection.connection(config[:connection]) do |connection|
  batching_size = total_count if batching_size > total_count
  
  client = BatchClientPattern.new(connection, request_address)
  
  times = (total_count/batching_size).to_i
  puts "Performing #{times} loops"
  count = 0
  times.times do |i|
    client.send(batching_size)
    count += batching_size
    # Wait for at least 80% of responses
    loop do
      #puts "Waiting for receive"
      sleep 0.1
      received_count = client.counter
      #puts "\nReceived #{received_count} messages"
      if received_count >= 0.8 * count
        puts ""
        break 
      end
    end
  end
  
  while client.counter < total_count
    sleep 0.1
    print "*"
  end
  client.close
end
