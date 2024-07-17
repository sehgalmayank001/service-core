# frozen_string_literal: true

require "active_support/concern"

module ServiceCore
  module StepValidation
    extend ActiveSupport::Concern

    included do
      # NOTE: #
      # added this to support partial validation
      # valid? method empties all errors, so needed a way to hold errors from within method invocation
      validate :local_errors_validation

      def local_errors_validation
        _local_errors_validation(@local_errors)
      end

      def _local_errors_validation(errors_hsh)
        errors_hsh.each do |attribute, messages|
          next unless messages

          messages.each do |message|
            errors.add(attribute, *message.is_a?(Array) ? message : [message])
          end
        end
        {}
      end

      def add_error(attribute, message, options = {})
        value = options.present? ? [message, options] : message
        @local_errors[attribute] = if @local_errors[attribute].present?
                                     Array(@local_errors[attribute]) << value
                                   else
                                     [value]
                                   end
      end

      # method to add partial errors and validate
      def add_error_and_validate(attribute, message, _options = {})
        add_error(attribute, message, {})
        valid?
      end
    end
  end
end
