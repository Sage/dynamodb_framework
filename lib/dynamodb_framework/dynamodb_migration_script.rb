class MigrationScript
  attr_accessor :timestamp

  def apply
    raise 'Not implemented.'
  end

  def undo
    raise 'Not implemented.'
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

end