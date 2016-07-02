module DynamoDbFramework
  class Store
    attr_reader :client

    def initialize(options = {})

      if options.has_key?(:endpoint)
        @client = Aws::DynamoDB::Client.new(region: options[:aws_region], endpoint: options[:endpoint])
      else
        @client = Aws::DynamoDB::Client.new
      end

    end

  end
end
