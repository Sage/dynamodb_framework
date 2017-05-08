require 'hash_kit'
require 'json'
require_relative 'dynamodb_framework/version'
require_relative 'dynamodb_framework/dynamodb_attributes_builder'
require_relative 'dynamodb_framework/dynamodb_store'
require_relative 'dynamodb_framework/dynamodb_table_manager'
require_relative 'dynamodb_framework/dynamodb_repository'
require_relative 'dynamodb_framework/dynamodb_migration_manager'
require_relative 'dynamodb_framework/dynamodb_migration_script'
require_relative 'dynamodb_framework/dynamodb_logger'
require_relative 'dynamodb_framework/hash_helper'
require_relative 'dynamodb_framework/dynamodb_namespace_migration_manager'
require_relative 'dynamodb_framework/dynamodb_table'
require_relative 'dynamodb_framework/dynamodb_index'
require_relative 'dynamodb_framework/dynamodb_query'

require 'date'

module DynamoDbFramework
  def self.namespace=(value)
    @namespace = value
  end
  def self.namespace
    @namespace
  end
  def self.namespace_delimiter=(value)
    @namespace_delimiter = value
  end
  def self.namespace_delimiter
    @namespace_delimiter ||= '.'
  end
  def self.default_store=(value)
    unless value.is_a?(DynamoDbFramework::Store)
      raise 'Invalid default store specified. Store must be of type: [DynamoDbFramework::Store]'
    end
    @default_store = value
  end
  def self.default_store
    @default_store ||= DynamoDbFramework::Store.new
  end
end
