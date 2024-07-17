# spec/service_core_spec.rb

require "spec_helper"

RSpec.describe ServiceCore do
  it "has a version number" do
    expect(ServiceCore::VERSION).not_to be nil
  end

  describe ".logger" do
    before do
      # Reset the logger before each example
      ServiceCore.instance_variable_set(:@logger, nil)
    end

    context "when Rails is defined" do
      before do
        stub_const("Rails", double(logger: Logger.new(nil)))
      end

      it "uses the Rails logger" do
        expect(ServiceCore.logger).to eq(Rails.logger)
      end
    end

    context "when Rails is not defined" do
      it "uses the default logger" do
        expect(ServiceCore.logger).to be_a(ActiveSupport::Logger)
      end
    end
  end

  describe ".configure" do
    it "allows the logger to be configured" do
      custom_logger = Logger.new(nil)
      ServiceCore.configure do |config|
        config.logger = custom_logger
      end
      expect(ServiceCore.logger).to eq(custom_logger)
    end
  end
end
