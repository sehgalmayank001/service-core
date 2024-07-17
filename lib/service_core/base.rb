# frozen_string_literal: true
require "active_support/concern"
require "active_model"
require_relative "response"

module ServiceCore
  module Base
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ServiceCore::Response

           # NOTE: output attribute will hold output of the service
      attr_reader :output

      # NOTE: fields attribute will hold the fields defined and their values
      attr_reader :fields

      class << self
        # Wrapper method to define attribuutes and attr_accessor methods on object
        def fields_defined
          @fields_defined ||= {}
        end

        def field(name, *args, **opts)
          # field :active, :boolean, default: true
          # field :active, type: :boolean, default: true
          # Both explicit and implicit definitions are handled
          type = args[0] || opts[:type]
          default = args[1] || opts[:default]

          # NOTE: -
          # ActiveModel::Attributes support only basic data types
          # for ActiveRecord objects we use attr_accessor through ActiveModel::Model
          # define attr_accessor to make instance variables also available for attributes
          
          # define attribute if type is available to type cast
          if type
            attribute(name, type, default: default)
          else
            attr_accessor(name)
          end

          # save fields defind as an hash, makes it easier to check
          fields_defined[name] = default
        end

        def call(attributes = {})
          new(attributes).call
        end
      end

      def initialize(attributes = {})
        super
        @local_errors = {}
        @fields = {}
        # NOTE: this helps identify values passed from values updated
        self.class.fields_defined.each do |name, _value|
          @fields[name] = send(name)
        end

        # default value of output
        @output = { status: "initialized" }
      end

      def call
        # check if valid arguments are present?
        return error_response(message: "validation failure", errors: errors) unless valid?

        # perform the operation
        perform

        # return output
        output
      end

      protected

      # output writer is protected to be used inside class and sub-classes only
      attr_writer :output

      def perform
        raise StandardError, "perform method not implemented"
      end
    end
  end
end
