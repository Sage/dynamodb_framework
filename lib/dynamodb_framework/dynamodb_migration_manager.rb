module DynamoDbFramework
  class MigrationManager

    attr_reader :dynamodb_table_manager
    attr_reader :dynamodb_repository

    def initialize(store)
      @dynamodb_repository = DynamoDbFramework::Repository.new(store)
      @dynamodb_table_manager = DynamoDbFramework::TableManager.new(store)
    end

    def connect

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Connecting to DynamoDb instance'

      migration_table_name = 'dynamodb_framework_migrations'

      #check if migration table exists
      if !@dynamodb_table_manager.exists?(migration_table_name)
        #migration table not found so create it
        builder = DynamoDbFramework::AttributesBuilder.new
        builder.add(:timestamp, :S)
        @dynamodb_table_manager.create(migration_table_name, builder.attributes, :timestamp)
      end

      #set the table name for the repository
      @dynamodb_repository.table_name = migration_table_name

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Connected.'

    end

    def get_executed_scripts
      scripts = @dynamodb_repository.all()
      if scripts.length > 0
        return scripts.sort { |a,b| b['timestamp'] <=> a['timestamp'] }.map { |i| i['timestamp'] }
      end

      return nil
    end

    def apply

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Applying migration scripts'

      executed_scripts = get_executed_scripts()

      scripts = []
      DynamoDbFramework::MigrationScript.descendants.each do |ms|
        script = ms.new
        scripts.push(script)
      end

      scripts.sort { |a,b| a.timestamp <=> b.timestamp }.each do |script|
        if executed_scripts == nil || !executed_scripts.include?(script.timestamp)
          DynamoDbFramework.logger.info '[DynamoDbFramework] - Applying script: ' + script.timestamp + '.....'
          script.apply
          @dynamodb_repository.put({ :timestamp => script.timestamp })
        end
      end

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Migration scripts applied.'

    end

    def rollback

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Rolling back started.'

      executed_scripts = get_executed_scripts()

      scripts = []
      DynamoDbFramework::MigrationScript.descendants.each do |ms|
        script = ms.new
        scripts.push(script)
      end

      scripts.sort { |a,b| a.timestamp <=> b.timestamp }.each do |script|
        if executed_scripts != nil && executed_scripts.length > 0 && executed_scripts.include?(script.timestamp)
          script.undo
          @dynamodb_repository.delete({ :timestamp => script.timestamp })
          return
        end
      end

      DynamoDbFramework.logger.info '[DynamoDbFramework] - Rollback complete.'

    end

  end
end
