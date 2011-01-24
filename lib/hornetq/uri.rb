module HornetQ
  class URI
    attr_reader :scheme, :host, :port, :backup_host, :backup_port, :path, :params

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
      @params = {}
      if query
        query.split('&').each do |i|
          key, value = i.split('=')
          @params[key.to_sym] = value
        end
      end
    end

    def [](key)
      @params[key]
    end

    def create_server(parms={})
      # parms override settings
      parms = @params.merge(parms)
      config = Java::org.hornetq.core.config.impl.ConfigurationImpl.new
      data_directory = parms[:data_directory] || HornetQ::DEFAULT_DATA_DIRECTORY
      config.paging_directory = "#{data_directory}/paging"
      config.bindings_directory = "#{data_directory}/bindings"
      config.journal_directory = "#{data_directory}/journal"
      config.large_messages_directory = "#{data_directory}/large-messages"

      parms.each_pair do |key, val|
        next if key == :uri || key == :data_directory
        method = key.to_s+'='
        if factory.respond_to? method
          factory.send method, val
          #puts "Debug: #{key} = #{factory.send key}" if factory.respond_to? key.to_sym
        else
          puts "Warning: Option:#{key}, with value:#{val} is invalid and being ignored"
        end
      end
      config.persistence_enabled = false
      config.security_enabled = false
      config.journal_min_files = 10

      if Java::org.hornetq.core.journal.impl.AIOSequentialFileFactory.isSupported
        config.journal_type = Java::org.hornetq.core.server.JournalType::ASYNCIO
      else
        puts("AIO wasn't located on this platform, it will fall back to using pure Java NIO. If your platform is Linux, install LibAIO to enable the AIO journal");
        config.journal_type = Java::org.hornetq.core.server.JournalType::NIO
      end

      transport = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_ACCEPTOR_CLASS_NAME, {'host' => @host, 'port' => @port })

      transport_conf_set = java.util.HashSet.new
      transport_conf_set.add(transport)

      config.acceptor_configurations = transport_conf_set

      if backup?
        puts "backup"
        config.backup = true
        config.shared_store = false
      elsif @backup_host
        puts "live"
        #backup_params.put('reconnectAttempts', -1)
        backup_connector = Java::org.hornetq.api.core.TransportConfiguration.new(HornetQ::NETTY_CONNECTOR_CLASS_NAME, {'host' => @backup_host, 'port' => @backup_port })

        connector_conf_map = java.util.HashMap.new
        connector_conf_map.put('backup-connector', backup_connector)

        config.connector_configurations = connector_conf_map
        config.backup_connector_name = 'backup-connector'
      else
        puts 'standalone'
      end

      return Java::org.hornetq.core.server.HornetQServers.newHornetQServer(config)
    end

    def backup?
      @params[:backup] == 'true'
    end
  end
end