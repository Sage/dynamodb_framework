module DynamoDbFramework
  module Table

    class InvalidConfigException < StandardError
      def initialize(message)
        super(message)
      end
    end

    def config
      details = {
          table_name: full_table_name,
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

    def full_table_name
      unless self.instance_variable_defined?(:@table_name)
        raise DynamoDbFramework::Table::InvalidConfigException.new('Table name must be specified.')
      end
      table_name = self.instance_variable_get(:@table_name)
      if DynamoDbFramework.namespace != nil
        table_name = "#{DynamoDbFramework.namespace}#{DynamoDbFramework.namespace_delimiter}#{table_name}"
      end
      table_name
    end

    def partition_key(field, type)
      self.instance_variable_set(:@partition_key, { field: field, type: type })
    end

    def range_key(field, type)
      self.instance_variable_set(:@range_key, { field: field, type: type })
    end

    def create(store: DynamoDbFramework.default_store, read_capacity: 25, write_capacity: 25, indexes: [])

      #make method idempotent
      if exists?(store: store)
        wait_until_active(store: store)
        return
      end

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

      global_indexes = nil
      if indexes != nil && indexes.length > 0
        global_indexes = []
        indexes.each do |i|
          global_indexes << i.create(store: store, submit: false)
          index_partition_key = i.instance_variable_get(:@partition_key)
          unless builder.contains(name: index_partition_key[:field])
            builder.add({ name: index_partition_key[:field], type: index_partition_key[:type] })
          end
          if i.instance_variable_defined?(:@range_key)
            index_range_key = i.instance_variable_get(:@range_key)
            unless builder.contains(name: index_range_key[:field])
              builder.add({ name: index_range_key[:field], type: index_range_key[:type] })
            end
          end

        end
      end

      DynamoDbFramework::TableManager.new(store).create_table({ name: full_table_name, attributes: builder.attributes, read_capacity: read_capacity, write_capacity: write_capacity, global_indexes: global_indexes })
    end

    def update(store: DynamoDbFramework.default_store, read_capacity:, write_capacity:)
      DynamoDbFramework::TableManager.new(store).update_throughput(full_table_name, read_capacity, write_capacity)
    end

    def drop(store: DynamoDbFramework.default_store)
      unless exists?(store: store)
        return
      end
      DynamoDbFramework::TableManager.new(store).drop(full_table_name)
    end

    def exists?(store: DynamoDbFramework.default_store)
      DynamoDbFramework::TableManager.new(store).exists?(full_table_name)
    end

    def wait_until_active(store: DynamoDbFramework.default_store)
      DynamoDbFramework::TableManager.new(store).wait_until_active(full_table_name)
    end

    def get_status(store: DynamoDbFramework.default_store)
      DynamoDbFramework::TableManager.new(store).get_status(full_table_name)
    end

    def active?(store: DynamoDbFramework.default_store)
      DynamoDbFramework::TableManager.new(store).get_status(full_table_name) == 'ACTIVE'
    end

    def query(partition:)
      DynamoDbFramework::Query.new(table_name: config[:table_name], partition_key: config[:partition_key][:field], partition_value: partition)
    end

    def all(store: DynamoDbFramework.default_store)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]
      repository.all
    end

    def put_item(store: DynamoDbFramework.default_store, item:)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]
      repository.put(item)
    end

    def get_item(store: DynamoDbFramework.default_store, partition:, range: nil)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]

      if range != nil
        repository.get_by_key(config[:partition_key][:field], partition, config[:range_key][:field], range)
      else
        repository.get_by_key(config[:partition_key][:field], partition)
      end
    end

    def delete_item(store: DynamoDbFramework.default_store, partition:, range: nil)
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = config[:table_name]

      if range != nil
        range_key = config[:range_key][:field]
      end

      repository.delete_item(partition_key: config[:partition_key][:field], partition_key_value: partition, range_key: range_key, range_key_value: range)
    end

  end
end