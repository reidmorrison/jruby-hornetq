require 'rubygems'
require 'resque/job_with_status' # in rails you would probably do this in an initializer

# sleeps for _length_ seconds updating the status every second
#
#
# Create a Resque Job with the ability to report status
#
class SleepJob < Resque::JobWithStatus

  # Set the name of the queue to use for this Job Worker
  @queue = "sleep_job"

  # Must be an instance method for Resque::JobWithStatus
  def perform
    total = options['length'].to_i || 10
    num = 0
    while num < total
      at(num, total, "At #{num} of #{total}")
      sleep(1)
      num += 1
    end
    completed
  end

end

# Submit a new request at the command line
if __FILE__ == $0
  # Make sure you have a worker running
  # jruby resque_worker.rb

  count = (ARGV[0] || 10).to_i

  # running the job
  puts "Creating the SleepJob"
  job_id = SleepJob.create :length => count
  puts "Got back #{job_id}"

  # check the status until its complete
  while status = Resque::Status.get(job_id) and !status.completed? && !status.failed?
    sleep 1
    puts status.inspect
  end
end