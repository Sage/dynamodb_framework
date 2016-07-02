module DynamoDbFramework
  class AttributesBuilder
    attr_reader :attributes

    def initialize
      @attributes = []
    end

    def add_from_args(name, type, key = nil)
      type_symbol = :S
      if type == 'number' || type == :N || type == :number
        type_symbol = :N
      elsif type == 'binary' || type == :B || type == :binary
        type_symbol = :B
      elsif type == 'bool' || type == 'boolean' || type == :BOOL || type == :bool || type == :boolean
        type_symbol = :BOOL
      end

      if key == 'hash' || key == :hash || key == 'partition' || key == :partition
        key = :hash
      elsif key == 'range' || key == :range
        key = :range
      else
        key = nil
      end

      @attributes.push({ :name => name, :type => type_symbol, :key => key })
    end

    def add_from_hash(options)
      type_symbol = :S
      if options[:type] == 'number' || options[:type] == :N || options[:type] == :number
        type_symbol = :N
      elsif options[:type] == 'binary' || options[:type] == :B || options[:type] == :binary
        type_symbol = :B
      elsif options[:type] == 'bool' || options[:type] == 'boolean' || options[:type] == :BOOL || options[:type] == :bool || options[:type] == :boolean
        type_symbol = :BOOL
      end

      if options[:key] == 'hash' || options[:key] == :hash || options[:key] == 'partition' || options[:key] == :partition
        key = :hash
      elsif options[:key] == 'range' || options[:key] == :range
        key = :range
      else
        key = nil
      end

      @attributes.push({ :name => options[:name], :type => type_symbol, :key => key })
    end

    def add(*options)

      if options.length == 1 && options[0].is_a?(Hash)
        add_from_hash(options[0])
      elsif options.length == 3
        add_from_args(options[0], options[1], options[2])
      else
        add_from_args(options[0], options[1])
      end

    end

  end
end
