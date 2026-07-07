# frozen_string_literal: true

# The .locallingo.yml file: the defaults block, how values resolve, and ERB.
class Views::Docs::Pages::Configuration < DocsUI::Page
  title "Configuration"
  eyebrow "Configuration"

  def lead = "Everything app-specific lives in .locallingo.yml — a defaults block plus optional per-package overrides."

  def content
    the_file
    defaults_block
    resolution
    erb
  end

  private

  def the_file
    DocsUI::Section("The file", description: ".locallingo.yml at your app root.") do
      md <<~'MD'
        locallingo reads a single YAML file, `.locallingo.yml` (or
        `.locallingo.yaml`), from your app root. It has a `defaults:` block that
        applies to the whole app and an optional `packages:` list for per-location
        overrides. With no config file at all, the shipped defaults are used.
      MD
    end
  end

  def defaults_block
    DocsUI::Section("The defaults block") do
      md <<~'MD'
        A representative config. Every key has a default, so you only set what
        differs from the shipped values — see the full list on the
        [Configuration reference](/docs/configuration-reference).
      MD
      DocsUI::Code(<<~'YAML', filename: ".locallingo.yml")
        defaults:
          source_locale: en
          target_locales: [de, sv]

          locales_dir: config/locales
          state_dir: .i18n-state

          provider: openai
          translate:
            model: gpt-5-mini
            batch_size: 20
          quality:
            model: gpt-4o-mini
            british_spellings: false
            terminology: business

          context: "Acme, a business application"
          glossary:
            entity: "business/company account holder"
          language_guides:
            de:
              file: config/locales/.guides/de.md

          validators:
            missing: true
            outdated: true
            duplicate_values: true
            manual_edits: false

          strict:
            strict: [missing, outdated]
            strict_all: [missing, outdated, duplicate_value]

          after_translate:
            - "bundle exec i18n-tasks normalize -p"
      YAML
    end
  end

  def resolution
    DocsUI::Section("How values resolve") do
      md <<~'MD'
        A resolved config is the shipped defaults, deep-merged with your
        `defaults:` block, deep-merged with the selected `packages:` entry (if
        you pass `--package`). "Deep-merged" means a package that overrides one
        `quality.model` keeps the sibling `quality.british_spellings` from the
        defaults — you never restate a whole sub-tree to change one key. See
        [Multiple packages](/docs/packages).
      MD
    end
  end

  def erb
    DocsUI::Section("ERB and secrets") do
      md <<~'MD'
        The file is ERB-evaluated, so `<%= ENV["SOMETHING"] %>` works for values
        you want to vary by environment.
      MD
      DocsUI::Callout(:warning) do
        plain "Never put raw API keys in "
        code { ".locallingo.yml" }
        plain ". The LLM provider reads its own credentials from the environment "
        plain "via RubyLLM — locallingo never stores keys."
      end
    end
  end
end
