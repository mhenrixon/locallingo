# frozen_string_literal: true

require "spec_helper"

RSpec.describe Locallingo::StateStore do
  describe "#save" do
    it "does not rewrite a namespace file whose content is unchanged" do
      Dir.mktmpdir("locallingo-state") do |dir|
        store = described_class.new(dir)
        store.save("de", { "a.x" => { "source_hash" => "11111111" } })

        file = File.join(dir, "a.de.json")
        File.utime(Time.at(0), Time.at(0), file)

        store.save("de", { "a.x" => { "source_hash" => "11111111" } })

        expect(File.mtime(file)).to eq(Time.at(0))
      end
    end

    it "rewrites when content changed" do
      Dir.mktmpdir("locallingo-state") do |dir|
        store = described_class.new(dir)
        store.save("de", { "a.x" => { "source_hash" => "11111111" } })

        store.save("de", { "a.x" => { "source_hash" => "22222222" } })

        expect(store.load("de").dig("a.x", "source_hash")).to eq("22222222")
      end
    end

    it "deletes namespace files whose keys are all gone" do
      Dir.mktmpdir("locallingo-state") do |dir|
        store = described_class.new(dir)
        store.save("de", { "a.x" => { "source_hash" => "11111111" }, "b.y" => { "source_hash" => "22222222" } })

        store.save("de", { "b.y" => { "source_hash" => "22222222" } })

        expect(File).not_to exist(File.join(dir, "a.de.json"))
        expect(File).to exist(File.join(dir, "b.de.json"))
      end
    end
  end
end
