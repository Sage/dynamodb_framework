require 'logger'

module DynamoDbFramework

  def self.logger
    return @@logger
  end

  def self.set_logger(logger)
    @@logger = logger
  end

  DynamoDbFramework.set_logger(Logger.new(STDOUT))

end