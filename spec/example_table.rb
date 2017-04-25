class ExampleTable
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S
  range_key :timestamp, :N
  read_capacity 50
  write_capacity 25

end

class ExampleTableWithoutTableName
  extend DynamoDbFramework::Table

  partition_key :id, :S
  range_key :timestamp, :N
  read_capacity 50
  write_capacity 25

end

class ExampleTableWithoutPartitionKey
  extend DynamoDbFramework::Table

  table_name 'example'
  range_key :timestamp, :N
  read_capacity 50
  write_capacity 25

end

class ExampleTableWithoutRangeKey
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S
  read_capacity 50
  write_capacity 25

end

class ExampleTableWithoutReadCapacity
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S
  range_key :timestamp, :N
  write_capacity 25

end

class ExampleTableWithoutWriteCapacity
  extend DynamoDbFramework::Table

  table_name 'example'
  partition_key :id, :S
  range_key :timestamp, :N
  read_capacity 50

end