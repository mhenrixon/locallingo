# frozen_string_literal: true

require "spec_helper"

RSpec.describe Locallingo::CLI do
  # Run the CLI inside a tmp app, capturing stdout/stderr and the exit code.
  def run_cli(root, argv)
    out = StringIO.new
    err = StringIO.new
    code = 0
    Dir.chdir(root) do
      original_out = $stdout
      original_err = $stderr
      $stdout = out
      $stderr = err
      begin
        described_class.start(argv)
      rescue SystemExit => e
        code = e.status
      ensure
        $stdout = original_out
        $stderr = original_err
      end
    end
    [out.string, err.string, code]
  end

  let(:locales) do
    {
      "en" => { "greeting" => { "hi" => "Hello", "bye" => "Goodbye" } },
      "de" => { "greeting" => { "hi" => "Hallo" } }
    }
  end

  describe "validate" do
    it "reports missing keys and exits 1 under --strict" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        out, _err, code = run_cli(root, %w[validate --strict])
        expect(out).to include("Translation Issues Found")
        expect(out).to include("greeting.bye")
        expect(code).to eq(1)
      end
    end

    it "exits 0 when there are no violations" do
      full = { "en" => { "greeting" => { "hi" => "Hello" } }, "de" => { "greeting" => { "hi" => "Hallo" } } }
      with_app(config: { "target_locales" => %w[de] }, locales: full) do |root|
        # Sync state so nothing reads as outdated.
        Locallingo::Manager.new(config: config_for(root)).sync_state!
        out, _err, code = run_cli(root, %w[validate --strict])
        expect(out).to include("All translations valid")
        expect(code).to eq(0)
      end
    end
  end

  describe "legacy flag aliases" do
    it "accepts --validate, warns deprecation, and behaves like `validate`" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        out, err, code = run_cli(root, %w[--validate --strict])
        expect(err).to match(/\[deprecated\].*--validate.*use `lingo validate`/)
        expect(out).to include("greeting.bye")
        expect(code).to eq(1)
      end
    end
  end

  describe "status (default command)" do
    it "prints status when no command is given" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        out, _err, _code = run_cli(root, [])
        expect(out).to include("Translation Status")
        expect(out).to include("Missing: 1")
      end
    end
  end

  describe "hash" do
    it "prints the source hash as json with --json" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        out, _err, _code = run_cli(root, %w[hash --json])
        expect(out).to include('"hash":')
      end
    end
  end

  describe ".locallingo.rb setup file" do
    it "loads it before dispatch so it can configure credentials" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        File.write(
          File.join(root, ".locallingo.rb"),
          'Locallingo.configure { |c| c.anthropic_api_key = "from-setup" }'
        )

        _out, _err, code = run_cli(root, %w[status])

        expect(code).to eq(0)
        expect(Locallingo.settings.anthropic_api_key).to eq("from-setup")
      end
    end

    it "runs silently without one" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        _out, err, code = run_cli(root, %w[status])
        expect(code).to eq(0)
        expect(err).to be_empty
      end
    end

    it "propagates errors from the setup file instead of swallowing them" do
      with_app(config: { "target_locales" => %w[de] }, locales:) do |root|
        File.write(File.join(root, ".locallingo.rb"), "NoSuchConstant.boom!")

        expect { run_cli(root, %w[status]) }.to raise_error(NameError, /NoSuchConstant/)
      end
    end
  end
end
