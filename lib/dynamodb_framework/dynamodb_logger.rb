require 'logger'

module DynamoDbFramework

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.set_logger(logger)
    @@logger = logger
  end

end