# spec/service_core/responses_spec.rb

require "spec_helper"

class ResponseService
  include ServiceCore::Base
  include ServiceCore::Response

  def perform
    success_response(message: "It worked!", data: { key: "value" })
  end
end

RSpec.describe ServiceCore::Response do
  let(:service) { ResponseService.new }

  describe "#success_response" do
    it "returns a success response with a message and data" do
      response = service.call
      expect(response[:status]).to eq("success")
      expect(response[:message]).to eq("It worked!")
      expect(response[:data]).to eq(key: "value")
    end
  end

  describe "#error_response" do
    it "returns an error response with a message and errors" do
      response = service.send(:error_response, message: "Something went wrong", errors: { name: ["can't be blank"] })
      expect(response[:status]).to eq("error")
      expect(response[:message]).to eq("Something went wrong")
      expect(response[:errors]).to eq(name: ["can't be blank"])
    end
  end

  describe "#pending_response" do
    it "returns a pending response with a message and data" do
      response = service.send(:pending_response, message: "Pending", data: { key: "value" })
      expect(response[:status]).to eq("pending")
      expect(response[:message]).to eq("Pending")
      expect(response[:data]).to eq(key: "value")
    end
  end
end
