require "active_support/concern"

module ServiceCore
  module StepValidation
    extend ActiveSupport::Concern

    included do
      # NOTE: ActiveModel::Validations resets `errors` on every `valid?`,
      # so we re-apply any errors recorded via #add_error through a
      # registered validator. This lets a service accumulate errors
      # mid-perform without them being wiped.
      validate :local_errors_validation
    end

    def add_error(attribute, message, options = {})
      value = options.empty? ? message : [message, options]
      @local_errors[attribute] ||= []
      @local_errors[attribute] << value
    end

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
