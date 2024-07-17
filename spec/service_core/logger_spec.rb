# frozen_string_literal: true

# spec/service_core/errors_spec.rb

require "spec_helper"

class ErrorService
  include ServiceCore::Base
  include ServiceCore::Logger

  def perform
    raise StandardError, "Something went wrong"
  rescue StandardError => e
    log_error(e)
    error_response(message: "Failed", errors: { base: [e.message] })
  end
end

RSpec.describe ServiceCore::Logger do
  let(:service) { ErrorService.new }

  describe "#log_error" do
    it "logs an error message" do
      expect(ServiceCore.logger).to receive(:error).with("ErrorService: Something went wrong")
      service.call
    end
  end

  describe "#perform" do
    it "returns an error response with the error message" do
      response = service.call
      expect(response[:status]).to eq("error")
      expect(response[:message]).to eq("Failed")
      expect(response[:errors]).to eq(base: ["Something went wrong"])
    end
  end
end
