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

  end
end