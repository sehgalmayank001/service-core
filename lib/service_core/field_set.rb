require "active_support/json"

module ServiceCore
  # Immutable, Hash-compatible snapshot of a service's declared fields and
  # their values at +#initialize+ time.
  class FieldSet
    attr_reader :to_h
    alias to_hash to_h

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

    def fetch(name, *default, &)
      @to_h.fetch(name, *default, &)
    end

    def key?(name)
      @to_h.key?(name)
    end
    alias has_key? key?
    alias include? key?
    alias member? key?

    def keys
      @to_h.keys
    end

    def values
      @to_h.values
    end

    def each_pair(&)
      return to_enum(:each_pair) unless block_given?

      @to_h.each_pair(&)
    end
    alias each each_pair

    def dig(name, *rest)
      @to_h.dig(name, *rest)
    end

    def to_s
      @to_h.to_s
    end

    def inspect
      "#<#{self.class.name} #{@to_h.inspect}>"
    end

    def ==(other)
      case other
      when FieldSet then @to_h == other.to_h
      when Hash then @to_h == other
      else super
      end
    end
    alias eql? ==

    def hash
      @to_h.hash
    end

    # NOTE: enables pattern matching, e.g. `case fields in { first_name: }`
    def deconstruct_keys(keys)
      keys ? @to_h.slice(*keys) : @to_h
    end

    def as_json(options = nil)
      @to_h.as_json(options)
    end

    def to_json(*args)
      @to_h.to_json(*args)
    end
  end
end
