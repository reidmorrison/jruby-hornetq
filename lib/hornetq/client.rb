HornetQ.require_jar 'hornetq-core-client'
HornetQ.require_jar 'netty'

module HornetQ
  module Client
    # Import Message Constants
    java_import Java::org.hornetq.api.core::Message
  end
end

require 'hornetq/client/connection'
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
