class DynamoDbMigrationManager

  attr_reader :dynamodb_table_manager
  attr_reader :dynamodb_repository

  def initialize
    @dynamodb_repository = DynamoDbRepository.new
    @dynamodb_table_manager = DynamoDbTableManager.new
  end

  def connect

    puts 'Connecting to DynamoDb instance.....'

    migration_table_name = 'dynamodb_migrations'

    #check if migration table exists
    if !@dynamodb_table_manager.exists?(migration_table_name)
      #migration table not found so create it
      builder = DynamoDbAttributesBuilder.new
      builder.add(:timestamp, :S)
      @dynamodb_table_manager.create(migration_table_name, builder.attributes, :timestamp)
    end

    #set the table name for the repository
    @dynamodb_repository.table_name = migration_table_name

    puts 'Connected.'

  end

  def get_executed_scripts
    scripts = @dynamodb_repository.all()
    if scripts.length > 0
      return scripts.sort { |a,b| b['timestamp'] <=> a['timestamp'] }.map { |i| i['timestamp'] }
    end

    return nil
  end

  def apply

    puts 'Applying migration scripts.....'

    executed_scripts = get_executed_scripts()

    scripts = []
    MigrationScript.descendants.each do |ms|
      script = ms.new
      scripts.push(script)
    end

    scripts.sort { |a,b| a.timestamp <=> b.timestamp }.each do |script|
      if executed_scripts == nil || !executed_scripts.include?(script.timestamp)
        puts 'Applying script: ' + script.timestamp + '.....'
        script.apply
        @dynamodb_repository.put({ :timestamp => script.timestamp })
      end
    end

    puts 'Migration scripts applied.'

  end

  def rollback

    puts 'Rolling back last migration script.....'

    executed_scripts = get_executed_scripts()

    scripts = []
    MigrationScript.descendants.each do |ms|
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

    puts 'Completed.'

  end

end