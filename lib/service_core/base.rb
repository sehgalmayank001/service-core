require "active_support/concern"
require "active_model"
require_relative "responder"

module ServiceCore
  module Base
    extend ActiveSupport::Concern

    included do
      # NOTE: Responder is included first so its initialize (inherited
      # from Output) runs at the bottom of the super chain.
      include ServiceCore::Responder
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      # NOTE: fields holds a ServiceCore::FieldSet snapshot of declared
      # fields and their values at initialize time.
      attr_reader :fields

      class << self
        def fields_defined
          @fields_defined ||= {}
        end

        def field(name, *args, **opts)
          # field :active, :boolean, default: true
          # field :active, type: :boolean, default: true
          # field :active, :boolean, false   # positional default
          # field :payload                   # untyped (hash/array/object)
          type = args.first || opts[:type]
          # NOTE: arity check, not `||`, so a positional default of
          # `false` or `nil` is not silently swallowed by opts[:default].
          default = args.length >= 2 ? args[1] : opts[:default]

          if type
            attribute(name, type, default: default)
          else
            attr_accessor(name)
          end

          fields_defined[name] = default
        end

        def call(attributes = {})
          obj = new(attributes)
          obj.call
          obj
        end
      end

      def initialize(attributes = {})
        super
        @local_errors = {}
        snapshot = self.class.fields_defined.keys.to_h { |name| [name, send(name)] }
        @fields = ServiceCore::FieldSet.new(snapshot)
      end

      def call
        # check if valid arguments are present?
        return error_response(message: "validation failure", errors: errors) unless valid?

        # perform the operation
        perform

        # auto assign status if output is dirty
        auto_assign_status

        # return output
        output
      end

      private

      def perform
        raise StandardError, "perform method not implemented"
      end
    end
  end
end
