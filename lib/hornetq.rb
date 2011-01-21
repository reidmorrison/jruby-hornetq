require 'hornetq/server'
require 'hornetq/client'

module HornetQ
  # Allow override of our included jars so we don't have to keep up with hornetq releases
  def self.require_jar(jar_name)
    if ENV['HORNETQ_HOME']
      require "#{ENV['HORNETQ_HOME']}/lib/#{jar_name}.jar"
    else
      require "hornetq/java/#{jar_name}.jar"
    end
  end
end
