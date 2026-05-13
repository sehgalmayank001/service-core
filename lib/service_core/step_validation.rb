# frozen_string_literal: true

require "active_support/concern"

module ServiceCore
  # Allows a service to accumulate validation errors mid-+perform+ without
  # being wiped by subsequent +valid?+ calls. ActiveModel::Validations
  # resets +errors+ on every +valid?+, which is hostile to multi-step
  # services; this module re-applies any errors recorded via {#add_error}
  # through a registered validator.
  module StepValidation
    extend ActiveSupport::Concern

    included do
      validate :local_errors_validation
    end

    # Records an error to be re-applied to +errors+ on the next +valid?+
    # call. Multiple errors per attribute are supported.
    #
    # @param attribute [Symbol]
    # @param message [String, Symbol]
    # @param options [Hash] forwarded to +ActiveModel::Errors#add+
    def add_error(attribute, message, options = {})
      value = options.empty? ? message : [message, options]
      @local_errors[attribute] ||= []
      @local_errors[attribute] << value
    end

    # Adds an error and immediately validates, mirroring the common
    # +invalid? unless ...+ idiom.
    #
    # @return [Boolean] result of +valid?+
    def add_error_and_validate(attribute, message, options = {})
      add_error(attribute, message, options)
      valid?
    end

    private

    def local_errors_validation
      @local_errors.each do |attribute, messages|
        Array(messages).each { |message| apply_local_error(attribute, message) }
      end
    end

    def apply_local_error(attribute, message)
      if message.is_a?(Array)
        errors.add(attribute, *message)
      else
        errors.add(attribute, message)
      end
    end
  end
end
