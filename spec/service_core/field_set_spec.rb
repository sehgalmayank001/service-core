require "spec_helper"

RSpec.describe ServiceCore::FieldSet do
  let(:field_set) { described_class.new(first_name: "Ada", last_name: "Lovelace") }

  describe "#to_h" do
    it "returns the snapshot as a frozen Hash" do
      expect(field_set.to_h).to eq(first_name: "Ada", last_name: "Lovelace")
      expect(field_set.to_h).to be_frozen
    end
  end

  describe "named accessors" do
    it "exposes each symbol key as a real method" do
      expect(field_set.first_name).to eq("Ada")
      expect(field_set.last_name).to eq("Lovelace")
    end

    it "does not define accessors for non-symbol keys" do
      set = described_class.new("first_name" => "Ada")
      expect(set.respond_to?(:first_name)).to be false
      expect(set.to_h.fetch("first_name")).to eq("Ada")
    end
  end

  describe "#inspect" do
    it "includes the class name and the hash form" do
      expected = "#<ServiceCore::FieldSet #{{ first_name: "Ada", last_name: "Lovelace" }.inspect}>"
      expect(field_set.inspect).to eq(expected)
    end
  end
end
