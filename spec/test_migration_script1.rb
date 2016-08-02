class TestMigrationScript1 < DynamoDbFramework::MigrationScript

  def initialize
    @timestamp = '20160318110710'
    @namespace = 'test_namespace'
    @store = DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
    @table_manager = DynamoDbFramework::TableManager.new(@store)
  end

  def apply

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add({ name: :id, type: :string, key: :hash })
    @table_manager.create_table({ name: 'test1', attributes: builder.attributes })

  end

  def undo

    @table_manager.drop('test1')

  end

end
