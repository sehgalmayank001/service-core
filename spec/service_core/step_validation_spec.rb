# spec/service_core/step_validations_spec.rb

require "spec_helper"

class ValidationService
  include ServiceCore::Base
  include ServiceCore::StepValidation

  field :name, :string

  validates :name, presence: true

  def perform
    @output[:message] = "Validated, #{@fields[:name]}"
  end
end

RSpec.describe ServiceCore::StepValidation do
  let(:service) { ValidationService.new(name: name) }
  let(:name) { "John Doe" }

  describe "#call" do
    context "when valid" do
      it "returns a success response" do
        response = service.call
        expect(response[:message]).to eq("Validated, John Doe")
      end
    end

    context "when invalid" do
      let(:name) { nil }

      it "returns an error response" do
        response = service.call
        expect(response[:status]).to eq("error")
        expect(response[:errors]).to have_key(:name)
      end
    end
  end

  describe "#add_error_and_validate" do
    it "adds a custom error and returns false" do
      service.add_error_and_validate(:name, "Custom error")
      expect(service.errors[:name]).to include("Custom error")
      expect(service.valid?).to be false
    end
  end
end
