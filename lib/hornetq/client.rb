module HornetQ
  module Client
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core-client'
      HornetQ.require_jar 'netty'
      require 'hornetq/org_hornetq_api_core_client_client_session'
      require 'hornetq/org_hornetq_core_client_impl_client_message_impl'
      require 'hornetq/org_hornetq_utils_typed_properties'
    end
  end
end

require 'hornetq/client/factory'
require 'hornetq/client/requestor'
require 'hornetq/client/server'
require 'hornetq/client/session_pool'
