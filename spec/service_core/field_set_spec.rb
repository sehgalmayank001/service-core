require "spec_helper"

RSpec.describe ServiceCore::FieldSet do
  let(:field_set) { described_class.new(first_name: "Ada", last_name: "Lovelace") }

  describe "#initialize" do
    it "freezes the snapshot hash" do
      expect(field_set.to_h).to be_frozen
    end

    it "defaults to an empty snapshot" do
      expect(described_class.new.to_h).to eq({})
    end

    it "ignores non-symbol keys for the named-accessor definitions" do
      set = described_class.new("first_name" => "Ada")
      expect(set["first_name"]).to eq("Ada")
      expect(set.respond_to?(:first_name)).to be false
    end
  end

  describe "hash-style access" do
    it "reads via []" do
      expect(field_set[:first_name]).to eq("Ada")
    end

    it "returns nil for missing keys (Hash parity)" do
      expect(field_set[:unknown]).to be_nil
    end

    it "responds to key?, has_key? and include?" do
      expect(field_set.key?(:first_name)).to be true
      expect(field_set).to have_key(:first_name)
      expect(field_set).to include(:first_name)
      expect(field_set.key?(:unknown)).to be false
    end
  end

  describe "named accessors" do
    it "exposes each symbol key as a real method" do
      expect(field_set.first_name).to eq("Ada")
      expect(field_set.last_name).to eq("Lovelace")
    end

    it "advertises the methods via respond_to?" do
      expect(field_set.respond_to?(:first_name)).to be true
    end
  end

  describe "#fetch" do
    it "returns the value when present" do
      expect(field_set.fetch(:first_name)).to eq("Ada")
    end

    it "uses a default when missing" do
      expect(field_set.fetch(:unknown, "fallback")).to eq("fallback")
    end

    it "yields the missing key" do
      expect(field_set.fetch(:unknown) { |k| "no #{k}" }).to eq("no unknown")
    end

    it "raises KeyError when no default or block" do
      expect { field_set.fetch(:unknown) }.to raise_error(KeyError)
    end
  end

  describe "iteration" do
    it "exposes keys/values in insertion order" do
      expect(field_set.keys).to eq(%i[first_name last_name])
      expect(field_set.values).to eq(%w[Ada Lovelace])
    end

    it "each_pair yields every member" do
      pairs = field_set.each_pair.to_a
      expect(pairs).to eq([[:first_name, "Ada"], [:last_name, "Lovelace"]])
    end
  end

  describe "equality" do
    it "compares equal to an equivalent Hash" do
      expect(field_set).to eq(first_name: "Ada", last_name: "Lovelace")
    end

    it "compares equal to another FieldSet with the same contents" do
      expect(field_set).to eq(described_class.new(first_name: "Ada", last_name: "Lovelace"))
    end

    it "has a hash code consistent with to_h" do
      expect(field_set.hash).to eq(field_set.to_h.hash)
    end
  end

  describe "string representations" do
    it "to_s mirrors the Hash form" do
      expect(field_set.to_s).to eq({ first_name: "Ada", last_name: "Lovelace" }.to_s)
    end

    it "inspect includes the class name" do
      expect(field_set.inspect).to include("ServiceCore::FieldSet")
    end
  end

  describe "#dig" do
    let(:nested) { described_class.new(user: { profile: { name: "Ada" } }) }

    it "drills into nested values" do
      expect(nested.dig(:user, :profile, :name)).to eq("Ada")
    end
  end

  describe "pattern matching" do
    it "supports `case ... in { first_name: }` matching" do
      matched =
        case field_set
        in { first_name: }
          first_name
        else
          nil
        end
      expect(matched).to eq("Ada")
    end
  end

  describe "immutability" do
    it "does not expose a mutable view of the snapshot" do
      expect { field_set.to_h[:first_name] = "Grace" }.to raise_error(FrozenError)
    end
  end

  describe "JSON serialisation" do
    it "as_json returns the hash form" do
      expect(field_set.as_json).to eq("first_name" => "Ada", "last_name" => "Lovelace")
    end

    it "to_json serialises like the hash form" do
      expect(field_set.to_json).to eq({ first_name: "Ada", last_name: "Lovelace" }.to_json)
    end
  end
end
