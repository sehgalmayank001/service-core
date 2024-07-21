# frozen_string_literal: true

require "active_support/concern"
# require "active_model/errors"

module ServiceCore
  module Output
    extend ActiveSupport::Concern

    ALLOWED_KEYS = %i[status data message errors].freeze

    # NOTE: output attribute will hold output of the service
    attr_reader :output

    def initialize(_attributes = {})
      @output_dirty = false
      @status_dirty = false
      @output = { status: "initialized" }
    end

    private

    def set_output(key, value)
      return unless key && value
      raise ArgumentError, "Invalid key. Allowed keys are: #{ALLOWED_KEYS.join(", ")}" unless ALLOWED_KEYS.include?(key)

      @output_dirty ||= true
      @status_dirty = true if key == :status && !@status_dirty
      @output[key] = value
    end

    def auto_assign_status
      if !@output_dirty
        set_output(:status, "success")
      elsif @output_dirty && !@status_dirty
        status_value = output[:errors].blank? ? "success" : "error"
        set_output(:status, status_value)
      elsif @output_dirty && @status_dirty
        # ignore
      end
    end
  end
end
