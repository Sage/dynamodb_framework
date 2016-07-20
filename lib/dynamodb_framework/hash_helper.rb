module DynamoDbFramework
  class HashHelper
    def to_hash(obj)
      hsh = obj.is_a?(Hash) ? obj : hash_kit.to_hash(obj)
      strip_nil(hsh)
    end

    private

    def strip_nil(obj)
      remove_nil = ->(*args) do
        val = args.last
        val.delete_if(&remove_nil) if val.respond_to?(:delete_if)
        val.nil?
      end
      obj.delete_if(&remove_nil)
    end

    def hash_kit
      @hash_kit ||= HashKit::Helper.new
    end
  end
end
