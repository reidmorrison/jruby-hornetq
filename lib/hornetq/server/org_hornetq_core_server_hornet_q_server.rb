# Add methods to Server Interface
module Java::org.hornetq.core.server::HornetQServer

  # Shutdown the server when a typical interrupt signal (1,2,15) is caught
  def enable_shutdown_on_signal
    ['HUP', 'INT', 'TERM'].each do |signal_name|
      Signal.trap(signal_name) do
        HornetQ.logger.info "Caught #{signal_name}, stopping server"
        stop
      end
    end
  end
end
