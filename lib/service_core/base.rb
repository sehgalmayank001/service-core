require "active_support/concern"
require "active_model"
require_relative "response"

module ServiceCore
  module Base
    extend ActiveSupport::Concern

    included do
      # ServiceCore::Response is included first as it inherited output,
      # which too has initialize method.
      include ServiceCore::Response
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      # NOTE: fields holds a {ServiceCore::FieldSet} snapshot of declared
      # fields and their values at +#initialize+ time. The FieldSet is
      # Hash-compatible (responds to +[]+, +==+ with a Hash, +to_h+) so
      # existing +service.fields[:name]+ callers keep working unchanged,
      # while gaining named accessors and immutability.
      attr_reader :fields

      class << self
        # Registry of declared fields, keyed by name. Values are the
        # declared default for each field (nil when no default was given).
        # Kept as a Hash for backward-compatible introspection.
        def fields_defined
          @fields_defined ||= {}
        end

        # Declares a field on the service.
        #
        # Supports both keyword and positional forms:
        #
        #   field :active, :boolean, default: true
        #   field :active, type: :boolean, default: true
        #   field :active, :boolean, false        # positional default
        #   field :payload                         # untyped (hash/array/object)
        #
        # Typed fields are backed by ActiveModel::Attributes and inherit its
        # casting and default support. Untyped fields fall back to a plain
        # attr_accessor and cannot carry defaults.
        def field(name, *args, **opts)
          type = args.first || opts[:type]
          # NOTE: arity check is required so that positional defaults of
          # false or nil are honoured; `args[1] || opts[:default]` would
          # silently swallow `false`.
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
        # Capture an immutable snapshot of every declared field's value at
        # initialisation time. Stored as a {ServiceCore::FieldSet} so the
        # snapshot has a name, is read-only, and exposes both Hash-style
        # and named access.
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
