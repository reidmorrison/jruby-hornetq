# TODO Support send(String)
# TODO Support send(:data => string, :durable=>true, :address=>'MyAddress')
#
# See: http://hornetq.sourceforge.net/docs/hornetq-2.1.2.Final/api/index.html?org/hornetq/api/core/client/ClientProducer.html
#
# Other methods still directly accessible through this class:
#
# void   send(Message message)
#          Sends a message to an address
# void   send(String address, Message message)
#          Sends a message to the specified address instead of the ClientProducer's address
#
#  close()
#          Closes the ClientProducer
# boolean   closed?
#          Returns whether the producer is closed or not
#
# SimpleString   address()
#          Returns the address where messages will be sent
#
# int   max_rate()
#          Returns the maximum rate at which a ClientProducer can send messages per second
#
# boolean   block_on_durable_send?
#          Returns whether the producer will block when sending durable messages
# boolean   block_on_non_durable_send?
#          Returns whether the producer will block when sending non-durable messages
#
class Java::org.hornetq.core.client.impl::ClientProducerImpl
  def send_with_retry(message)
    first_time = true
    begin
      send(message)
    rescue Java::org.hornetq.api.core.HornetQException => e
      HornetQ.logger.warn "Received producer exception: #{e.message} with code=#{e.cause.code}"
      if first_time && e.cause.code == Java::org.hornetq.api.core.HornetQException::UNBLOCKED
        HornetQ.logger.info "Retrying the send"
        first_time = false
        retry
      else
        raise
      end
    end
  end
end