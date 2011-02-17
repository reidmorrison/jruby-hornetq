require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'hornetq'
require 'fileutils'

class MyThread < ::Thread
  def initialize(name, &block)
    super() do
      begin
        yield
      rescue => e
        HornetQ.logger.error("Thread #{name} died due to exception #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end

class ServerTest < Test::Unit::TestCase
  context 'standalone server' do
    setup do
      @server       = nil
      @tmp_data_dir = "/tmp/data_dir/#{$$}"
      @uri          = "hornetq://localhost:15445"
      @server_thread = MyThread.new('standalone server') do
        @server = HornetQ::Server.create_server(:uri => @uri, :data_directory => @tmp_data_dir, :security_enabled => false)
        @server.start
      end
      # Give the server time to startup
      sleep 5
    end

    teardown do
      @server.stop if @server
      @server_thread.join if @server_thread
      FileUtils.rm_rf(@tmp_data_dir)
    end

    should 'pass simple messages' do
      count      = 10
      queue_name = 'test_queue'
      config = {
        :connection => { :uri => @uri },
        #:session   => { :username =>'guest', :password => 'guest'}
      }

      # Create a HornetQ session
      HornetQ::Client::Connection.session(config) do |session|
        session.create_queue(queue_name, queue_name, true)
        producer = session.create_producer(queue_name)
        (1..count).each do |i|
          message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,false)
          message.durable = true
          # Set the message body text
          message.body = "Message ##{i}"
          # Send message to the queue
          producer.send(message)
        end
      end

      HornetQ::Client::Connection.session(config) do |session|
        consumer = session.create_consumer(queue_name)
        session.start

        i = 0
        while message = consumer.receive(1000)
          i += 1
          message.acknowledge
          assert_equal "Message ##{i}", message.body
        end
      end
    end
  end

  # TODO: Figure out why producer get's severe error during failover
#  context 'live and backup server' do
#    setup do
#      @count      = 20
#
#      @server              = nil
#      @tmp_data_dir        = "/tmp/data_dir/#{$$}"
#      @uri                 = "hornetq://localhost:15445,localhost:15446"
#
#      @backup_server       = nil
#      @backup_tmp_data_dir = "/tmp/backup_data_dir/#{$$}"
#      @backup_uri          = "hornetq://localhost:15446"
#
#      @backup_server_thread = MyThread.new('backup server') do
#        begin
#          @backup_server = HornetQ::Server.create_server(:uri => @backup_uri, :data_directory => @backup_tmp_data_dir, :backup => true, :security_enabled => false)
#          @backup_server.start
#        rescue Exception => e
#          HornetQ.logger.error "Error in backup server thread: #{e.message}\n#{e.backtrace.join("\n")}"
#        end
#      end
#      # Give the backup server time to startup
#      sleep 10
#
#      @server_thread = MyThread.new('live server') do
#        begin
#          @server = HornetQ::Server.create_server(:uri => @uri, :data_directory => @tmp_data_dir, :security_enabled => false)
#          @server.start
#        rescue Exception => e
#          HornetQ.logger.error "Error in live server thread: #{e.message}\n#{e.backtrace.join("\n")}"
#        end
#      end
#
#      # Give the live server time to startup
#      sleep 10
#
#      @queue_name = 'test_queue'
#      @config = {
#        :connection => {
#          :uri                            => @uri,
#          :failover_on_initial_connection => true,
#          :failover_on_server_shutdown    => true,
#        },
#        :session   => {}
#      }
#
#      @killer_thread = MyThread.new('killer') do
#        sleep 5
#        @server.stop
#      end
#
#      @producer_thread = MyThread.new('producer') do
#        # Create a HornetQ session
#        HornetQ::Client::Connection.session(@config) do |session|
#          session.create_queue(@queue_name, @queue_name, true)
#          producer = session.create_producer(@queue_name)
#          (1..@count).each do |i|
#            message = session.create_message(HornetQ::Client::Message::TEXT_TYPE, true)
#            # Set the message body text
#            message.body = "Message ##{i}"
#            # Send message to the queue
#            begin
#              HornetQ.logger.info "Producing message: #{message.body}"
#              producer.send(message)
#              sleep 1
#            rescue Java::org.hornetq.api.core.HornetQException => e
#              HornetQ.logger.error "Received producer exception: #{e.message} with code=#{e.cause.code}"
#              if e.cause.getCode == Java::org.hornetq.api.core.HornetQException::UNBLOCKED
#                HornetQ.logger.info "Retrying the send"
#                retry
#              end
#            rescue Exception => e
#              HornetQ.logger.error "Received producer exception: #{e.message}"
#            end
#          end
#        end
#      end
#    end
#
#    teardown do
#      @server.stop
#      @backup_server.stop
#      [ @server_thread, @backup_server_thread, @killer_thread, @producer_thread ].each do |thread|
#        thread.join
#      end
#      FileUtils.rm_rf([@tmp_data_dir, @backup_tmp_data_dir])
#    end
#
#    should 'failover to backup server w/o message loss' do
#      # Let the producer create the queue
#      sleep 2
#      HornetQ::Client::Connection.session(@config) do |session|
#        consumer = session.create_consumer(@queue_name)
#        session.start
#
#        i = 0
#        while message = consumer.receive(1000)
#          i += 1
#          message.acknowledge
#          assert_equal "Message ##{i}", message.body
#          HornetQ.logger.info "Consuming message #{message.body}"
#        end
#        assert_equal @count, i
#      end
#    end
#  end
end
