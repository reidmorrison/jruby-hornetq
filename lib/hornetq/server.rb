module HornetQ
  module Server
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core'
      HornetQ.require_jar 'netty'
      require 'hornetq/org_hornetq_core_server_hornet_q_server'
      require 'hornetq/org_hornetq_core_server_hornet_q_servers'
    end
  end
end

require 'hornetq/server/factory'
