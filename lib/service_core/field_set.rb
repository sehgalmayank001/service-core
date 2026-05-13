module ServiceCore
  # Immutable snapshot of a service's declared fields and their values
  # at #initialize time. Each symbol key is exposed as a real method.
  # Call #to_h for full Hash semantics.
  class FieldSet
    attr_reader :to_h

    def initialize(values = {})
      @to_h = values.to_h.freeze
      @to_h.each_key do |name|
        next unless name.is_a?(Symbol)

        define_singleton_method(name) { @to_h[name] }
      end
    end

    def [](name)
      @to_h[name]
    end

    def inspect
      "#<#{self.class.name} #{@to_h.inspect}>"
    end
  end
end
