module DynamoDbFramework
  class Query

    def initialize(table_name:, partition_key:, partition_value:, index_name: nil)
      @table_name = table_name
      @partition_key = partition_key
      @partition_value = partition_value
      @index_name = index_name
      @parts = []
    end

    def method_missing(name)
      @parts << { type: :field, value: name }
      self
    end

    def ==(value)
      condition(expression: '==', value: value)
      self
    end

    def !=(value)
      condition(expression: '!=', value: value)
      self
    end

    def >(value)
      condition(expression: '>', value: value)
      self
    end

    def >=(value)
      condition(expression: '>=', value: value)
      self
    end

    def <(value)
      condition(expression: '<', value: value)
      self
    end

    def <=(value)
      condition(expression: '<=', value: value)
      self
    end

    def and()
      @parts << { type: :and }
      self
    end

    def or()
      @parts << { type: :or }
      self
    end

    def execute(store:, limit: nil, count: false)
      expression_string, expression_params = generate_expression
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = @table_name
      repository.query(@partition_key, @partition_value, nil, nil, expression_string, expression_params, @index_name, limit, count)
    end

    def generate_expression
      expression_string = ''
      expression_params = {}

      counter = 0
      @parts.each do |p|
        case p[:type]
          when :field
            field_param = '#' + p[:value].to_s
            expression_string += ' ' + field_param
            expression_params[field_param] = p[:value].to_s
          when :condition
            param_name = ':p' + counter.to_s
            counter = counter + 1
            expression_string += ' ' + p[:expression].to_s + ' ' + param_name
            expression_params[param_name] = p[:value]
          when :and
            expression_string += ' and'
          when :or
            expression_string += ' or'
          else
            raise 'Invalid query part'
        end
      end

      return expression_string.strip, expression_params
    end

    def condition(expression:, value:)
      @parts << { type: :condition, expression: expression, value: value }
    end

  end
end
