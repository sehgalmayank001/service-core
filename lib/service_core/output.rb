require "active_support/concern"
require_relative "response"

module ServiceCore
  module Output
    extend ActiveSupport::Concern

    ALLOWED_KEYS = ServiceCore::Response::ALLOWED_KEYS

    # NOTE: output holds the {ServiceCore::Response} for the service.
    # Response is Hash-compatible (responds to +[]+, +==+ with a Hash,
    # +to_s+), so existing callers keep working without changes.
    attr_reader :output
    # response is a more accurately-named accessor for the same value;
    # output is retained for backward compatibility.
    alias response output

    def initialize(_attributes = {})
      # Empty parens so that mixing Output in beside other modules that take
      # keyword arguments (e.g. ActiveModel::Model) does not forward stray
      # positional args up the chain.
      super()
      @output_dirty = false
      @status_dirty = false
      @output = ServiceCore::Response.new
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
