module HornetQ
  module Server
    # Only load as needed
    def self.load_requirements
      HornetQ.require_jar 'hornetq-core'
      HornetQ.require_jar 'netty'
      require 'hornetq/server/org_hornetq_core_server_hornet_q_server'
    end
  end
end

require 'hornetq/server/factory'
