require "spec_helper"

class OutputTestService
  include ServiceCore::Output

  def set_test_output(key, value)
    set_output(key, value)
  end

  def test_auto_assign_status
    auto_assign_status
  end
end

RSpec.describe ServiceCore::Output do
  let(:service) { OutputTestService.new }

  describe "#initialize" do
    it "initializes the output with default status" do
      expect(service.output).to eq({ status: "initialized" })
    end
  end

  describe "#set_output" do
    context "when key is valid" do
      it "sets the output value" do
        service.set_test_output(:data, "payload")
        expect(service.output[:data]).to eq("payload")
        expect(service.output[:status]).to eq("initialized")
      end

      it "sets the status_dirty to true if key is :status" do
        service.set_test_output(:status, "error")
        expect(service.output[:status]).to eq("error")
      end
    end

    context "when key is invalid" do
      it "raises an ArgumentError" do
        expect do
          service.set_test_output(:invalid_key, "value")
        end.to raise_error(ArgumentError, "Invalid key. Allowed keys are: status, data, message, errors")
      end
    end

    context "with legitimate falsy values" do
      it "records false" do
        service.set_test_output(:data, false)
        expect(service.output[:data]).to be false
      end

      it "records 0" do
        service.set_test_output(:data, 0)
        expect(service.output[:data]).to eq(0)
      end

      it "records an empty string" do
        service.set_test_output(:message, "")
        expect(service.output[:message]).to eq("")
      end

      it "records an empty hash" do
        service.set_test_output(:errors, {})
        expect(service.output[:errors]).to eq({})
      end
    end

    context "when value is nil" do
      it "silently skips the write" do
        service.set_test_output(:data, nil)
        expect(service.output.key?(:data)).to be false
      end
    end

    context "when key is nil" do
      it "silently skips the write" do
        expect { service.set_test_output(nil, "value") }.not_to raise_error
      end
    end
  end

  describe "#output" do
    it "returns a ServiceCore::Response instance" do
      expect(service.output).to be_a(ServiceCore::Response)
    end

    it "is also reachable via #response" do
      expect(service.response).to equal(service.output)
    end
  end

  describe "#auto_assign_status" do
    context "when output is not dirty" do
      it "sets status to success" do
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("success")
      end
    end

    context "when output is dirty and errors are blank" do
      it "sets status to success" do
        service.set_test_output(:data, "payload")
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("success")
      end
    end

    context "when output is dirty and errors are present" do
      it "sets status to error" do
        service.set_test_output(:errors, "something went wrong")
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("error")
      end
    end
  end
end
