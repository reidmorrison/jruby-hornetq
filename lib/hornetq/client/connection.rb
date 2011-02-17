module HornetQ
  module Client

    class Connection
      # Create a new Connection and Session
      #
      #  Creates a new connection and session, then passes the session to the supplied
      #  block. Upon completion the session and connection are both closed
      # See Connection::initialize and Connection::create_session for the list
      #  of parameters
      #
      # Returns result of block
      def self.session(params={},&proc)
        raise "Missing mandatory code block" unless proc
        connection = nil
        session = nil
        begin
          if params.kind_of?(String)
            # TODO: Support passing username and password from URI to Session
            connection = self.new(params)
            connection.session({}, &proc)
          else
            connection = self.new(params[:connection] || {})
            connection.session(params[:session] || {}, &proc)
          end
        ensure
          connection.close if connection
        end
      end

      # Create a new Connection along with a Session, and then start the session
      #
      #  Creates a new connection and session, then passes the session to the supplied
      #  block. Upon completion the session and connection are both closed
      # See Connection::initialize and Connection::create_session for the list
      #  of parameters
      #  
      # Returns result of block
      def self.start(params={},&proc)
        session(params) do |session|
          session.start
          proc.call(session)
        end
      end

      # Call the supplied code block after creating a connection instance
      # See initialize for the parameter list
      # The connection is closed before returning
      #
      # Returns the result of the code block
      def self.connection(params={}, &proc)
        raise "Missing mandatory code block" unless proc
        connection = nil
        result = nil
        begin
          connection=self.new(params)
          result = proc.call(connection)
        ensure
          connection.close
        end
        result
      end

      # Create a new Connection from which sessions can be created
      #
      # Parameters:
      # * a Hash consisting of one or more of the named parameters
      # * Summary of parameters and their default values
      #  HornetQ::Client::Connection.new(
      #    :uri                            => 'hornetq://localhost',
      #    :ack_batch_size                 => ,
      #    :auto_group                     => ,
      #    :block_on_acknowledge           => ,
      #    :block_on_durable_send          => ,
      #    :block_on_non_durable_send      => ,
      #    :cache_large_messages_client    => ,
      #    :call_timeout                   => ,
      #    :client_failure_check_period    => ,
      #    :confirmation_window_size       => ,
      #    :connection_load_balancing_policy_class_name => ,
      #    :connection_ttl                 => ,
      #    :consumer_max_rate              => ,
      #    :consumer_window_size           => ,
      #    :discovery_address              => ,
      #    :discovery_initial_wait_timeout => ,
      #    :discovery_port                 => ,
      #    :discovery_refresh_timeout      => ,
      #    :failover_on_initial_connection => true,
      #    :failover_on_server_shutdown    => true,
      #    :group_id                       => ,
      #    :initial_message_packet_size    => ,
      #    :java_object                    => ,
      #    :local_bind_address             => ,
      #    :max_retry_interval             => ,
      #    :min_large_message_size         => ,
      #    :pre_acknowledge                => ,
      #    :producer_max_rate              => ,
      #    :producer_window_size           => ,
      #    :reconnect_attempts             => 1,
      #    :retry_interval                 => ,
      #    :retry_interval_multiplier      => ,
      #    :scheduled_thread_pool_max_size => ,
      #    :static_connectors              => ,
      #    :thread_pool_max_size           => ,
      #    :use_global_pools               =>
      #  )
      #
      # Mandatory Parameters
      # * :uri
      #   * The hornetq uri as to which server to connect with and which
      #     transport protocol to use. Format:
      #       hornetq://server:port,backupserver:port/?protocol=[netty|discover]
      #   * To use the default netty transport
      #       hornetq://server:port
      #   * To use the default netty transport and specify a backup server
      #       hornetq://server:port,backupserver:port
      #   * To use auto-discovery
      #       hornetq://server:port/?protocol=discovery
      #   * To use HornetQ within the current JVM
      #       hornetq://invm
      #
      # Optional Parameters
      # * :ack_batch_size
      # * :auto_group
      # * :block_on_acknowledge
      # * :block_on_durable_send
      # * :block_on_non_durable_send
      # * :cache_large_messages_client
      # * :call_timeout
      # * :client_failure_check_period
      # * :confirmation_window_size
      # * :connection_load_balancing_policy_class_name
      # * :connection_ttl
      # * :consumer_max_rate
      # * :consumer_window_size
      # * :discovery_address
      # * :discovery_initial_wait_timeout
      # * :discovery_port
      # * :discovery_refresh_timeout
      # * :failover_on_initial_connection
      # * :failover_on_server_shutdown
      # * :group_id
      # * :initial_message_packet_size
      # * :java_object
      # * :local_bind_address
      # * :max_retry_interval
      # * :min_large_message_size
      # * :pre_acknowledge
      # * :producer_max_rate
      # * :producer_window_size
      # * :reconnect_attempts
      # * :retry_interval
      # * :retry_interval_multiplier
      # * :scheduled_thread_pool_max_size
      # * :static_connectors
      # * :thread_pool_max_size
      # * :use_global_pools

      def initialize(params={})
        params =params.clone
        uri = nil
        # TODO: Support :uri as an array for cluster configurations
        if params.kind_of?(String)
          uri = HornetQ::URI.new(params)
          params = uri.params
        else
          raise "Missing :uri param in HornetQ::Server.create_server" unless params[:uri]
          uri = HornetQ::URI.new(params.delete(:uri))
          # params override uri params
          params = uri.params.merge(params)
        end

        @connection = nil
        @sessions = []
        @consumers = []
        # In-VM Transport has no fail-over or additional parameters
        if uri.host == 'invm'
          transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::INVM_CONNECTOR_CLASS_NAME)
          @connection = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
        elsif params[:protocol]
          # Auto-Discovery just has a host name and port
          if params[:protocol] == 'discovery'
            @connection = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(uri.host, uri.port)
          elsif params[:protocol] != 'netty'
            raise "Unknown HornetQ protocol:#{params[:protocol]}"
          end
        end

        # Unless already created, then the connection will use the netty protocol
        unless @connection
          # Primary Transport
          transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.host, 'port' => uri.port })

          # Check for backup server connection information
          if uri.backup_host
            backup_transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.backup_host, 'port' => uri.backup_port })
            @connection = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport, backup_transport)
          else
            @connection = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
          end
        end

        # If any other options were supplied, apply them to the created Connection instance
        params.each_pair do |key, val|
          next if key == :uri
          method = key.to_s+'='
          if @connection.respond_to? method
            @connection.send method, val
            #puts "Debug: #{key} = #{@connection.send key}" if @connection.respond_to? key.to_sym
          else
            HornetQ.logger.warn "Warning: Option:#{key}, with value:#{val} is invalid and being ignored"
          end
        end
      end

      # Create a new HornetQ session
      #
      # Note: Remember to close the session once it is no longer used.
      #       Recommend using #session with a block over this method where possible
      #
      # Note:
      # * The returned session MUST be closed once complete
      #     connection = HornetQ::Client::Connection.new(:uri => 'hornetq://localhost/')
      #     session = connection.create_session
      #       ...
      #     session.close
      #     connection.close
      #
      # Returns:
      # * A new HornetQ ClientSession
      # * See org.hornetq.api.core.client.ClientSession for documentation on returned object
      #
      # Throws:
      # * NativeException
      # * ...
      #
      # Example:
      #   require 'hornetq'
      #
      #   connection = nil
      #   session = nil
      #   begin
      #     connection = HornetQ::Client::Connection.new(:uri => 'hornetq://localhost/')
      #     session = connection.create_session
      #
      #     # Create a new queue
      #     session.create_queue('Example', 'Example', true)
      #
      #     # Create a producer to send messages
      #     producer = session.create_producer('Example')
      #
      #     # Create a Text Message
      #     message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
      #     message.body_buffer.write_string('Hello World')
      #
      #     # Send the message
      #     producer.send(message)
      #   ensure
      #     session.close if session
      #     connection.close if connection
      #   end
      #
      # Parameters:
      # * a Hash consisting of one or more of the named parameters
      # * Summary of parameters and their default values
      #  connection.create_session(
      #   :username          => 'my_username',   # Default is no authentication
      #   :password          => 'password',      # Default is no authentication
      #   :xa                => false,
      #   :auto_commit_sends => true,
      #   :auto_commit_acks  => true,
      #   :pre_acknowledge   => false,
      #   :ack_batch_size    => 1
      #   )
      #
      # Mandatory Parameters
      # * None
      #
      # Optional Parameters
      # * :username
      #   * The user name. To create an authenticated session
      #
      # * :password
      #   * The user password. To create an authenticated session
      #
      # * :xa
      #   * Whether the session supports XA transaction semantics or not
      #
      # * :auto_commit_sends
      #   * true: automatically commit message sends
      #   * false: commit manually
      #
      # * :auto_commit_acks
      #   * true: automatically commit message acknowledgement
      #   * false: commit manually
      #
      # * :pre_acknowledge
      #   * true: to pre-acknowledge messages on the server
      #   * false: to let the client acknowledge the messages
      #   * Note: It is possible to pre-acknowledge messages on the server so that the
      #     client can avoid additional network trip to the server to acknowledge
      #     messages. While this increases performance, this does not guarantee
      #     delivery (as messages can be lost after being pre-acknowledged on the
      #     server). Use with caution if your application design permits it.
      #
      #  * :ack_batch_size
      #    * the batch size of the acknowledgements
      #
      # * :auto_close
      #   * true: closing the connection will also automatically close the 
      #           returned session
      #   * false: the caller must close the session
      #
      def create_session(params={})
        raise "HornetQ::Client::Connection Already Closed" unless @connection
        session = @connection.create_session(
          params[:username],
          params[:password],
          params[:xa] || false,
          params[:auto_commit_sends].nil? ? true : params[:auto_commit_sends],
          params[:auto_commit_acks].nil? ? true : params[:auto_commit_acks],
          params[:pre_acknowledge] || false,
          params[:ack_batch_size] || 1)
        (@sessions << session) if params[:auto_close]
        session
      end

      # Create a session, call the supplied block and once it completes
      # close the session.
      # See session_create for the Parameters
      #
      # Returns the result of the block
      #
      # Example
      #     HornetQ::Client::Connection.create_session(:uri => 'hornetq://localhost/') do |session|
      #       session.create_queue("Address", "Queue")
      #     end
      #
      # Example:
      #   require 'hornetq'
      #
      #   connection = nil
      #   begin
      #     connection = HornetQ::Client::Connection.new(:uri => 'hornetq://localhost/')
      #     connection.create_session do |session|
      #
      #       # Create a new queue
      #       session.create_queue('Example', 'Example', true)
      #
      #       # Create a producer to send messages
      #       producer = session.create_producer('Example')
      #
      #       # Create a Text Message
      #       message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
      #       message.body = 'Hello World'
      #
      #       # Send the message
      #       producer.send(message)
      #     end
      #   ensure
      #     connection.close if connection
      #   end
      def session(params={}, &proc)
        raise "HornetQ::Client::session mandatory block missing" unless proc
        session = nil
        begin
          session = create_session(params)
          proc.call(session)
        ensure
          session.close if session
        end
      end

      # Create a Session pool
      # TODO Raise an exception when gene_pool is not available
      def create_session_pool(params={})
        require 'hornetq/client/session_pool'
        SessionPool.new(self, params)
      end

      # Close Connection connections
      def close
        @sessions.each { |session| session.close }
        @connection.close if @connection
        @connection = nil
      end

      # Receive messages in a separate thread when they arrive
      # Allows messages to be received in a separate thread. I.e. Asynchronously
      # This method will return to the caller before messages are processed.
      # It is then the callers responsibility to keep the program active so that messages
      # can then be processed.
      #
      # Note:
      #
      # Session Parameters:
      #   :options => any of the javax.jms.Session constants
      #      Default: javax.jms.Session::AUTO_ACKNOWLEDGE
      #
      #   :session_count : Number of sessions to create, each with their own consumer which
      #                    in turn will call the supplied block.
      #                    Note: The supplied block must be thread safe since it will be called
      #                          by several threads at the same time.
      #                          I.e. Don't change instance variables etc. without the
      #                          necessary semaphores etc.
      #                    Default: 1
      #
      # Consumer Parameters:
      #   :queue_name => Name of the Queue to read messages from
      #
      #   :selector   => Filter which messages should be returned from the queue
      #                  Default: All messages
      #   :no_local   => Determine whether messages published by its own connection
      #                  should be delivered to it
      #                  Default: false
      #
      #   :statistics Capture statistics on how many messages have been read
      #      true  : This method will capture statistics on the number of messages received
      #              and the time it took to process them.
      #              The timer starts when each() is called and finishes when either the last message was received,
      #              or when Destination::statistics is called. In this case MessageConsumer::statistics
      #              can be called several times during processing without affecting the end time.
      #              Also, the start time and message count is not reset until MessageConsumer::each
      #              is called again with :statistics => true
      #
      #              The statistics gathered are returned when :statistics => true and :async => false
      #
      # Usage: For transacted sessions (the default) the Proc supplied must return
      #        either true or false:
      #          true => The session is committed
      #          false => The session is rolled back
      #          Any Exception => The session is rolled back
      #
      # Notes:
      # * Remember to call ::start on the connection otherwise the on_message will not
      #   start consuming any messages
      # * Remember to call message.acknowledge before completing the block so that
      #       the message will be removed from the queue
      # * If the block throws an exception, the
      def on_message(params, &proc)
        consumer_count = params[:session_count] || 1
        consumer_count.times do
          session = self.create_session(params)
          consumer = session.create_consumer_from_params(params)
          consumer.on_message(params, &proc)
          session.start
          @consumers << consumer
          @sessions << session
        end
      end

      def on_message_statistics
        @consumers.collect{|consumer| consumer.on_message_statistics}
      end

    end
  end  
end