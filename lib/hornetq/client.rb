module HornetQ
  module Client
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core-client'
      HornetQ.require_jar 'netty'
      require 'hornetq/common/org_hornetq_core_logging_logger'
      require 'hornetq/client/org_hornetq_api_core_client_client_session'
      require 'hornetq/client/org_hornetq_core_client_impl_client_message_impl'
      require 'hornetq/client/org_hornetq_core_client_impl_client_consumer_impl'
      require 'hornetq/client/org_hornetq_core_client_impl_client_producer_impl'
      require 'hornetq/client/org_hornetq_utils_typed_properties'
      require 'hornetq/common/logging'
      require 'hornetq/common/log_delegate'
      require 'hornetq/client/message_handler'
      require 'hornetq/client/requestor_pattern'
      require 'hornetq/client/server_pattern'

      # Import Message Constants
      import Java::org.hornetq.api.core::Message
    end
  end
end

require 'hornetq/client/factory'
require 'hornetq/client/producer_manager'
require 'hornetq/client/consumer_manager'
require 'hornetq/client/session_manager'
