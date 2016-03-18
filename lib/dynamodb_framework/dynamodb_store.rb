class DynamoDbStore
  attr_reader :client

  def initialize
    region = ENV['DYNAMODB_REGION']
    endpoint = ENV['DYNAMODB_ENDPOINT']
    secret = ENV['DYNAMODB_SECRET']
    key = ENV['DYNAMODB_ACCESS_KEY']
    if endpoint != nil
      @client = Aws::DynamoDB::Client.new(region: region, endpoint: endpoint, secret_access_key: secret, access_key_id: key)
    else
      @client = Aws::DynamoDB::Client.new(region: region, secret_access_key: secret, access_key_id: key)
    end
  end

end