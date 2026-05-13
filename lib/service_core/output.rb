# frozen_string_literal: true

require "active_support/concern"
require_relative "result"

module ServiceCore
  module Output
    extend ActiveSupport::Concern

    ALLOWED_KEYS = ServiceCore::Result::ALLOWED_KEYS

    # NOTE: output attribute holds the {ServiceCore::Result} for the service.
    # Result is Hash-compatible (responds to +[]+, +==+ with a Hash, +to_s+),
    # so existing callers keep working without changes.
    attr_reader :output

    def initialize(_attributes = {})
      # Empty parens so that mixing Output in beside other modules that take
      # keyword arguments (e.g. ActiveModel::Model) does not forward stray
      # positional args up the chain.
      super()
      @output_dirty = false
      @status_dirty = false
      @output = ServiceCore::Result.new
    end

    private

    # Records a key on the response.
    #
    # Only +nil+ values are short-circuited; legitimate falsy values such
    # as +false+, +0+ and +""+ are recorded faithfully.
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
