class DynamoDbAttributesBuilder
  attr_reader :attributes

  def initialize
    @attributes = []
  end

  def add(name, type)
    type_symbol = :S
    if type == 'number' || type == :N
      type_symbol = :N
    elsif type == 'binary' || type == :B
      type_symbol = :B
    elsif type == 'bool' || type == 'boolean' || type == :BOOL
      type_symbol = :BOOL
    end
    @attributes.push({ :name => name, :type => type_symbol })
  end

end