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
          partition_key: self.instance_variable_get(:@partition_key),
          read_capacity: self.instance_variable_get(:@read_capacity),
          write_capacity: self.instance_variable_get(:@write_capacity)
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

    def read_capacity(value)
      self.instance_variable_set(:@read_capacity, value)
    end

    def write_capacity(value)
      self.instance_variable_set(:@write_capacity, value)
    end

    def create(store:)
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

      unless self.instance_variable_defined?(:@read_capacity)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Read capacity must be specified.')
      end
      read_capacity = self.instance_variable_get(:@read_capacity)

      unless self.instance_variable_defined?(:@write_capacity)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Write capacity must be specified.')
      end
      write_capacity = self.instance_variable_get(:@write_capacity)

      builder = DynamoDbFramework::AttributesBuilder.new
      builder.add({ name: partition_key[:field], type: partition_key[:type], key: :partition })
      if range_key != nil
        builder.add({ name: range_key[:field], type: range_key[:type], key: :range })
      end

      DynamoDbFramework::TableManager.new(store).create_table({ name: table_name, attributes: builder.attributes, read_capacity: read_capacity, write_capacity: write_capacity })
    end

    def update(store:)
      unless self.instance_variable_defined?(:@table_name)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Table name must be specified.')
      end
      table_name = self.instance_variable_get(:@table_name)

      unless self.instance_variable_defined?(:@read_capacity)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Read capacity must be specified.')
      end
      read_capacity = self.instance_variable_get(:@read_capacity)

      unless self.instance_variable_defined?(:@write_capacity)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Write capacity must be specified.')
      end
      write_capacity = self.instance_variable_get(:@write_capacity)

      DynamoDbFramework::TableManager.new(store).update_throughput(table_name, read_capacity, write_capacity)
    end

  end
end