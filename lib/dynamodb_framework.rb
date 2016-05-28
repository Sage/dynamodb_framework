require "dynamodb_framework/version"
require "dynamodb_framework/dynamodb_attributes_builder"
require "dynamodb_framework/dynamodb_store"
require "dynamodb_framework/dynamodb_table_manager"
require "dynamodb_framework/dynamodb_repository"
require "dynamodb_framework/dynamodb_migration_manager"
require "dynamodb_framework/dynamodb_migration_script"

module DynamodbFramework
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new(STDOUT).tap do |log|
        log.formatter = ->(severity, datetime, progname, msg) {
          "#{severity}: #{msg}\n"
        }
      end
    end
  end
end

DynamodbFramework.logger.level = Logger::INFO
