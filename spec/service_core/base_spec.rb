# spec/service_core/base_spec.rb

require "spec_helper"

class TestService
  include ServiceCore::Base

  field :name, :string
  field :active, :boolean, default: true

  def perform
    @output[:message] = "Hello, #{name}"
  end
end

class TestService2
  include ServiceCore::Base

  field :name, :string
  field :active, :boolean, default: true
end

class DefaultsService
  include ServiceCore::Base

  field :enabled_positional, :boolean, false
  field :enabled_keyword, :boolean, default: false
  field :counter, :integer, 0
  field :title, :string, ""
  field :payload

  def perform
    success_response(data: fields)
  end
end

RSpec.describe ServiceCore::Base do
  let(:service) { TestService.new(name: "World") }

  describe "#initialize" do
    it "exposes fields as a FieldSet value object" do
      expect(service.fields).to be_a(ServiceCore::FieldSet)
    end

    it "snapshots declared fields via named accessors" do
      expect(service.fields.name).to eq("World")
      expect(service.fields.active).to be true
    end

    it "exposes the snapshot via to_h" do
      expect(service.fields.to_h).to eq(name: "World", active: true)
    end

    it "freezes the underlying snapshot" do
      expect { service.fields.to_h[:name] = "Other" }.to raise_error(FrozenError)
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

  describe ".call" do
    it "returns the service class object" do
      response = TestService.call(name: "World")
      expect(response).to be_an_instance_of(TestService)
      expect(response.output[:message]).to eq("Hello, World")
    end
  end

  describe "reserved field names" do
    it "raises when a field name would shadow a gem method" do
      ServiceCore::Base::RESERVED_FIELD_NAMES.each do |reserved|
        expect do
          Class.new { include ServiceCore::Base }.field(reserved, :string)
        end.to raise_error(ArgumentError, /reserved by ServiceCore/)
      end
    end
  end

  describe "field defaults" do
    let(:service) { DefaultsService.new }

    it "honours a positional false default" do
      expect(service.enabled_positional).to be false
      expect(service.fields.enabled_positional).to be false
    end

    it "honours a keyword false default" do
      expect(service.enabled_keyword).to be false
    end

    it "honours a positional zero default" do
      expect(service.counter).to eq(0)
    end

    it "honours a positional empty-string default" do
      expect(service.title).to eq("")
    end

    it "leaves untyped fields as nil" do
      expect(service.payload).to be_nil
    end
  end
end
