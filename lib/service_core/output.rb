require "active_support/concern"
require_relative "response"

module ServiceCore
  module Output
    extend ActiveSupport::Concern

    ALLOWED_KEYS = ServiceCore::Response::ALLOWED_KEYS

    # NOTE: output holds the ServiceCore::Response for the service.
    # response is the preferred name; output is retained as an alias.
    attr_reader :output
    alias response output

    def initialize(_attributes = {})
      # NOTE: super() with empty parens so positional args aren't forwarded
      # up to other modules in the ancestor chain (ActiveModel::Model et al).
      super()
      @output_dirty = false
      @status_dirty = false
      @output = ServiceCore::Response.new
    end

    private

    # NOTE: nil values are skipped; legitimate falsy values
    # (false, 0, "") are recorded faithfully.
    def set_output(key, value)
      return if key.nil? || value.nil?

      @output[key] = value
      @output_dirty = true
      @status_dirty = true if key == :status
    end

    def auto_assign_status
      if !@output_dirty
        set_output(:status, "success")
      elsif !@status_dirty
        status_value = output[:errors].blank? ? "success" : "error"
        set_output(:status, status_value)
      end
    end
  end
end
