module HornetQ
  class URI
    attr_reader :scheme, :host, :port, :backup_host, :backup_port, :path

    # hornetq://localhost
    # hornetq://localhost,192.168.0.22
    # hornetq://localhost:5445,backupserver:5445/?protocol=netty
    # hornetq://localhost/?protocol=invm
    # hornetq://discoveryserver:5445/?protocol=discovery

    def initialize(uri)
      raise Exception,"Invalid protocol format: #{uri}" unless uri =~ /(.*):\/\/(.*)/
      @scheme, @host = $1, $2
      raise Exception,"Bad URI(only scheme hornetq:// is supported): #{uri}" unless @scheme == 'hornetq'
      raise 'Mandatory hostname missing in uri' if @host.empty?
      if @host =~ /(.*?)(\/.*)/
        @host, @path = $1, $2
      else
        @path = '/'
      end
      if @host =~ /(.*),(.*)/
        @host, @backup_host = $1, $2
      end
      if @host =~ /(.*):(.*)/
        @host, @port = $1, HornetQ.netty_port($2)
      else
        @port = HornetQ::DEFAULT_NETTY_PORT
      end
      if @backup_host
        if @backup_host =~ /(.*):(.*)/
          @backup_host, @backup_port = $1, HornetQ.netty_port($2)
        else
          @backup_port = HornetQ::DEFAULT_NETTY_PORT
        end
      end
      query = nil
      if @path =~ /(.*)\?(.*)/
        @path, query = $1, $2
      end

      # Extract settings passed in query
      @settings = {}
      if query
        query.split('&').each do |i|
          key, value = i.split('=')
          @settings[key.to_sym] = value
        end
      end
    end

    def [](key)
      @settings[key]
    end

    def client_factory(parms={})
      # Determine transport protocol
      factory = nil
      # In-VM Transport has no fail-over or additional parameters
      if @host == 'invm'
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(INVM_CLASS_NAME)
        factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
      elsif @settings[:protocol]
        # Auto-Discovery just has a host name and port
        if @settings[:protocol] == 'discovery'
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(@host, @port)
        elsif @settings[:protocol] != 'netty'
          raise "Unknown HornetQ protocol:#{@settings[:protocol]}"
        end
      end

      # Unless already created, then the factory will use the netty protocol
      unless factory
        # Primary Transport
        transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => @host, 'port' => @port })

        # Check for backup server connection information
        if @backup_host
          backup_transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => @backup_host, 'port' => @backup_port })
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport, backup_transport)
        else
          factory = Java::org.hornetq.api.core.client.HornetQClient.create_client_session_factory(transport)
        end
      end

      # If any other options were supplied, apply them to the created Factory instance
      parms.each_pair do |key, val|
        next if key == :uri
        method = key.to_s+'='
        if factory.respond_to? method
          factory.send method, val
          #puts "Debug: #{key} = #{factory.send key}" if factory.respond_to? key.to_sym
        else
          puts "Warning: Option:#{key}, with value:#{val} is invalid and being ignored"
        end
      end
      return factory
    end

    def create_server
      config = Java::org.hornetq.core.config.impl.ConfigurationImpl.new
      config.persistence_enabled = false
      config.security_enabled = false
      config.paging_directory = "#{data_directory}/paging"
      config.bindings_directory = "#{data_directory}/bindings"
      config.journal_directory = "#{data_directory}/journal"
      config.journal_min_files = 10
      config.large_messages_directory = "#{data_directory}/large-messages"

      if Java::org.hornetq.core.journal.impl.AIOSequentialFileFactory.isSupported
        config.journal_type = Java::org.hornetq.core.server.JournalType::ASYNCIO
      else
        puts("AIO wasn't located on this platform, it will fall back to using pure Java NIO. If your platform is Linux, install LibAIO to enable the AIO journal");
        config.journal_type = Java::org.hornetq.core.server.JournalType::NIO
      end

      transport_conf_params = java.util.HashMap.new
      transport_conf_params.put('host', host)
      transport_conf_params.put('port', @port)
      transport_conf = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_ACCEPTOR_CLASS_NAME, transport_conf_params);

      transport_conf_set = java.util.HashSet.new
      transport_conf_set.add(transport_conf)

      config.acceptor_configurations = transport_conf_set

      if backup?
        puts "backup"
        config.backup = true
        config.shared_store = false
      elsif @backup_host
        puts "live"
        backup_params = java.util.HashMap.new
        backup_params.put('host', @backup_host)
        backup_params.put('port', @backup_port)
        #backup_params.put('reconnectAttempts', -1)
        backup_connector_conf = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, backup_params)

        connector_conf_map = java.util.HashMap.new
        connector_conf_map.put('backup-connector', backup_connector_conf)

        config.connector_configurations = connector_conf_map
        config.backup_connector_name = 'backup-connector'
      else
        puts 'standalone'
      end

      return Java::org.hornetq.core.server.HornetQServers.newHornetQServer(config)
    end

    def backup?
      @settings[:backup] == 'true'
    end

    def data_directory
      @settings[:data_directory] || HornetQ::DEFAULT_DATA_DIRECTORY
    end
  end
end