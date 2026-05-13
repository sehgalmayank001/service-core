require "active_support/json"

module ServiceCore
  # Value object carrying the four-key service response.
  class Response
    ALLOWED_KEYS = %i[status data message errors].freeze

    attr_accessor(*ALLOWED_KEYS)

    def initialize(status: "initialized", data: nil, message: nil, errors: nil)
      @status = status
      @data = data
      @message = message
      @errors = errors
    end

    def [](key)
      ensure_allowed_key!(key)
      public_send(key)
    end

    def []=(key, value)
      ensure_allowed_key!(key)
      public_send(:"#{key}=", value)
    end

    def fetch(key, *default)
      ensure_allowed_key!(key)
      value = public_send(key)
      return value unless value.nil?
      return yield(key) if block_given?
      return default.first if default.any?

      raise(KeyError, "key not found: #{key.inspect}")
    end

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
      when Response then to_h == other.to_h
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

    # NOTE: enables pattern matching, e.g. `case response in { status:, data: }`
    def deconstruct_keys(keys)
      hash = to_h
      keys ? hash.slice(*keys) : hash
    end

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
