require 'logger'

module DynamoDbFramework

  def self.logger
    @logger ||= Logger.new(STDOUT)

    return @logger
  end

end