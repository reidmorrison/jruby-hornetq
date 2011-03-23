# TODO Support send(String)
# TODO Support send(:data => string, :durable=>true, :address=>'MyAddress')
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