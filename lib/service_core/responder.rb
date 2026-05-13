require "active_support/concern"
require "active_model/errors"
require_relative "output"

module ServiceCore
  # Mixin that provides the response-building helpers used inside +perform+.
  module Responder
    extend ActiveSupport::Concern

    include ServiceCore::Output

    protected

    def success_response(message: nil, data: nil)
      formatted_response(status: "success", message: message, data: data)
    end

    def error_response(message:, errors: nil)
      formatted_response(status: "error", message: message, errors: errors)
    end

    # NOTE: nil-valued keys are skipped; legitimate falsy values
    # (false, 0, "") are recorded faithfully.
    def formatted_response(status:, message: nil, data: nil, errors: nil)
      set_output(:status, status)
      set_output(:message, message)
      set_output(:data, data)
      set_output(:errors, error_messages(errors))
      output
    end

    def error_messages(errors)
      return nil if errors.nil?

      errors.is_a?(ActiveModel::Errors) ? errors.messages : errors
    end
  end
end
