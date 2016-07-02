class TestMigrationScript2 < DynamoDbFramework::MigrationScript

  def initialize
    @timestamp = '20160318110730'
    @store = DynamoDbFramework::Store.new({ endpoint: 'http://localhost:8000', aws_region: 'eu-west-1' })
    @table_manager = DynamoDbFramework::TableManager.new(@store)
  end

  def apply

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:id, :S)
    @table_manager.create('test2', builder.attributes, :id)

  end

  def undo

    @table_manager.drop('test2')

  end

end