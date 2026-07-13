# frozen_string_literal: true

require "ruby_llm"

RSpec.describe Locallingo::Providers::RubyLLM do
  subject(:provider) { described_class.new(provider: :anthropic) }

  describe "#chat" do
    let(:conversation) { double }
    let(:response) { double(content: '{"greeting":"hallo"}') }

    before do
      allow(RubyLLM).to receive(:chat).and_return(conversation)
      allow(conversation).to receive_messages(with_instructions: conversation, ask: response)
    end

    around do |example|
      original = RubyLLM.config.anthropic_api_key
      example.run
    ensure
      RubyLLM.config.anthropic_api_key = original
    end

    it "configures the provider API key from ENV before chatting" do
      RubyLLM.config.anthropic_api_key = nil
      stub_const("ENV", ENV.to_h.merge("ANTHROPIC_API_KEY" => "env-key-123"))

      result = provider.chat(model: "claude-x", instructions: "translate", payload: { "greeting" => "hello" })

      expect(RubyLLM.config.anthropic_api_key).to eq("env-key-123")
      expect(result).to eq({ "greeting" => "hallo" })
    end

    it "does not clobber a key the host app already configured" do
      RubyLLM.config.anthropic_api_key = "explicit-app-key"
      stub_const("ENV", ENV.to_h.merge("ANTHROPIC_API_KEY" => "env-key-123"))

      provider.chat(model: "claude-x", instructions: "translate", payload: { "greeting" => "hello" })

      expect(RubyLLM.config.anthropic_api_key).to eq("explicit-app-key")
    end

    it "leaves configuration untouched when the ENV var is absent" do
      RubyLLM.config.anthropic_api_key = nil
      stub_const("ENV", ENV.to_h.except("ANTHROPIC_API_KEY"))

      provider.chat(model: "claude-x", instructions: "translate", payload: { "greeting" => "hello" })

      expect(RubyLLM.config.anthropic_api_key).to be_nil
    end
  end
end
