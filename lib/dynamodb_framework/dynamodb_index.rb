module DynamoDbFramework
  module Index

    class InvalidConfigException < StandardError
      def initialize(message)
        super(message)
      end
    end

    def config
      details = {
          index_name: full_index_name,
          table: self.instance_variable_get(:@table),
          partition_key: self.instance_variable_get(:@partition_key)
      }
      if self.instance_variable_defined?(:@range_key)
        details[:range_key] = self.instance_variable_get(:@range_key)
      end
      details
    end

    def index_name(value)
      self.instance_variable_set(:@index_name, value)
    end

    def full_index_name
      unless self.instance_variable_defined?(:@index_name)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Index name must be specified.')
      end
      index_name = self.instance_variable_get(:@index_name)
      if DynamoDbFramework.namespace != nil
        index_name = "#{DynamoDbFramework.namespace}#{DynamoDbFramework.namespace_delimiter}#{index_name}"
      end
      index_name
    end

    def table(value)
      self.instance_variable_set(:@table, value)
    end

    def partition_key(field, type)
      self.instance_variable_set(:@partition_key, { field: field, type: type })
    end

    def range_key(field, type)
      self.instance_variable_set(:@range_key, { field: field, type: type })
    end

    def create(store:, read_capacity: 25, write_capacity: 25)
      unless self.instance_variable_defined?(:@table)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Table must be specified.')
      end
      table = self.instance_variable_get(:@table)
      table_name = table.config[:table_name]

      unless self.instance_variable_defined?(:@partition_key)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Partition key must be specified.')
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
      if partition_key[:field] != table.config[:partition_key][:field] && range_key != nil && range_key[:field] != table.config[:partition_key][:field]
        builder.add({ name: table.config[:partition_key][:field], type: table.config[:partition_key][:type] })
      end
      if table.config[:range_key] != nil && partition_key[:field] != table.config[:range_key][:field] && range_key != nil && range_key[:field] != table.config[:range_key][:field]
        builder.add({ name: table.config[:range_key][:field], type: table.config[:range_key][:type] })
      end

      table_manager = DynamoDbFramework::TableManager.new(store)

      range_key_field = range_key[:field] unless range_key == nil

      index =table_manager.create_global_index(full_index_name, partition_key[:field], range_key_field, read_capacity, write_capacity)

      table_manager.add_index(table_name, builder.attributes, index)
    end

    def update(store:, read_capacity:, write_capacity:)
      unless self.instance_variable_defined?(:@table)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Table must be specified.')
      end
      table = self.instance_variable_get(:@table)

      DynamoDbFramework::TableManager.new(store).update_index_throughput(table.config[:table_name], full_index_name, read_capacity, write_capacity)
    end

    def drop(store:)
      unless self.instance_variable_defined?(:@table)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Table must be specified.')
      end
      table = self.instance_variable_get(:@table)
      table_name = table.config[:table_name]

      DynamoDbFramework::TableManager.new(store).drop_index(table_name, full_index_name)
    end

    def exists?(store:)
      unless self.instance_variable_defined?(:@table)
        raise DynamoDbFramework::Index::InvalidConfigException.new('Table must be specified.')
      end
      table = self.instance_variable_get(:@table)
      table_name = table.config[:table_name]
      DynamoDbFramework::TableManager.new(store).has_index?(table_name, full_index_name)
    end

    def query(partition:)
      DynamoDbFramework::Query.new(index_name: config[:index_name], table_name: config[:table].config[:table_name], partition_key: config[:partition_key][:field], partition_value: partition)
    end

  end
end