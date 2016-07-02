require 'date'

module DynamoDbFramework
  class Repository

    attr_reader :dynamodb
    attr_accessor :table_name

    def initialize(store)
      @dynamodb = store
    end

    def put(item)

      hash = to_hash(item)

      params =
          {
              table_name: @table_name,
              item: hash
          }

      dynamodb.client.put_item(params)

      return true

    end

    def delete(keys)

      params =
          {
              table_name: @table_name,
              key: keys
          }

      dynamodb.client.delete_item(params)

      return true

    end

    def get_by_key(partition_key, partition_value, range_key = nil, range_value = nil)

      key = {}
      key[partition_key] = partition_value
      if(range_key != nil)
        key[range_key] = range_value
      end

      params = {
          table_name: table_name,
          key: key
      }

      result = dynamodb.client.get_item(params)
      return result.item

    end

    def all

      result = dynamodb.client.scan({
                                        :table_name => @table_name
                                    })

      output = []
      result.items.each do |item|
        output.push(item)
      end

      return output

    end

    def scan(expression, expression_params, limit = nil, count = false)

      params = {
          :table_name => table_name
      }

      if expression != nil
        params[:filter_expression] = expression
      end

      if expression_params != nil

        params[:expression_attribute_names] = {}
        params[:expression_attribute_values] = {}

        expression_params.each do |key, value|
          if key[0] == '#'
            params[:expression_attribute_names][key] = value
          elsif key[0] == ':'
            params[:expression_attribute_values][key] = value
          end
        end

      end

      if limit != nil
        params[:limit] = limit
      end

      if count
        params[:select] = 'COUNT'
      else
        params[:select] = 'ALL_ATTRIBUTES'
      end

      result = dynamodb.client.scan(params)

      if count
        return result.count
      else
        output = []
        result.items.each do |item|
          output.push(item)
        end

        return output
      end

    end

    def query(partition_key_name, partition_key_value, range_key_name = nil, range_key_value = nil, expression = nil, expression_params = nil, index_name = nil, limit = nil, count = false)

      params = {
          table_name: table_name
      }

      if expression != nil
        params[:filter_expression] = expression
      end

      if index_name != nil
        params[:index_name] = index_name
      end

      if range_key_name != nil
        params[:key_condition_expression] = '#partition_key = :partition_key and #range_key = :range_key'
        params[:expression_attribute_names] = { '#partition_key' => partition_key_name, '#range_key' => range_key_name }
        params[:expression_attribute_values] = { ':partition_key' => partition_key_value, ':range_key' => range_key_value }
      else
        params[:key_condition_expression] = '#partition_key = :partition_key'
        params[:expression_attribute_names] = { '#partition_key' => partition_key_name }
        params[:expression_attribute_values] = { ':partition_key' => partition_key_value }
      end

      if expression_params != nil
        expression_params.each do |key, value|
          if key[0] == '#'
            params[:expression_attribute_names][key] = value
          elsif key[0] == ':'
            params[:expression_attribute_values][key] = value
          end
        end

      end

      if limit != nil
        params[:limit] = limit
      end

      if count
        params[:select] = 'COUNT'
      else
        params[:select] = 'ALL_ATTRIBUTES'
      end

      result = dynamodb.client.query(params)

      if count
        return result.count
      else
        output = []
        result.items.each do |item|
          output.push(item)
        end

        return output
      end

    end

    private

    def to_hashb(obj)
      hash = {}
      obj.instance_variables.each {|var| hash[var.to_s.delete("@")] = obj.instance_variable_get(var) }
      hash
    end

    STANDARD_TYPES = [String, Numeric, Fixnum, Integer, Float, Time, Date, DateTime].freeze

    def is_standard_type?(obj)
      return STANDARD_TYPES.detect { |type| obj.is_a?(type) } != nil
    end

    def to_hash(obj)
      if obj.is_a?(Hash)
        return obj
      end

      hash = {}
      obj.instance_variables.each do |var|
        value = obj.instance_variable_get(var)
        if value.is_a?(Array)
          hash[var.to_s.delete("@")] = value.collect { |i| to_hash(i) }
        elsif !is_standard_type?(value)
          hash[var.to_s.delete("@")] = to_hash(value)
        else
          hash[var.to_s.delete("@")] = value
        end
      end
      hash
    end

  end
end