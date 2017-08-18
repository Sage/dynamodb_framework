module DynamoDbFramework
  class Query

    class InvalidQueryError < StandardError
      def initialize(message)
        super(message)
      end
    end

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

    def eq(value)
      condition(expression: '=', value: value)
      self
    end

    def not_eq(value)
      condition(expression: '<>', value: value)
      self
    end

    def gt(value)
      condition(expression: '>', value: value)
      self
    end

    def gt_eq(value)
      condition(expression: '>=', value: value)
      self
    end

    def lt(value)
      condition(expression: '<', value: value)
      self
    end

    def lt_eq(value)
      condition(expression: '<=', value: value)
      self
    end

    def contains(value)
      field = @parts.last
      unless field[:type] == :field
        raise ::InvalidQueryError.new('The contains query part can only be chained to a field.')
      end
      @parts.pop
      @parts << { type: :contains, field: field[:value], value: value }
      self
    end

    def exists?
      field = @parts.last
      unless field[:type] == :field
        raise ::InvalidQueryError.new('The exists? query part can only be chained to a field.')
      end
      @parts.pop
      @parts << { type: :exists, field: field[:value] }
      self
    end

    def and
      @parts << { type: :and }
      self
    end

    def or
      @parts << { type: :or }
      self
    end

    def execute(store: DynamoDbFramework.default_store, limit: nil, count: false)
      build
      repository = DynamoDbFramework::Repository.new(store)
      repository.table_name = @table_name
      repository.query(@partition_key, @partition_value, nil, nil, @expression_string, @expression_params, @index_name, limit, count)
    end

    def build
      @expression_string = ''
      @expression_params = {}

      counter = 0
      @parts.each do |p|
        case p[:type]
          when :field
            field_param = '#' + p[:value].to_s
            @expression_string += ' ' + field_param
            @expression_params[field_param] = p[:value].to_s
          when :condition
            param_name = ':p' + counter.to_s
            counter = counter + 1
            @expression_string += ' ' + p[:expression].to_s + ' ' + param_name
            @expression_params[param_name] = clean_value(p[:value])
          when :contains
            param_name = ':p' + counter.to_s
            counter = counter + 1
            field_param = '#' + p[:field].to_s
            @expression_string += ' contains(' + field_param + ', ' + param_name + ')'
            @expression_params[field_param] = p[:field].to_s
            @expression_params[param_name] = clean_value(p[:value])
          when :exists
            field_param = '#' + p[:field].to_s
            @expression_string += ' attribute_exists(' + field_param + ')'
            @expression_params[field_param] = p[:field].to_s
          when :and
            @expression_string += ' and'
          when :or
            @expression_string += ' or'
          else
            raise 'Invalid query part'
        end
      end

      return @expression_string.strip, @expression_params
    end

    def condition(expression:, value:)
      @parts << { type: :condition, expression: expression, value: value }
    end

    def convert_date(value)
      klass = value.class
      return value.iso8601 if klass == DateTime
      return value.to_i if klass == Time
    end

    def clean_value(value)
      if value.is_a?(Time) || value.is_a?(DateTime)
        convert_date(value)
      else
        value
      end
    end

  end
end
