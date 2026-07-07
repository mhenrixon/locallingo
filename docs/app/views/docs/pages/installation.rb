# frozen_string_literal: true

# Getting locallingo into an app: the gem, the config file, and credentials.
class Views::Docs::Pages::Installation < DocsUI::Page
  title "Installation"
  eyebrow "Getting started"

  def lead = "Add the gem, create a config file, and point it at your LLM provider."

  def content
    add_the_gem
    binstub
    credentials
    config_file
  end

  private

  def add_the_gem
    DocsUI::Section("Add the gem", description: "In your app's Gemfile.") do
      md <<~'MD'
        locallingo is a development-time tool — it never runs in production — so
        put it in the `:development` group. It pulls in
        [RubyLLM](https://github.com/crmne/ruby_llm) as its provider client.
      MD
      DocsUI::Code(<<~'RUBY', filename: "Gemfile")
        group :development do
          gem "locallingo"
        end
      RUBY
      md <<~'MD'
        Then `bundle install`.
      MD
    end
  end

  def binstub
    DocsUI::Section("Generate the binstub") do
      md <<~'MD'
        The gem installs an executable called `lingo`. Generate a binstub so you
        can run it via `bin/lingo` inside your app's bundle:
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bundle binstubs locallingo
      BASH
    end
  end

  def credentials
    DocsUI::Section("Provider credentials") do
      md <<~'MD'
        locallingo never stores API keys. RubyLLM reads them from the environment
        based on the provider you configure — for example `OPENAI_API_KEY` for
        OpenAI or `ANTHROPIC_API_KEY` for Anthropic.
      MD
      DocsUI::Code(<<~'BASH', filename: ".env")
        OPENAI_API_KEY=sk-...
      BASH
      DocsUI::Callout(:note) do
        plain "Only translation and the optional AI quality pass need credentials. "
        plain "`status`, `validate`, `sync`, and the static quality checks run "
        plain "with no key at all."
      end
    end
  end

  def config_file
    DocsUI::Section("Create the config file") do
      md <<~'MD'
        Add a `.locallingo.yml` at your app root. The smallest useful config names
        your source and target locales; every other key has a sensible default
        (see the [Configuration reference](/docs/configuration-reference)).
      MD
      DocsUI::Code(<<~'YAML', filename: ".locallingo.yml")
        defaults:
          source_locale: en
          target_locales: [de, sv]

          provider: openai
          translate:
            model: gpt-5-mini
          quality:
            model: gpt-4o-mini

          context: "Acme, a business application"
          glossary:
            entity: "business/company account holder"
      YAML
      md <<~'MD'
        That's it — head to the [Quick start](/docs/quick-start).
      MD
    end
  end
end
