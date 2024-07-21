# frozen_string_literal: true

require "active_support/concern"
require_relative "output"
# require "active_model/errors"

module ServiceCore
  module Response
    extend ActiveSupport::Concern

    include ServiceCore::Output

    protected

    def success_response(message: nil, data: nil)
      formatted_response(status: "success", message: message, data: data)
    end

    def error_response(message:, errors: nil)
      formatted_response(status: "error", message: message, errors: errors)
    end

    # set output response
    def formatted_response(status:, message: nil, data: nil, errors: nil)
      set_output(:status, status)
      set_output(:message, message) if message.present?
      set_output(:data, data) if data.present?
      set_output(:errors, error_messages(errors)) if errors.present?
      output
    end

    def error_messages(errors)
      errors.is_a?(ActiveModel::Errors) ? errors.messages : errors
    end
  end
end
