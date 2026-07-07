# frozen_string_literal: true

# Stubs Locallingo::Providers::RubyLLM so specs never make a network call. The
# stubbed provider returns a canned Hash (or raises) for #chat and reports
# credentials present by default.
module RubyLLMStub
  # Replace the provider's #chat with a lambda that receives the payload and
  # returns the response hash. Also forces #credentials? true.
  def stub_llm_chat(provider_class: Locallingo::Providers::RubyLLM, &responder)
    allow_any_instance_of(provider_class).to receive(:credentials?).and_return(true)
    allow_any_instance_of(provider_class).to receive(:ensure_credentials!).and_return(nil)
    allow_any_instance_of(provider_class).to(receive(:chat)) do |_instance, model:, instructions:, payload:|
      yield(payload:, model:, instructions:)
    end
  end

  def stub_llm_missing_credentials(provider_class: Locallingo::Providers::RubyLLM)
    allow_any_instance_of(provider_class).to receive(:credentials?).and_return(false)
    allow_any_instance_of(provider_class).to receive(:ensure_credentials!)
      .and_raise(Locallingo::MissingCredentialsError, "No credentials")
  end
end

RSpec.configure { |config| config.include RubyLLMStub }
