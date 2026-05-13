require "spec_helper"

RSpec.describe ServiceCore::FieldSet do
  let(:field_set) { described_class.new(first_name: "Ada", last_name: "Lovelace") }

  describe "#to_h" do
    it "returns the snapshot as a frozen Hash" do
      expect(field_set.to_h).to eq(first_name: "Ada", last_name: "Lovelace")
      expect(field_set.to_h).to be_frozen
    end
  end

  describe "#[]" do
    it "reads field values" do
      expect(field_set[:first_name]).to eq("Ada")
    end

    it "returns nil for unknown keys" do
      expect(field_set[:unknown]).to be_nil
    end
  end

  describe "named accessors" do
    it "exposes each symbol key as a real method" do
      expect(field_set.first_name).to eq("Ada")
      expect(field_set.last_name).to eq("Lovelace")
    end

    it "ignores non-symbol keys for named-accessor definitions" do
      set = described_class.new("first_name" => "Ada")
      expect(set["first_name"]).to eq("Ada")
      expect(set.respond_to?(:first_name)).to be false
    end
  end

  describe "#inspect" do
    it "includes the class name and the hash form" do
      expect(field_set.inspect).to eq('#<ServiceCore::FieldSet {first_name: "Ada", last_name: "Lovelace"}>')
    end
  end
end
