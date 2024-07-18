# frozen_string_literal: true

# spec/service_core_spec.rb

require "spec_helper"

RSpec.describe ServiceCore do
  it "has a version number" do
    expect(ServiceCore::VERSION).not_to be_nil
  end

  describe ".logger" do
    before do
      # Reset the logger before each example
      described_class.instance_variable_set(:@logger, nil)
    end

    context "when Rails is defined" do
      before do
        logger_double = instance_double(Logger)
        allow(logger_double).to receive(:info)
        rails_double = instance_double("Rails", logger: logger_double)
        stub_const("Rails", rails_double)
      end

      it "uses the Rails logger" do
        expect(described_class.logger).to eq(Rails.logger)
      end
    end

    context "when Rails is not defined" do
      it "uses the default logger" do
        expect(described_class.logger).to be_a(ActiveSupport::Logger)
      end
    end
  end

  describe ".configure" do
    it "allows the logger to be configured" do
      custom_logger = Logger.new(nil)
      described_class.configure do |config|
        config.logger = custom_logger
      end
      expect(described_class.logger).to eq(custom_logger)
    end
  end
end
