# frozen_string_literal: true

# spec/service_core/base_spec.rb

require "spec_helper"

class TestService
  include ServiceCore::Base

  field :name, :string
  field :active, :boolean, default: true

  def perform
    @output[:message] = "Hello, #{@fields[:name]}"
  end
end

class TestService2
  include ServiceCore::Base

  field :name, :string
  field :active, :boolean, default: true
end

RSpec.describe ServiceCore::Base do
  let(:service) { TestService.new(name: "World") }

  describe "#initialize" do
    it "initializes with the given attributes" do
      expect(service.fields[:name]).to eq("World")
      expect(service.fields[:active]).to be true
    end
  end

  describe "#call" do
    it "returns a success response with the correct message" do
      response = service.call
      expect(response[:message]).to eq("Hello, World")
    end
  end

  describe "#perform" do
    it "raises an error if not implemented" do
      expect { TestService2.new.call }.to raise_error(StandardError, "perform method not implemented")
    end
  end
end
