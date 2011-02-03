# Start up a Resque Worker to run the Job Request
require 'rubygems'
require 'resque'
require 'resque/job_with_status'
require 'sleep_job'
require 'hornetq_job'

# Number of workers to start (each on its own thread)
thread_count = (ARGV[0] || 1).to_i

# Configure Redis client connection
Resque.redis = "localhost:6379"

# How long to keep Job status for in seconds
Resque::Status.expire_in = (24 * 60 * 60) # 24hrs in seconds

# Start the worker instance(s) in which Jobs are run
resque_worker = Resque::Worker.new("hornetq_job")
resque_worker.log "Starting worker #{resque_worker}"
resque_worker.verbose = true
resque_worker.very_verbose = true
resque_worker.work(5) # Redis Poll interval in seconds
