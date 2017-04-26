class ExampleIndex
  extend DynamoDbFramework::Index

  index_name 'example_index'
  table ExampleTable
  partition_key :name, :S
  range_key :timestamp, :N

end

class ExampleIndexWithoutIndexName
  extend DynamoDbFramework::Index

  table ExampleTable
  partition_key :name, :S
  range_key :timestamp, :N

end

class ExampleIndexWithoutTable
  extend DynamoDbFramework::Index

  index_name 'example_index'
  partition_key :name, :S
  range_key :timestamp, :N

end

class ExampleIndexWithoutPartitionKey
  extend DynamoDbFramework::Index

  table ExampleTable
  index_name 'example_index'
  range_key :timestamp, :N

end

class ExampleIndexWithoutRangeKey
  extend DynamoDbFramework::Index

  index_name 'example_index'
  table ExampleTable
  partition_key :name, :S

end