# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rubygems'
require 'resque/job_with_status' # in rails you would probably do this in an initializer
require 'yaml'
require 'hornetq'
require 'sync'

# The Batch Client Pattern submits requests to a server following the Server Pattern
#
# A good example of when to use the Batch Client Pattern is when processing large
# batch files. Rather than just flood the queue with every record from a file
# the Batch Client Pattern can be used to only send out a batch of requests at
# a time and when sufficient responses have been received, send another batch.
#
# The following additional features can be implemented in this pattern
# * Stop the batch if say 80% of records fail in the first batch, etc.
# * Support pause and resume of batch processing
# * Support restart and recoverability
#
# See the Resque example for implementations of some of the above capabilities
#
class BatchClientPattern
  def initialize(session, request_address)
    @producer = session.create_producer(request_address)
    reply_queue = "#{request_address}.#{Java::java.util::UUID.randomUUID.toString}"
    begin
      session.create_temporary_queue(reply_queue, reply_queue)
    rescue NativeException => exc
      p exc
    end
    @consumer = session.create_consumer(reply_queue)
    @session = session
    session.start

    @counter_sync = Sync.new
    @processed = 0
  end

  # Before re-using a batch pattern, reset all internal counters
  def reset
    @counter_sync.synchronize(:EX) do
      @failed    = 0
      @sucessful = 0
    end
  end

  # Return the current message count
  def processed
    @counter_sync.synchronize(:SH) { @sucessful + @processed }
  end

  # Increment Successful response counter by supplied count
  def inc_sucessful(count=1)
    @counter_sync.synchronize(:EX) { @sucessful += count }
  end

  # Return the current message count
  def sucessful
    @counter_sync.synchronize(:SH) { @sucessful }
  end

  # Increment Successful response counter by supplied count
  def inc_failed(count=1)
    @counter_sync.synchronize(:EX) { @failed += count }
  end

  # Return the current message count
  def failed
    @counter_sync.synchronize(:SH) { @failed }
  end

  # Send x messages
  def send(total_count)
    #print "Sending #{total_count} messages"
    start_time = Time.now
    total_count.times do |i|
      message = @session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
      message.reply_to_address = @consumer.queue_name
      message.body = "Request Current Time. #{i}"
      @producer.send(message)
      print "."
      #puts "Sent:#{message}"
    end
    duration = Time.now - start_time
    #printf "\nSend %5d msg, %5.2f s, %10.2f msg/s\n", total_count, duration, total_count/duration
  end

  # Receive Reply messages calling the supplied block for each message
  # passing in the message received from the server.
  # After the block returns, the message is automatically acknowledged
  def receive(&block)
    print "Receiving messages"
    raise "Missing mandatory block" unless block
    begin
      while reply = @consumer.receive
        block.call(reply)
        reply.acknowledge
      end
    rescue Exception => exc
      p exc
    end
  end

  def close
    @producer.close
    @consumer.close
    @session.delete_queue(@consumer.queue_name)
  end
end

# sleeps for _length_ seconds updating the status every second
#
#
# Create a Resque Job with the ability to report status
#
class HornetQJob < Resque::JobWithStatus

  # Set the name of the queue to use for this Job Worker
  @queue = "hornetq_job"

  # Must be an instance method for Resque::JobWithStatus
  def perform
    total_count    = (options['total_count'] || 4000).to_i
    batching_size  = (options['batching_size'] || 80).to_i
    address        = options['address'] || 'processor'
    receive_thread = nil

    # Create a HornetQ session
    count = 0
    HornetQ::Client::Connection.session('hornetq://localhost') do |session|
      batching_size = total_count if batching_size > total_count

      client = BatchClient.new(session, address)

      # Start receive thread
      receive_thread = Thread.new do
        client.receive do |message|
          print '@'
          client.inc_sucessful
        end
      end

      times = (total_count/batching_size).to_i
      puts "Performing #{times} loops"
      times.times do |i|
        at(count, total_count, "At #{count} of #{total_count}")
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
    receive_thread.kill if receive_thread
    completed('num' => total_count, 'description' => "Completed #{count} of #{total_count}")
  end

end

# Submit a new request at the command line
if __FILE__ == $0
  # Make sure you have a worker running
  # jruby resque_worker.rb

  options = {
    'total_count' => (ARGV[0] || 4000).to_i,
    'batching_size' => (ARGV[1] || 40).to_i,
    'address' => 'processor'
  }
  # running the job
  puts "Creating the HornetQJob"
  job_id = HornetQJob.create(options)
  puts "Got back #{job_id}"

  # check the status until its complete
  while status = Resque::Status.get(job_id) and !status.completed? && !status.failed? &&!status.killed?
    sleep 1
    puts status.inspect
  end
  puts status.inspect
end