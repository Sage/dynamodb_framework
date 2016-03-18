class DynamoDbRepository

  attr_reader :dynamodb
  attr_accessor :table_name

  def initialize
    @dynamodb = DynamoDbStore.new
  end

  def put(item)

    json_string = item.to_json
    json_obj = JSON.load(json_string)

    params =
        {
            table_name: @table_name,
            item: json_obj
        }

    dynamodb.client.put_item(params)

  end

  def delete(key)

    params =
        {
            table_name: @table_name,
            key: key
        }

    dynamodb.client.delete_item(params)

  end

  def get_by_key(hash_key, hash_value, range_key = nil, range_value = nil)

    key = {}
    key[hash_key] = hash_value
    if(range_key != nil)
      key[range_key] = range_value
    end

    params = {
        table_name: table_name,
        key: key
    }

    result = dynamodb.client.get_item(params)
    return map(result.item)

  end

  def all

    result = dynamodb.client.scan({
                                      :table_name => table_name
                                  })

    output = []
    result.items.each do |item|
      output.push(map(item))
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
        if key.starts_with?('#')
          params[:expression_attribute_names][key] = value
        elsif key.starts_with?(':')
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
        output.push(map(item))
      end

      return output
    end

  end

  def query(hash_key_name, hash_key_value, range_key_name = nil, range_key_value = nil, expression = nil, expression_params = nil, index_name = nil, limit = nil, count = false)

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
      params[:key_condition_expression] = '#hash_key = :hash_key and #range_key = :range_key'
      params[:expression_attribute_names] = { '#hash_key' => hash_key_name, '#range_key' => range_key_name }
      params[:expression_attribute_values] = { ':hash_key' => hash_key_value, ':range_key' => range_key_value }
    else
      params[:key_condition_expression] = '#hash_key = :hash_key'
      params[:expression_attribute_names] = { '#hash_key' => hash_key_name }
      params[:expression_attribute_values] = { ':hash_key' => hash_key_value }
    end

    if expression_params != nil

      expression_params.each do |key, value|
        if key.starts_with?('#')
          params[:expression_attribute_names][key] = value
        elsif key.starts_with?(':')
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
        output.push(map(item))
      end

      return output
    end

  end

  def map(item)
    return item
  end

end