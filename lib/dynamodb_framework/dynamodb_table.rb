module DynamoDbFramework
  module Table

    class InvalidConfigException < StandardError
      def initialize(message)
        super(message)
      end
    end

    def config
      details = {
          table_name: self.instance_variable_get(:@table_name),
          partition_key: self.instance_variable_get(:@partition_key)
      }
      if self.instance_variable_defined?(:@range_key)
        details[:range_key] = self.instance_variable_get(:@range_key)
      end
      details
    end

    def table_name(value)
      self.instance_variable_set(:@table_name, value)
    end

    def partition_key(field, type)
      self.instance_variable_set(:@partition_key, { field: field, type: type })
    end

    def range_key(field, type)
      self.instance_variable_set(:@range_key, { field: field, type: type })
    end

    def create(store:, read_capacity: 25, write_capacity: 25)
      unless self.instance_variable_defined?(:@table_name)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Table name must be specified.')
      end
      table_name = self.instance_variable_get(:@table_name)

      unless self.instance_variable_defined?(:@partition_key)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Partition key must be specified.')
      end
      partition_key = self.instance_variable_get(:@partition_key)

      if self.instance_variable_defined?(:@range_key)
        range_key = self.instance_variable_get(:@range_key)
      end

      builder = DynamoDbFramework::AttributesBuilder.new
      builder.add({ name: partition_key[:field], type: partition_key[:type], key: :partition })
      if range_key != nil
        builder.add({ name: range_key[:field], type: range_key[:type], key: :range })
      end

      DynamoDbFramework::TableManager.new(store).create_table({ name: table_name, attributes: builder.attributes, read_capacity: read_capacity, write_capacity: write_capacity })
    end

    def update(store:, read_capacity:, write_capacity:)
      unless self.instance_variable_defined?(:@table_name)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Table name must be specified.')
      end
      table_name = self.instance_variable_get(:@table_name)

      DynamoDbFramework::TableManager.new(store).update_throughput(table_name, read_capacity, write_capacity)
    end

    def query(partition:)
      DynamoDbFramework::Query.new(table_name: config[:table_name], partition_key: config[:partition_key][:field], partition_value: partition)
    end

    def all(store:)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]
      repository.all
    end

    def put_item(store:, item:)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]
      repository.put(item)
    end

    def get_item(store:, partition:, range: nil)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]

      if range != nil
        repository.get_by_key(config[:partition_key][:field], partition, config[:range_key][:field], range)
      else
        repository.get_by_key(config[:partition_key][:field], partition)
      end
    end

    def delete_item(store:, partition:, range: nil)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]

      if range != nil
        range_key = config[:range_key][:field]
      end

      repository.delete_item(partition_key: config[:partition_key][:field], partition_key_value: partition, range_key: range_key, range_key_value: range)
    end

  end
end