require "rubygems"
require "bundler"
require 'aws-sdk-core'
require 'dynamodb_framework'
require_relative '../spec/test_migration_script1'
require_relative '../spec/test_migration_script2'
require_relative '../spec/test_item.rb'
require 'pry'

DYNAMODB_STORE_ENDPOINT = 'http://localhost:8000'

Aws.config[:credentials] = Aws::Credentials.new('test_key', 'test_secret')
Aws.config[:region] = 'eu-west-1'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :defined
end
