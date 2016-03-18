class TestMigrationScript1 < MigrationScript

  def initialize
    @timestamp = '20160318110710'
  end

  def apply

    table_manager = DynamoDbTableManager.new
    builder = DynamoDbAttributesBuilder.new
    builder.add(:id, :S)
    table_manager.create('test1', builder.attributes, :id)

  end

  def undo

    table_manager = DynamoDbTableManager.new
    table_manager.drop('test1')

  end

end