module HornetQ::Client
  class ConsumerManager
    def initialize(factory, session_config, queues_config)
      @session_manager = SessionManager.new(factory, session_config)
      @queues_config = queues_config
    end

    def each(queue, &block)
      config = @queues_config[queue]
      raise "Unknown queue #{queue}" unless config
      queue_name = config[:queue]
      @session_manager.session do |session|
        consumer = session.create_consumer(queue_name)
        begin
          while msg = consumer.receive do
            # TODO: change based on configs
            obj = Marshal.load(msg.body)
            yield obj
            msg.acknowledge
          end
        rescue Java::org.hornetq.api.core.HornetQException => e
          raise unless e.cause.code == Java::org.hornetq.api.core.HornetQException::OBJECT_CLOSED
        end
      end
    end

    def close
      @session_manager.close
    end
  end
end
