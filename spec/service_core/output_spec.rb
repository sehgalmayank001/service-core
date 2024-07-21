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

  describe '#initialize' do
    it 'initializes the output with default status' do
      expect(service.output).to eq({ status: "initialized" })
    end
  end

  describe '#set_output' do
    context 'when key is valid' do
      it 'sets the output value' do
        service.set_test_output(:data, "payload")
        expect(service.output[:data]).to eq("payload")
        expect(service.output[:status]).to eq("initialized")
      end

      it 'sets the status_dirty to true if key is :status' do
        service.set_test_output(:status, "error")
        expect(service.output[:status]).to eq("error")
      end
    end

    context 'when key is invalid' do
      it 'raises an ArgumentError' do
        expect { service.set_test_output(:invalid_key, "value") }.to raise_error(ArgumentError, "Invalid key. Allowed keys are: status, data, message, errors")
      end
    end
  end

  describe '#auto_assign_status' do
    context 'when output is not dirty' do
      it 'sets status to success' do
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("success")
      end
    end

    context 'when output is dirty and errors are blank' do
      it 'sets status to success' do
        service.set_test_output(:data, "payload")
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("success")
      end
    end

    context 'when output is dirty and errors are present' do
      it 'sets status to error' do
        service.set_test_output(:errors, "something went wrong")
        service.test_auto_assign_status
        expect(service.output[:status]).to eq("error")
      end
    end
  end
end
