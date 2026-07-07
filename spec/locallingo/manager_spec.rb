# frozen_string_literal: true

require "spec_helper"

RSpec.describe Locallingo::Manager do
  describe "#validate" do
    it "reports missing target keys" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => { "greeting" => { "hi" => "Hello", "bye" => "Goodbye" } },
          "de" => { "greeting" => { "hi" => "Hallo" } }
        }
      ) do |root|
        violations = described_class.new(config: config_for(root)).validate
        expect(violations).to include(a_hash_including(type: :missing, locale: "de", key: "greeting.bye"))
      end
    end

    context "with the duplicate_values validator enabled" do
      it "reports a view-scoped key duplicating an AR attribute value" do
        with_app(
          config: { "target_locales" => %w[de], "validators" => { "duplicate_values" => true } },
          locales: {
            "en" => {
              "activerecord" => { "attributes" => { "user" => { "name" => "Name" } } },
              "admin" => { "users" => { "index" => { "name_column" => "Name" } } }
            }
          }
        ) do |root|
          violations = described_class.new(config: config_for(root)).validate
          expect(violations).to include(
            a_hash_including(
              type: :duplicate_value,
              locale: "en",
              key: "admin.users.index.name_column",
              suggestion: a_string_including("activerecord.attributes.user.name")
            )
          )
        end
      end

      it "does not flag when no duplication exists" do
        with_app(
          config: { "target_locales" => %w[de], "validators" => { "duplicate_values" => true } },
          locales: {
            "en" => {
              "activerecord" => { "attributes" => { "user" => { "name" => "Name" } } },
              "admin" => { "users" => { "index" => { "title" => "User Index" } } }
            }
          }
        ) do |root|
          violations = described_class.new(config: config_for(root)).validate
          expect(violations.select { |v| v[:type] == :duplicate_value }).to be_empty
        end
      end
    end

    it "does not run duplicate_values when disabled (default)" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => {
            "activerecord" => { "attributes" => { "user" => { "name" => "Name" } } },
            "admin" => { "users" => { "index" => { "name_column" => "Name" } } }
          }
        }
      ) do |root|
        violations = described_class.new(config: config_for(root)).validate
        expect(violations.select { |v| v[:type] == :duplicate_value }).to be_empty
      end
    end
  end

  describe "#status" do
    it "counts missing and outdated keys per locale" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => { "greeting" => { "hi" => "Hello", "bye" => "Bye" } },
          "de" => { "greeting" => { "hi" => "Hallo" } }
        }
      ) do |root|
        status = described_class.new(config: config_for(root)).status
        expect(status["de"]).to include(total_keys: 2, translated: 1, missing: 1)
      end
    end
  end

  describe "#translate!" do
    it "translates missing keys via the provider and writes them to the locale file" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => { "greeting" => { "hi" => "Hello", "bye" => "Goodbye" } },
          "de" => { "greeting" => { "hi" => "Hallo" } }
        }
      ) do |root|
        # payload arrives as { "greeting.bye" => "Goodbye" }
        stub_llm_chat { |payload:, **| payload.transform_values { |v| "DE:#{v}" } }

        config = config_for(root)
        described_class.new(config:).translate!(locale: "de")

        de = YAML.load_file(File.join(root, "config/locales/greeting.de.yml"))
        expect(de.dig("de", "greeting", "bye")).to eq("DE:Goodbye")
        expect(de.dig("de", "greeting", "hi")).to eq("Hallo") # untouched
      end
    end

    it "records state so a re-run has nothing to translate" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => { "greeting" => { "hi" => "Hello" } },
          "de" => {}
        }
      ) do |root|
        stub_llm_chat { |payload:, **| payload.transform_values { |v| "DE:#{v}" } }
        config = config_for(root)
        described_class.new(config:).translate!(locale: "de")

        status = described_class.new(config: config_for(root)).status
        expect(status["de"][:missing]).to eq(0)
      end
    end

    it "raises when credentials are missing" do
      with_app(config: { "target_locales" => %w[de] }, locales: { "en" => { "g" => { "h" => "Hi" } } }) do |root|
        stub_llm_missing_credentials
        expect { described_class.new(config: config_for(root)).translate!(locale: "de") }
          .to raise_error(Locallingo::MissingCredentialsError)
      end
    end
  end

  describe "#source_hash" do
    it "is stable across calls and changes when source changes" do
      with_app(config: {}, locales: { "en" => { "g" => { "h" => "Hi" } } }) do |root|
        first = described_class.new(config: config_for(root)).source_hash
        again = described_class.new(config: config_for(root)).source_hash
        expect(first).to eq(again)

        File.write(
          File.join(root, "config/locales/g.en.yml"),
          { "en" => { "g" => { "h" => "Changed" } } }.to_yaml
        )
        expect(described_class.new(config: config_for(root)).source_hash).not_to eq(first)
      end
    end
  end

  describe "#sync_state! then outdated detection" do
    it "flags a key as outdated after its source changes" do
      with_app(
        config: { "target_locales" => %w[de] },
        locales: {
          "en" => { "greeting" => { "hi" => "Hello" } },
          "de" => { "greeting" => { "hi" => "Hallo" } }
        }
      ) do |root|
        config = config_for(root)
        described_class.new(config:).sync_state!

        # Change the English source after state was recorded.
        File.write(
          File.join(root, "config/locales/greeting.en.yml"),
          { "en" => { "greeting" => { "hi" => "Hi there" } } }.to_yaml
        )

        violations = described_class.new(config: config_for(root)).validate
        expect(violations).to include(a_hash_including(type: :outdated, locale: "de", key: "greeting.hi"))
      end
    end
  end
end
