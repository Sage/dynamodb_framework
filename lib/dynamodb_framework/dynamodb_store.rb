module DynamoDbFramework
  class Store
    attr_reader :client

    def initialize(options = {})
=begin
      if options.has_key?(:endpoint)
        @client = Aws::DynamoDB::Client.new(region: options[:aws_region], endpoint: options[:endpoint], secret_access_key: options[:aws_secret], access_key_id: options[:aws_key])
      elsif options.has_key?(:aws_secret)
        @client = Aws::DynamoDB::Client.new(region: options[:aws_region], secret_access_key: options[:aws_secret], access_key_id: options[:aws_key])
      else
        @client = Aws::DynamoDB::Client.new
      end
=end

      if options.has_key?(:endpoint)
        @client = Aws::DynamoDB::Client.new(region: options[:aws_region], endpoint: options[:endpoint])
      else
        @client = Aws::DynamoDB::Client.new
      end

    end

  end
end
