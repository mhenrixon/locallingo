# frozen_string_literal: true

require_relative "../json_extraction"

module Locallingo
  module Providers
    # Thin wrapper over the `ruby_llm` gem. Every translation and quality-review
    # call goes through here so the rest of the gem never touches a provider SDK
    # directly and stays provider-agnostic.
    #
    # A fresh chat is created per call (`assume_model_exists: true` skips
    # RubyLLM's registry lookup — the configured model id is the source of
    # truth) so independent batches don't share conversation history. The
    # response is parsed with the robust JsonExtraction extractor because not
    # every provider guarantees fenceless JSON.
    class RubyLLM
      # Maps a RubyLLM provider symbol to the ENV var whose presence indicates
      # credentials are available, so we can fail fast with a clear message
      # before making a network call.
      CREDENTIAL_ENV = {
        openai: "OPENAI_API_KEY",
        anthropic: "ANTHROPIC_API_KEY",
        gemini: "GEMINI_API_KEY",
        deepseek: "DEEPSEEK_API_KEY",
        openrouter: "OPENROUTER_API_KEY"
      }.freeze

      attr_reader :provider

      def initialize(provider:)
        @provider = provider.to_sym
      end

      # True when credentials for the configured provider are present in ENV.
      # Unknown providers are assumed configured (RubyLLM may source the key
      # elsewhere) rather than blocking.
      def credentials?
        env = CREDENTIAL_ENV[provider]
        return true unless env

        !ENV.fetch(env, "").to_s.strip.empty?
      end

      # Raise a precise error when the provider has no credentials.
      def ensure_credentials!
        return if credentials?

        raise MissingCredentialsError,
              "No credentials for provider #{provider.inspect} " \
              "(expected #{CREDENTIAL_ENV[provider]} in ENV)"
      end

      # Send +instructions+ (system prompt) + +payload+ (user message, JSON) to
      # the model and return the parsed JSON object as a Hash.
      def chat(model:, instructions:, payload:)
        require "ruby_llm"

        conversation = ::RubyLLM.chat(
          model:,
          provider:,
          assume_model_exists: true
        ).with_instructions(instructions)

        response = conversation.ask(JSON.pretty_generate(payload))
        JsonExtraction.extract_object(response.content)
      end
    end
  end
end
