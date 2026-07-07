# frozen_string_literal: true

require "spec_helper"

RSpec.describe Locallingo::KeyFlattener do
  describe ".flatten" do
    it "flattens nested hashes to dotted keys" do
      nested = { "a" => { "b" => { "c" => "deep" } }, "x" => "top" }
      expect(described_class.flatten(nested)).to eq("a.b.c" => "deep", "x" => "top")
    end

    it "indexes string arrays with bracket notation" do
      nested = { "items" => %w[one two] }
      expect(described_class.flatten(nested)).to eq("items[0]" => "one", "items[1]" => "two")
    end

    it "flattens hashes inside arrays" do
      nested = { "rows" => [{ "name" => "a" }, { "name" => "b" }] }
      expect(described_class.flatten(nested)).to eq("rows[0].name" => "a", "rows[1].name" => "b")
    end
  end

  describe ".set_nested_value round-trip" do
    it "rebuilds a nested hash that flattens back to the same keys" do
      flat = { "a.b.c" => "deep", "items[0]" => "one", "items[1]" => "two", "rows[0].name" => "x" }
      nested = {}
      flat.each { |key, value| described_class.set_nested_value(nested, key, value) }

      expect(described_class.flatten(nested)).to eq(flat)
    end

    it "round-trips a single string-array index" do
      # The common real-world shape: a top-level key holding a list of strings.
      nested = {}
      described_class.set_nested_value(nested, "items[2]", "third")
      expect(described_class.flatten(nested)).to eq("items[2]" => "third")
    end
  end
end
