module ServiceCore
  # Value object representing a service response.
  #
  # ServiceCore enforces a four-key response contract: +status+, +data+,
  # +message+ and +errors+. {Result} carries that contract as a named object
  # with first-class accessors, while remaining drop-in compatible with the
  # previous +Hash+-based +#output+ so existing callers keep working.
  #
  # @example Named access
  #   result = ServiceCore::Result.new(status: "success", data: { id: 1 })
  #   result.status # => "success"
  #   result.data   # => { id: 1 }
  #
  # @example Hash-style access (backward compatible)
  #   result[:status]               # => "success"
  #   result[:message] = "ok"
  #   result == { status: "success", data: { id: 1 }, message: "ok" } # => true
  #
  # @example Pattern matching
  #   case result
  #   in { status: "success", data: }
  #     puts data
  #   end
  class Result
    ALLOWED_KEYS = %i[status data message errors].freeze

    attr_accessor(*ALLOWED_KEYS)

    # Coerce a Hash or another Result into a Result.
    #
    # @param source [Result, Hash]
    # @return [Result]
    # @raise [ArgumentError] if +source+ is not a Hash or Result
    def self.from(source)
      return source.dup if source.is_a?(Result)
      raise(ArgumentError, "Cannot coerce #{source.class} to ServiceCore::Result") unless source.is_a?(Hash)

      new(**allowed_attributes(source))
    end

    # @api private
    def self.allowed_attributes(hash)
      hash.each_with_object({}) do |(key, value), memo|
        memo[key.to_sym] = value if ALLOWED_KEYS.include?(key.to_sym)
      end
    end
    private_class_method(:allowed_attributes)

    def initialize(status: "initialized", data: nil, message: nil, errors: nil)
      @status = status
      @data = data
      @message = message
      @errors = errors
    end

    # @param key [Symbol]
    # @return [Object, nil]
    def [](key)
      ensure_allowed_key!(key)
      public_send(key)
    end

    # @param key [Symbol]
    # @param value [Object]
    def []=(key, value)
      ensure_allowed_key!(key)
      public_send(:"#{key}=", value)
    end

    # Mirror +Hash#fetch+.
    def fetch(key, *default)
      ensure_allowed_key!(key)
      value = public_send(key)
      return value unless value.nil?
      return yield(key) if block_given?
      return default.first if default.any?

      raise(KeyError, "key not found: #{key.inspect}")
    end

    # @param key [Symbol]
    # @return [Boolean] true when +key+ is one of {ALLOWED_KEYS} and currently set
    def key?(key)
      ALLOWED_KEYS.include?(key) && !public_send(key).nil?
    end
    alias has_key? key?
    alias include? key?
    alias member? key?

    def keys
      ALLOWED_KEYS.select { |key| key?(key) }
    end

    def values
      keys.map { |key| public_send(key) }
    end

    def each_pair
      return to_enum(:each_pair) unless block_given?

      keys.each { |key| yield(key, public_send(key)) }
    end
    alias each each_pair

    # @return [Hash{Symbol => Object}] only includes keys that have been set
    def to_h
      ALLOWED_KEYS.each_with_object({}) do |key, hash|
        value = public_send(key)
        hash[key] = value unless value.nil?
      end
    end
    alias to_hash to_h

    def to_s
      to_h.to_s
    end

    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end

    def ==(other)
      case other
      when Result then to_h == other.to_h
      when Hash then to_h == other
      else super
      end
    end
    alias eql? ==

    def hash
      to_h.hash
    end

    def dig(key, *rest)
      ensure_allowed_key!(key)
      value = public_send(key)
      return value if rest.empty? || value.nil?

      value.respond_to?(:dig) ? value.dig(*rest) : nil
    end

    # Enables pattern matching: +case result in { status:, data: } ...+
    def deconstruct_keys(keys)
      hash = to_h
      keys ? hash.slice(*keys) : hash
    end

    # ActiveSupport hook so the result serialises like its hash form.
    def as_json(options = nil)
      to_h.as_json(options)
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def ensure_allowed_key!(key)
      return if ALLOWED_KEYS.include?(key)

      raise(ArgumentError, "Invalid key. Allowed keys are: #{ALLOWED_KEYS.join(", ")}")
    end
  end
end
