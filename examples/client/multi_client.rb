#
# HornetQ Requestor:
#      Multithreaded clients all doing requests
#      Typical scenario is in a Rails app when we need to do a call to a
#      remote server and block until a response is received
#

# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'yaml'
require 'hornetq'

$thread_count = (ARGV[0] || 1).to_i
$timeout = (ARGV[1] || 30000).to_i

config = YAML.load_file(File.dirname(__FILE__) + '/hornetq.yml')['development']

# Sample thread that does some work and then does a request-response call
def worker_thread(id, session_pool)
  begin
    # Obtain a session from the pool and return when complete
    session_pool.requestor('jms.queue.ExampleQueue') do |session, requestor|
      message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
      message << "Request Current Time"
    
      # Send message to the queue
      puts "Thread[#{id}]: Sending Request"
      if reply = requestor.request(message, $timeout)
        puts "Thread[#{id}]: Received Response: #{reply.inspect}"
        puts "Thread[#{id}]:   Message:[#{reply.body.inspect}]"
      else
        puts "Thread[#{id}]: Time out, No reply received after #{$timeout/1000} seconds"
      end
    end
  rescue Exception => exc
    puts "Thread[#{id}]: Terminating due to Exception:#{exc.inspect}"
    puts exc.backtrace
  end
  puts "Thread[#{id}]: Complete"
end

# Create a HornetQ Factory 
HornetQ::Client::Factory.create_factory(config[:connector]) do |factory|
  
  # Create a pool of session connections, all with the same session parameters
  # The pool is thread-safe and can be accessed concurrently by multiple threads
  session_pool = factory.create_session_pool(config[:session])
  threads = []
  
  # Do some work and then lets re-use the session in another thread below
  worker_thread(9999, session_pool) 
  
  $thread_count.times do |i|
    # Each thread will get a session from the session pool as needed
    threads << Thread.new { worker_thread(i, session_pool) }
  end
  threads.each {|t| t.join}
  
  # Important. Remember to close any open sessions in the pool
  session_pool.close
end