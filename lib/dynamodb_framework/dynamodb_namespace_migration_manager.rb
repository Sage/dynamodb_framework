module DynamoDbFramework
  module Namespace
    class MigrationManager

      attr_reader :dynamodb_table_manager
      attr_reader :dynamodb_repository

      def initialize(store)
        @dynamodb_repository = DynamoDbFramework::Repository.new(store)
        @dynamodb_table_manager = DynamoDbFramework::TableManager.new(store)
      end

      def connect

        DynamoDbFramework.logger.info "[#{self.class}] - Connecting to DynamoDb instance"

        migration_table_name = 'dynamodb_framework_migration_history'

        #check if migration table exists
        if !@dynamodb_table_manager.exists?(migration_table_name)
          #migration table not found so create it
          builder = DynamoDbFramework::AttributesBuilder.new
          builder.add(:namespace, :S, :partition)
          builder.add(:timestamp, :S, :range)
          @dynamodb_table_manager.create_table(name: migration_table_name, attributes: builder.attributes)
        end

        #set the table name for the repository
        @dynamodb_repository.table_name = migration_table_name

        DynamoDbFramework.logger.info "[#{self.class}] - Connected."

      end

      def get_executed_scripts(namespace)
        scripts = @dynamodb_repository.query(:namespace, namespace)
        if scripts.length > 0
          return scripts.sort { |a,b| b['timestamp'] <=> a['timestamp'] }.map { |i| i['timestamp'] }
        end

        return nil
      end

      def apply(namespace)

        DynamoDbFramework.logger.info "[#{self.class}] - Applying migration scripts"

        executed_scripts = get_executed_scripts(namespace)

        scripts = []
        DynamoDbFramework::MigrationScript.descendants.each do |ms|
          script = ms.new
          scripts.push(script)
        end

        scripts.sort { |a,b| a.timestamp <=> b.timestamp }.each do |script|
          if executed_scripts == nil || !executed_scripts.include?(script.timestamp)
            DynamoDbFramework.logger.info "[#{self.class}] - Applying script: #{script.timestamp}....."
            script.apply
            @dynamodb_repository.put({ :timestamp => script.timestamp, :namespace => script.namespace })
          end
        end

        DynamoDbFramework.logger.info "[#{self.class}] - Migration scripts applied."

      end

      def rollback(namespace)

        DynamoDbFramework.logger.info "[#{self.class}] - Rolling back started."

        executed_scripts = get_executed_scripts(namespace)

        scripts = []
        DynamoDbFramework::MigrationScript.descendants.each do |ms|
          script = ms.new
          scripts.push(script)
        end

        scripts.sort { |a,b| a.timestamp <=> b.timestamp }.each do |script|
          if executed_scripts != nil && executed_scripts.length > 0 && executed_scripts.include?(script.timestamp)
            script.undo
            @dynamodb_repository.delete({ :timestamp => script.timestamp, :namespace => script.namespace })
            return
          end
        end

        DynamoDbFramework.logger.info "[#{self.class}] - Rollback complete."

      end

    end
  end
end
