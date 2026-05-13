# frozen_string_literal: true

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

      # NOTE: fields attribute will hold the fields defined and their values
      attr_reader :fields

      class << self
        # Wrapper method to define attribuutes and attr_accessor methods on object
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
        @fields = {}
        # NOTE: this helps identify values passed from values updated
        self.class.fields_defined.each_key do |name|
          @fields[name] = send(name)
        end
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
