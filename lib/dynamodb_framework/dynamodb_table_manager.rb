module DynamoDbFramework
  class TableManager

    attr_reader :dynamodb

    def initialize(store)
      @dynamodb = store
    end

    def exists?(table_name)

      exists = true

      begin
        dynamodb.client.describe_table(:table_name => table_name)
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        exists = false
      end

      return exists

    end

    def has_index?(table_name, index_name)
      exists = true

      begin
        result = dynamodb.client.describe_table(:table_name => table_name)

        if result.table[:global_secondary_indexes] == nil
          return false
        end

        if result.table[:global_secondary_indexes].select { |i| i[:index_name] == index_name }.length > 0
          exists = true
        else
          exists = false
        end
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        exists = false
      end

      return exists
    end

    def update_throughput(table_name, read_capacity, write_capacity)

      if !exists?(table_name)
        raise "table: #{table_name}, does not exist."
      end

      table = {
          :table_name => table_name,
          :provisioned_throughput => {
              :read_capacity_units => read_capacity,
              :write_capacity_units => write_capacity
          }
      }

      dynamodb.client.update_table(table)

      # wait for table to be updated
      puts "waiting for table: [#{table_name}] to be updated..."
      wait_until_active(table_name)
      puts "table: [#{table_name}] updated!"

    end

    def add_index(table_name, attributes, global_index)

      attribute_definitions = []

      attributes.each do |a|
        attribute_definitions.push({ :attribute_name => a[:name], :attribute_type => a[:type] })
      end

      table = {
          :table_name => table_name,
          :attribute_definitions => attribute_definitions,
          :global_secondary_index_updates => [
              :create => global_index
          ]
      }

      dynamodb.client.update_table(table)

      # wait for table to be updated
      puts "Adding global index: #{global_index[:index_name]}..."
      wait_until_index_active(table_name, global_index[:index_name])
      puts "Index added!"
    end

    def update_index_throughput(table_name, index_name, read_capacity, write_capacity)
      table = {
          :table_name => table_name,
          :global_secondary_index_updates => [
              :update => {
                  :index_name => index_name,
                  :provisioned_throughput => {
                      :read_capacity_units => read_capacity,
                      :write_capacity_units => write_capacity
                  }
              }
          ]
      }

      dynamodb.client.update_table(table)

      # wait for table to be updated
      puts "Updating throughput for global index: #{index_name}..."
      puts "waiting for table: [#{table_name}] to be updated..."
      wait_until_active(table_name)
      puts "table: [#{table_name}] updated!"
    end

    def drop_index(table_name, index_name)
      table = {
          :table_name => table_name,
          :global_secondary_index_updates => [
              :delete => {
                  :index_name => index_name
              }
          ]
      }

      dynamodb.client.update_table(table)

      # wait for table to be updated
      puts "Deleting global index: #{index_name}..."
      wait_until_index_dropped(table_name, index_name)
      puts "Index: [#{index_name}] dropped!"
    end

    def get_status(table_name)
      result = dynamodb.client.describe_table(:table_name => table_name)
      return result.table[:table_status]
    end

    def get_index_status(table_name, index_name)
      result = dynamodb.client.describe_table(:table_name => table_name)

      if result.table[:global_secondary_indexes] == nil
        return nil
      end

      index = result.table[:global_secondary_indexes].select { |i| i[:index_name] == index_name }

      if index.length > 0
        return index[0][:index_status]
      end

      return nil
    end

    def wait_until_active(table_name)

      end_time = Time.now + 300
      while Time.now < end_time do

        status = get_status(table_name)

        if status == 'ACTIVE'
          return
        end

        sleep(5)
      end

      raise "Timeout occured while waiting for table: #{table_name}, to become active."

    end

    def wait_until_index_active(table_name, index_name)

      end_time = Time.now + 300
      while Time.now < end_time do

        status = get_index_status(table_name, index_name)

        if status == 'ACTIVE'
          return
        end

        sleep(5)
      end

      raise "Timeout occured while waiting for table: #{table_name}, index: #{index_name}, to become active."

    end

    def wait_until_index_dropped(table_name, index_name)

      end_time = Time.now + 300
      while Time.now < end_time do

        status = get_index_status(table_name, index_name)

        if status == nil
          return
        end

        sleep(5)
      end

      raise "Timeout occured while waiting for table: #{table_name}, index: #{index_name}, to be dropped."

    end

    def create(table_name, attributes, partition_key, range_key = nil, read_capacity = 20, write_capacity = 10, global_indexes = nil)

      if exists?(table_name)
        return
      end

      attribute_definitions = []

      attributes.each do |a|
        attribute_definitions.push({ :attribute_name => a[:name], :attribute_type => a[:type] })
      end

      key_schema = []
      key_schema.push({ :attribute_name => partition_key, :key_type => :HASH })
      if range_key != nil
        key_schema.push({ :attribute_name => range_key, :key_type => :RANGE })
      end

      table = {
          :table_name => table_name,
          :attribute_definitions => attribute_definitions,
          :key_schema => key_schema,
          :provisioned_throughput => {
              :read_capacity_units => read_capacity,
              :write_capacity_units => write_capacity
          }
      }

      if global_indexes != nil
        table[:global_secondary_indexes] = global_indexes
      end

      dynamodb.client.create_table(table)

      # wait for table to be created
      puts "waiting for table: [#{table_name}] to be created..."
      dynamodb.client.wait_until(:table_exists, table_name: table_name)
      puts "table: [#{table_name}] created!"
    end

    def create_table(options = {})

      if options[:name] == nil
        raise 'A valid table name must be specified.'
      end

      if exists?(options[:name])
        return
      end

      options[:read_capacity] ||= 20
      options[:write_capacity] ||= 20

      if !options[:attributes].is_a?(Array)
        raise 'A valid :attributes array must be specified.'
      end

      attribute_definitions = options[:attributes].map { |a| { :attribute_name => a[:name], :attribute_type => a[:type] } }

      hash_key = options[:attributes].detect { |a| a[:key] == :hash }
      if hash_key == nil
        raise 'No Hash Key attribute has been specified.'
      end

      range_key = options[:attributes].detect { |a| a[:key] == :range }

      key_schema = []
      key_schema.push({ :attribute_name => hash_key[:name], :key_type => :HASH })
      if range_key != nil
        key_schema.push({ :attribute_name => range_key[:name], :key_type => :RANGE })
      end

      table = {
          :table_name => options[:name],
          :attribute_definitions => attribute_definitions,
          :key_schema => key_schema,
          :provisioned_throughput => {
              :read_capacity_units => options[:read_capacity],
              :write_capacity_units => options[:write_capacity]
          }
      }

      if options[:global_indexes] != nil
        table[:global_secondary_indexes] = options[:global_indexes]
      end

      dynamodb.client.create_table(table)

      # wait for table to be created
      puts "waiting for table: [#{options[:name]}] to be created..."
      dynamodb.client.wait_until(:table_exists, table_name: options[:name])
      puts "table: [#{options[:name]}] created!"
    end

    def create_global_index(name, partition_key, range_key = nil, read_capacity = 20, write_capacity = 10)

      key_schema = []

      key_schema.push({ :attribute_name => partition_key, :key_type => :HASH })
      if range_key != nil
        key_schema.push({ :attribute_name => range_key, :key_type => :RANGE })
      end

      index = {
          :index_name => name,
          :key_schema => key_schema,
          :projection => {
              :projection_type => :ALL
          },
          :provisioned_throughput => {
              :read_capacity_units => read_capacity,
              :write_capacity_units => write_capacity,
          }
      }

      return index
    end

    def drop(table_name)

      if !exists?(table_name)
        return
      end

      puts "dropping table: [#{table_name}] ..."
      dynamodb.client.delete_table({ table_name: table_name })
      puts "table: [#{table_name}] dropped!"
    end

    def drop_table(table_name)

      if !exists?(table_name)
        return
      end

      puts "dropping table: [#{table_name}] ..."
      dynamodb.client.delete_table({ table_name: table_name })
      puts "table: [#{table_name}] dropped!"
    end

  end
end
