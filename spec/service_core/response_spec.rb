# frozen_string_literal: true

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

  describe "#formatted_response" do
    before do
      service.instance_variable_set(:@output, {})
    end

    context "when all arguments are provided" do
      it "sets the output with all provided values" do
        status = "success"
        message = "Operation successful"
        data = { key: "value" }
        errors = { field: ["error message"] }

        result = service.send(:formatted_response, status: status, message: message, data: data, errors: errors)

        expect(result[:status]).to eq(status)
        expect(result[:message]).to eq(message)
        expect(result[:data]).to eq(data)
        expect(result[:errors]).to eq(errors)
      end
    end

    context "when optional arguments are not provided" do
      it "sets the output with only the status" do
        status = "success"

        result = service.send(:formatted_response, status: status)

        expect(result[:status]).to eq(status)
        expect(result[:message]).to be_nil
        expect(result[:data]).to be_nil
        expect(result[:errors]).to be_nil
      end

      it "sets the output with status and message" do
        status = "error"
        message = "Something went wrong"

        result = service.send(:formatted_response, status: status, message: message)

        expect(result[:status]).to eq(status)
        expect(result[:message]).to eq(message)
        expect(result[:data]).to be_nil
        expect(result[:errors]).to be_nil
      end
    end

    context "when errors are provided" do
      it "formats errors correctly" do
        status = "error"
        errors = { field: ["error message"] }

        allow(service).to receive(:error_messages).with(errors).and_return(errors)

        result = service.send(:formatted_response, status: status, errors: errors)

        expect(result[:status]).to eq(status)
        expect(result[:errors]).to eq(errors)
      end
    end
  end
end
