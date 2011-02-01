module HornetQ
  module Client
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core-client'
      HornetQ.require_jar 'netty'
      require 'hornetq/client/org_hornetq_api_core_client_client_session'
      require 'hornetq/client/org_hornetq_core_client_impl_client_message_impl'
      require 'hornetq/client/org_hornetq_utils_typed_properties'

      # Import Message Constants
      import Java::org.hornetq.api.core::Message
    end
  end
end

require 'hornetq/client/factory'
require 'hornetq/client/requestor'
require 'hornetq/client/server'
require 'hornetq/client/producer_manager'
require 'hornetq/client/consumer_manager'
require 'hornetq/client/session_manager'
