module HornetQ::Server

  class Factory
    def self.create_server(uri)
      HornetQ::Server.load_requirements
      return HornetQ::URI.new(uri).create_server
    end
  end
end
