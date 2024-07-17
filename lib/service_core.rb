# frozen_string_literal: true

require_relative "service_core/version"
require_relative "service_core/base"
require_relative "service_core/step_validation"
require_relative "service_core/logger"
require "active_model"
require "active_support/concern"
require "active_support/logger"

module ServiceCore
  extend ActiveSupport::Concern

  included do
    include ServiceCore::Base
    include ServiceCore::StepValidation
    include ServiceCore::Logger
  end

  class Error < StandardError; end

  class << self
    attr_writer :logger

    def logger
      @logger ||= defined?(Rails) && Rails.logger ? Rails.logger : ActiveSupport::Logger.new($stdout)
    end

    def configure
      yield self
    end
  end
end
