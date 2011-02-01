module HornetQ::Client
  class ProducerManager
    def initialize(session_pool, config, create_queues=false)
      @session_pool = session_pool
      @config = config
      # TODO: Should I keep this for performance for just use send below since it's less hackish?
      config.each do |key,value|
        # TODO: change based on configs
        body_serialize = 'Marshal.dump(obj)'
        msg_type = 'HornetQ::Client::Message::BYTES_TYPE'
        durable = !!value[:durable]
        eval <<-EOF
          def self.send_#{key}(obj)
            @session_pool.producer("#{value[:address]}") do |session, producer|
              message = session.create_message(#{msg_type}, #{durable})
              message.body = #{body_serialize}
              send_with_retry(producer, message)
            end
          end
        EOF
      end

      if create_queues
        @session_pool.session do |session|
          config.each_value do |queue_config|
            begin
              session.create_queue(queue_config[:address], queue_config[:queue], queue_config[:durable])
            rescue Java::org.hornetq.api.core.HornetQException => e
              raise unless e.cause.code == Java::org.hornetq.api.core.HornetQException::QUEUE_EXISTS
            end
          end
        end
      end
    end

    def send(queue, obj)
      queue_config = @config[queue]
      raise "Invalid queue #{queue}" unless queue_config
      @session_pool.producer(queue_config[:address]) do |session, producer|
        message = session.create_message(HornetQ::Client::Message::BYTES_TYPE, !!queue_config[:durable])
        message.body = Marshal.dump(obj)
        send_with_retry(producer, message)
      end
    end

    #######
    private
    #######

    def send_with_retry(producer, message)
      #message.put_string_property(Java::org.hornetq.api.core.SimpleString.new(HornetQ::Client::Message::HDR_DUPLICATE_DETECTION_ID.to_s), Java::org.hornetq.api.core.SimpleString.new("uniqueid#{i}"))
      begin
        producer.send(message)
      rescue Java::org.hornetq.api.core.HornetQException => e
        puts "Received producer exception: #{e.message} with code=#{e.cause.code}"
        if e.cause.code == Java::org.hornetq.api.core.HornetQException::UNBLOCKED
          puts "Retrying the send"
          retry
        end
      end
    end
  end
end