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
      def self.start_session(params={},&proc)
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
      # Mandatory Parameters
      # * :uri                             => 'hornetq://localhost',
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
      # Optional Parameters
      #
      #   High Availability
      #
      # *  :ha                             => true | false,
      #      true:  Receives cluster topology updates from the cluster as
      #             servers leave or join and new backups are appointed or removed.
      #      false: Uses the suplied static list of hosts in :uri
      #             and no HA backup information is propagated to the client
      #      Default: false
      #
      #   Flow Control
      #
      #    :ack_batch_size                 => integer,
      #      Sets the acknowledgements batch size. Must be > 0
      #
      #    :pre_acknowledge                => true | false,
      #      Sets whether messages will pre-acknowledged on the server before
      #      they are sent to the consumers or not
      #        true : Pre-acknowledge consumed messages on the server before they are sent to consumers
      #        false: Clients acknowledge the message they consume.
      #      Default: false
      #
      #   Grouping:
      #
      #    :auto_group                     => true | false,
      #      Sets whether producers will automatically assign a group ID
      #      to sent messages
      #        true: A random unique group ID is created and set on each message
      #              for the property Message.HDR_GROUP_ID
      #      Default: false
      #
      #    :group_id                       => string,
      #      Sets the group ID that will be set on each message sent
      #      Default: nil (no goup id will be set)
      #
      #   Blocking calls:
      #
      #    :block_on_acknowledge           => true | false,
      #      Sets whether consumers created through this factory will block
      #      while sending message acknowledgements or do it asynchronously.
      #      Default: false
      #
      #    :block_on_durable_send          => true | false,
      #      Sets whether producers will block while sending durable messages
      #      or do it asynchronously.
      #      If the session is configured to send durable message asynchronously,
      #      the client can set a SendAcknowledgementHandler on the ClientSession
      #      to be notified once the message has been handled by the server.
      #      Default: true
      #
      #    :block_on_non_durable_send      => true | false,
      #      Sets whether producers will block while sending non-durable messages
      #      or do it asynchronously.
      #      If the session is configured to send non-durable message asynchronously,
      #      the client can set a SendAcknowledgementHandler on the ClientSession
      #      to be notified once the message has been handled by the server.
      #      Default: false
      #
      #    :call_timeout                   => long,
      #      Sets the blocking calls timeout in milliseconds. If client's blocking calls to the
      #      server take more than this timeout, the call will throw a
      #      HornetQException with the code HornetQException.CONNECTION_TIMEDOUT.
      #      Value is in milliseconds, default value is HornetQClient.DEFAULT_CALL_TIMEOUT.
      #      Must be >= 0
      #
      #   Client Reconnection Parameters:
      #
      #    :connection_ttl                 => long,
      #      Set the connection time-to-live
      #      -1  : Disable
      #      >=0 : milliseconds the server will keep a connection alive in the
      #            absence of any data arriving from the client.
      #      Default: 60,000
      #
      #    :client_failure_check_period    => long,
      #      Sets the period in milliseconds used to check if a client has
      #      failed to receive pings from the server.
      #      Value must be -1 (to disable) or greater than 0
      #      Default: 30,000
      #
      #    :initial_connect_attempts       => int,
      #      ?
      #
      #    :failover_on_initial_connection => true | false,
      #      Sets whether the client will automatically attempt to connect to
      #      the backup server if the initial connection to the live server fails
      #        true : If live server is not reachable try to connect to backup server
      #        false: Fail to start if live server is not reachable
      #      Default: false
      #
      #    :max_retry_interval             => long,
      #      Sets the maximum retry interval in milliseconds.
      #      Only appicable if the retry interval multiplier has been specified
      #      Default: 2000 (2 seconds)
      #
      #    :reconnect_attempts             => 1,
      #    :retry_interval                 => long,
      #      Returns the time to retry the connection after failure.
      #      Value is in milliseconds.
      #      Default: 2000 (2 seconds)
      #
      #    :retry_interval_multiplier      => double,
      #      Sets the multiplier to apply to successive retry intervals.
      #      Value must be positive.
      #      Default: 1
      #
      #   Large Message parameters:
      #
      #    :cache_large_messages_client    => true | false,
      #      Sets whether large messages received by consumers will be
      #      cached in temporary files or not.
      #      When true, consumers will create temporary files to cache large messages.
      #      There is 1 temporary file created for each large message.
      #      Default: false
      #
      #    :min_large_message_size         => int,
      #      Sets the large message size threshold in bytes. Value must be > 0
      #      Messages whose size is if greater than this value will be handled as large messages
      #      Default: 102400 bytes  (100 KBytes)
      #
      #    :compress_large_message         => true | false,
      #
      #   Message Rate Management:
      #
      #    :consumer_max_rate              => int,
      #      Sets the maximum rate of message consumption for consumers.
      #      Controls the rate at which a consumer can consume messages.
      #      A consumer will never consume messages at a rate faster than the
      #      rate specified.
      #        -1 : Disable
      #       >=0 : Maximum desired message consumption rate specified
      #             in units of messages per second.
      #      Default: -1
      #
      #    :producer_max_rate              => int,
      #      Sets the maximum rate of message production for producers.
      #      Controls the rate at which a producer can produce messages.
      #      A producer will never produce messages at a rate faster than the rate specified.
      #        -1 : Disabled
      #        >0 : Maximum desired message production rate specified in units of messages per second.
      #      Default: -1 (Disabled)
      #
      #   Thread Pools:
      #
      #    :scheduled_thread_pool_max_size => int,
      #      Sets the maximum size of the scheduled thread pool.
      #      This setting is relevant only if this factory does not use global pools.
      #      Value must be greater than 0.
      #      Default: 5
      #
      #    :thread_pool_max_size           => int,
      #      Sets the maximum size of the thread pool.
      #      This setting is relevant only if this factory does not use
      #      global pools.
      #        -1 : Unlimited thread pool
      #        >0 : Number of threads in pool
      #      Default: -1 (Unlimited)
      #
      #    :use_global_pools               => true | false,
      #      Sets whether this factory will use global thread pools
      #      (shared among all the factories in the same JVM) or its own pools.
      #        true: Uses global JVM thread pools across all HornetQ connections
      #        false: Use a thread pool just for this connection
      #      Default: true
      #
      #   Window Sizes:
      #
      #    :confirmation_window_size       => int,
      #      Set the size in bytes for the confirmation window of this connection.
      #        -1 : Disable the window
      #        >0 : Size in bytes
      #      Default: -1 (Disabled)
      #
      #    :consumer_window_size           => int,
      #      Sets the window size for flow control for consumers.
      #       -1 : Disable flow control
      #        0 : Do Not buffer any messages
      #       >0 : Set the maximum size of the buffer
      #      Default: 1048576 (1 MB)
      #
      #    :producer_window_size           => int,
      #      Sets the window size for flow control of the producers.
      #      -1 : Disable flow control
      #      >0 : The maximum amount of bytes at any give time (to prevent overloading the connection).
      #      Default: 65536 (64 KBytes)
      #
      #  Other:
      #
      #    :connection_load_balancing_policy_class_name => string,
      #      Set the class name of the connection load balancing policy
      #      Value must be the name of a class implementing org.hornetq.api.core.client.loadbalance.ConnectionLoadBalancingPolicy
      #      Default: "org.hornetq.api.core.client.loadbalance.RoundRobinConnectionLoadBalancingPolicy"
      #
      #    :initial_message_packet_size    => int,
      #      Sets the initial size of messages in bytes
      #      Value must be greater than 0
      #
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

        # In-VM Transport has no fail-over or additional parameters
        @is_invm = uri.host == 'invm'
        transport_list = []
        if @is_invm
          transport_list << Java::org.hornetq.api.core::TransportConfiguration.new(HornetQ::INVM_CONNECTOR_CLASS_NAME)
        else
          case params[:protocol]
          when 'discovery'
            #TODO: Also support: DiscoveryGroupConfiguration(String name, String localBindAddress, String groupAddress, int groupPort, long refreshTimeout, long discoveryInitialWaitTimeout)
            transport_list << Java::org.hornetq.api.core::DiscoveryGroupConfiguration.new(uri.host, uri.port)
          when 'netty', nil
            transport_list << Java::org.hornetq.api.core::TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.host, 'port' => uri.port })

            if uri.backup_host
              transport_list << Java::org.hornetq.api.core::TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => uri.backup_host, 'port' => uri.backup_port })
            end
          else
            raise "Unknown HornetQ protocol:'#{params[:protocol]}'"
          end
        end

        #TODO: Support: server_locator.addInterceptor

        # Create server locator with or without HA. Without HA being the default
        @server_locator = if params[:ha]
          Java::org.hornetq.api.core.client::HornetQClient.createServerLocatorWithHA(*transport_list)
          #TODO: Support: server_locator.addClusterTopologyListener
        else
          Java::org.hornetq.api.core.client::HornetQClient.createServerLocatorWithoutHA(*transport_list)
        end

        # If any other options were supplied, apply them to the server locator
        params.each_pair do |key, val|
          method = key.to_s+'='
          if @server_locator.respond_to? method
            @server_locator.send method, val
            HornetQ.logger.trace { "HornetQ ServerLocator setting: #{key} = #{@connection.send key}" } if @server_locator.respond_to? key.to_sym
          else
            HornetQ.logger.warn "Warning: Option:#{key}, with value:#{val} is invalid and will be ignored"
          end
        end

        @connection = @server_locator.createSessionFactory
        # For handling managed sessions and consumers
        @sessions = []
        @consumers = []
      end

      # Return true if this connection was configured to use INVM transport protocol
      def invm?
        @is_invm
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
      # * :managed
      #   * true: The session will be managed by the connection. It will be
      #           closed when the connection is closed.
      #           Also the session will be started or stopped when
      #           Connection#start_managed_sessions or
      #           Connection#stop_managed_sessions is called
      #   * false: The caller is responsible for closing the session
      #   * Default: false
      #
      def create_session(params={})
        raise "HornetQ::Client::Connection Already Closed" unless @connection
        params ||= {}
        session = @connection.create_session(
          params[:username],
          params[:password],
          params[:xa] || false,
          params[:auto_commit_sends].nil? ? true : params[:auto_commit_sends],
          params[:auto_commit_acks].nil? ? true : params[:auto_commit_acks],
          params[:pre_acknowledge] || false,
          params[:ack_batch_size] || 1)
        (@sessions << session) if params.fetch(:managed, false)
        session
      end

      # Create a session, call the supplied block and once it completes
      # close the session.
      # See session_create for the Parameters
      #
      # Returns the result of the block
      #
      # Example:
      #   require 'hornetq'
      #
      #   HornetQ::Client::Connection.connection('hornetq://localhost/') do |connection
      #     connection.session do |session|
      #
      #       # Create a producer to send messages
      #       session.producer('Example') do |producer|
      #
      #         # Create a Text Message
      #         message = session.create_message(HornetQ::Client::Message::TEXT_TYPE,true)
      #         message.body = 'Hello World'
      #
      #         # Send the message
      #         producer.send(message)
      #       end
      #     end
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

      # Create a session, start the session, call the supplied block
      # and once the block completes close the session.
      #
      # See: #session_create for the Parameters
      #
      # Returns the result of the block
      #
      #
      # Example:
      #   require 'hornetq'
      #
      #   HornetQ::Client::Connection.connection('hornetq://localhost/') do |connection
      #     # Must start the session other we cannot consume messages using it
      #     connection.start_session do |session|
      #
      #       # Create a consumer to receive messages
      #       session.consumer('TestQueue') do |consumer|
      #
      #         consumer.each do |message|
      #           message.acknowledge
      #         end
      #
      #       end
      #     end
      #   end
      def start_session(params={}, &proc)
        raise "HornetQ::Client::session mandatory block missing" unless proc
        session = nil
        begin
          session = create_session(params)
          session.start
          proc.call(session)
        ensure
          session.close if session
        end
      end

      # Create a Session pool
      def create_session_pool(params={})
        require 'hornetq/client/session_pool'
        SessionPool.new(self, params)
      end

      # Close Connection connections
      def close
        @sessions.each { |session| session.close }
        @connection.close if @connection
        @server_locator.close if @server_locator
        @connection = nil
        @server_locator = nil
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
      #   :queue_name  => The name of the queue to consume messages from. Mandatory
      #   :filter      => Only consume messages matching the filter: Default: nil
      #   :browse_only => Whether to just browse the queue or consume messages
      #                   true | false. Default: false
      #   :window_size => The consumer window size.
      #   :max_rate    => The maximum rate to consume messages.
      #   :auto_start  => Immediately start processing messages.
      #                   If set to false, call Connection#start_managed_sessions
      #                   to manually start receive messages later
      #                   Default: true
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
          session.start if params.fetch(:auto_start, true)
          @consumers << consumer
          @sessions << session
        end
      end

      def on_message_statistics
        @consumers.collect{|consumer| consumer.on_message_statistics}
      end

      # Start all sessions managed by this connection
      #
      # Sessions created via #create_session are not managed unless
      # :managed => true was specified when the session was created
      #
      # Session are Only managed when created through the following methods:
      #   Connection#on_message
      #   Connection#create_session And :managed => true
      #
      # This call does not do anything to sessions in a session pool
      def start_managed_sessions
        @sessions.each {|session| session.start}
      end

      # Stop all sessions managed by this connection so that they no longer
      # receive messages for processing
      #
      # See: #start_managed_sessions for details on which sessions are managed
      def stop_managed_sessions
        @sessions.each {|session| session.stop}
      end
    end
  end
end