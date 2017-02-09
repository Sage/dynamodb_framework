require 'date'
require 'hash_kit'

module DynamoDbFramework
  class Repository

    attr_reader :dynamodb
    attr_accessor :table_name

    def initialize(store)
      @dynamodb = store
    end

    # Store the hash of an object to the dynamodb table
    # *Note* : [DateTime] attributes will be stored as an ISO8601 string
    #          [Time] attributes will be stored as an Epoch Int
    # The intent is that if you need to sort in dynamo by dates, then make sure you use a [Time] type. The Epoch int allows
    # you to compare properly as comparing date strings are not reliable.
    def put(item)
      hash = to_hash(item)

      clean_hash(hash)

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

    def to_hash(obj)
      hash_helper.to_hash(obj)
    end

    def hash_helper
      @hash_helper ||= HashHelper.new
    end

    # Convert empty string values to nil, as well as convert DateTime and Time to appropriate storage formats.
    def clean_hash(hash)
      hash.each do |key, value|
        if value == ''
          hash[key] = nil
        elsif value.is_a?(Array)
          value.each do |item|
            clean_hash(item) if item.is_a?(Hash)
          end
        elsif [DateTime, Time].include?(value.class)
          hash[key] = convert_date(value)
        elsif value.is_a?(Hash)
          clean_hash(value)
        end
      end
    end

    def convert_date(value)
      klass = value.class
      return value.iso8601 if klass == DateTime
      return value.to_i if klass == Time
    end
  end
end
