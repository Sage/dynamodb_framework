class ExampleTable
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S
  range_key :timestamp, :N

end

class ExampleTable2
  extend DynamoDbFramework::Table

  table_name 'example2'
  partition_key :name, :S
  range_key :id, :S

end

class ExampleTableWithoutTableName
  extend DynamoDbFramework::Table

  partition_key :id, :S
  range_key :timestamp, :N

end

class ExampleTableWithoutPartitionKey
  extend DynamoDbFramework::Table

  table_name 'example'
  range_key :timestamp, :N

end

class ExampleTableWithoutRangeKey
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S

end