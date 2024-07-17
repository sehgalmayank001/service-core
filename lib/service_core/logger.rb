# frozen_string_literal: true

require "active_support/concern"

module ServiceCore
  module Logger
    extend ActiveSupport::Concern

    protected

    def log_error(exception)
      ServiceCore.logger.error("#{self.class.name}: #{exception.message}")
    end
  end
end
