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
          value = true if value == 'true'
          value = false if value == 'false'
          value = value.to_i if value =~ /^\d+$/
          value = value.to_f if value =~ /^\d+\.\d*$/
          @params[key.to_sym] = value
        end
      end
    end

    def [](key)
      @params[key]
    end

    def backup?
      !!@params[:backup]
    end
  end
end