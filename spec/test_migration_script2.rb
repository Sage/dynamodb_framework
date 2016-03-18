class TestMigrationScript2 < MigrationScript

  def initialize
    @timestamp = '20160318110730'
  end

  def apply

    table_manager = DynamoDbTableManager.new
    builder = DynamoDbAttributesBuilder.new
    builder.add(:id, :S)
    table_manager.create('test2', builder.attributes, :id)

  end

  def undo

    table_manager = DynamoDbTableManager.new
    table_manager.drop('test2')

  end

end