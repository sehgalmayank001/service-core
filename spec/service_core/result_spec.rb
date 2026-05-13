require "spec_helper"

RSpec.describe ServiceCore::Result do
  describe "#initialize" do
    it "defaults status to 'initialized' and other keys to nil" do
      result = described_class.new
      expect(result.status).to eq("initialized")
      expect(result.data).to be_nil
      expect(result.message).to be_nil
      expect(result.errors).to be_nil
    end

    it "accepts keyword overrides" do
      result = described_class.new(status: "success", data: { id: 1 }, message: "ok")
      expect(result.status).to eq("success")
      expect(result.data).to eq(id: 1)
      expect(result.message).to eq("ok")
    end
  end

  describe "hash-style access" do
    let(:result) { described_class.new(status: "success") }

    it "reads via []" do
      expect(result[:status]).to eq("success")
      expect(result[:message]).to be_nil
    end

    it "writes via []=" do
      result[:data] = { id: 1 }
      expect(result.data).to eq(id: 1)
    end

    it "raises ArgumentError for invalid read keys" do
      expect { result[:invalid] }.to raise_error(
        ArgumentError, "Invalid key. Allowed keys are: status, data, message, errors"
      )
    end

    it "raises ArgumentError for invalid write keys" do
      expect { result[:invalid] = "x" }.to raise_error(
        ArgumentError, "Invalid key. Allowed keys are: status, data, message, errors"
      )
    end
  end

  describe "#fetch" do
    let(:result) { described_class.new(status: "success") }

    it "returns the value when present" do
      expect(result.fetch(:status)).to eq("success")
    end

    it "returns the default when value is nil" do
      expect(result.fetch(:message, "fallback")).to eq("fallback")
    end

    it "yields when value is nil and a block is provided" do
      expect(result.fetch(:message) { |k| "default for #{k}" }).to eq("default for message")
    end

    it "raises KeyError when no default and no block" do
      expect { result.fetch(:message) }.to raise_error(KeyError, /message/)
    end

    it "raises ArgumentError for invalid keys" do
      expect { result.fetch(:invalid) }.to raise_error(ArgumentError)
    end
  end

  describe "key/value introspection" do
    let(:result) { described_class.new(status: "success", data: { id: 1 }) }

    it "key? returns true only for set keys" do
      expect(result.key?(:status)).to be true
      expect(result.key?(:data)).to be true
      expect(result.key?(:message)).to be false
      expect(result.key?(:errors)).to be false
    end

    it "exposes Hash-compatible aliases" do
      expect(result).to have_key(:status)
      expect(result).to include(:status)
    end

    it "keys returns only set entries in canonical order" do
      expect(result.keys).to eq(%i[status data])
    end

    it "values mirrors keys" do
      expect(result.values).to eq(["success", { id: 1 }])
    end

    it "each_pair yields set entries" do
      pairs = result.each_pair.to_a
      expect(pairs).to eq([[:status, "success"], [:data, { id: 1 }]])
    end
  end

  describe "#to_h" do
    it "returns only set keys" do
      result = described_class.new(status: "success", data: false)
      expect(result.to_h).to eq(status: "success", data: false)
    end

    it "honours legitimate falsy values" do
      result = described_class.new(status: "success", data: 0, message: "")
      expect(result.to_h).to eq(status: "success", data: 0, message: "")
    end

    it "omits nil entries" do
      expect(described_class.new(status: "success").to_h).to eq(status: "success")
    end
  end

  describe "string representations" do
    let(:result) { described_class.new(status: "success", message: "ok") }

    it "to_s matches the hash form (puts compatibility)" do
      expect(result.to_s).to eq({ status: "success", message: "ok" }.to_s)
    end

    it "inspect includes the class name and the hash form" do
      expect(result.inspect).to eq("#<ServiceCore::Result {status: \"success\", message: \"ok\"}>")
    end
  end

  describe "equality" do
    let(:result) { described_class.new(status: "success", data: { id: 1 }) }

    it "compares equal to an equivalent Hash" do
      expect(result).to eq(status: "success", data: { id: 1 })
    end

    it "compares equal to another Result with the same contents" do
      expect(result).to eq(described_class.new(status: "success", data: { id: 1 }))
    end

    it "is unequal to a Hash with different contents" do
      expect(result).not_to eq(status: "error")
    end

    it "exposes a hash code consistent with to_h" do
      expect(result.hash).to eq(result.to_h.hash)
    end
  end

  describe "#dig" do
    let(:result) { described_class.new(data: { user: { name: "Ada" } }) }

    it "drills into nested values" do
      expect(result.dig(:data, :user, :name)).to eq("Ada")
    end

    it "returns nil when an intermediate value is missing" do
      expect(result.dig(:data, :user, :missing)).to be_nil
    end

    it "raises ArgumentError on an invalid root key" do
      expect { result.dig(:invalid, :anything) }.to raise_error(ArgumentError)
    end
  end

  describe "pattern matching" do
    it "supports `case ... in { status:, data: }` matching" do
      result = described_class.new(status: "success", data: { id: 1 })
      matched =
        case result
        in { status: "success", data: }
          data
        else
          nil
        end
      expect(matched).to eq(id: 1)
    end
  end

  describe "JSON serialisation" do
    let(:result) { described_class.new(status: "success", data: { id: 1 }) }

    it "as_json returns the hash form" do
      expect(result.as_json).to eq("status" => "success", "data" => { "id" => 1 })
    end

    it "to_json serialises like the hash form" do
      expect(result.to_json).to eq({ status: "success", data: { id: 1 } }.to_json)
    end
  end

  describe ".from" do
    it "coerces a Hash, dropping unknown keys" do
      result = described_class.from(status: "success", data: { id: 1 }, ignored: true)
      expect(result.status).to eq("success")
      expect(result.data).to eq(id: 1)
    end

    it "tolerates string keys" do
      result = described_class.from("status" => "success")
      expect(result.status).to eq("success")
    end

    it "returns a dup of an existing Result" do
      original = described_class.new(status: "success")
      copy = described_class.from(original)
      expect(copy).to eq(original)
      expect(copy).not_to equal(original)
    end

    it "raises ArgumentError for other types" do
      expect { described_class.from(123) }.to raise_error(ArgumentError, /Cannot coerce/)
    end
  end
end
