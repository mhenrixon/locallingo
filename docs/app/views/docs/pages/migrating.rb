# frozen_string_literal: true

# Moving from a home-grown bin/translate script to locallingo.
class Views::Docs::Pages::Migrating < DocsUI::Page
  title "Migrating from a script"
  eyebrow "Guides"

  def lead = "Already have a bin/translate script? locallingo replaces it — here's the swap."

  def content
    why
    steps
    flag_mapping
    keep_state
  end

  private

  def why
    DocsUI::Section("Why migrate") do
      md <<~'MD'
        locallingo *is* the extracted, maintained version of the `bin/translate`
        script that tends to grow inside each app. Moving to it means the same
        behaviour — AI translation, drift detection, quality linting — but shared
        across your apps, with a config file instead of hardcoded constants, and
        the same drift-state format you already have.
      MD
    end
  end

  def steps
    DocsUI::Section("The swap") do
      md <<~'MD'
        1. Add the gem and generate the binstub (see [Installation](/docs/installation)).
        2. Move your script's hardcoded values — target locales, provider/model,
           prompt context and glossary, language guides — into `.locallingo.yml`.
        3. Point your existing `.i18n-state/` directory at `state_dir` (the default
           `.i18n-state` matches most scripts). Run `lingo sync` if the format
           differs.
        4. Replace `bin/translate` calls in CI and docs with `bin/lingo`.
        5. Delete the old `bin/translate` and `lib/tools/*` files.
      MD
    end
  end

  def flag_mapping
    DocsUI::Section("Flag → subcommand") do
      md <<~'MD'
        The old flag forms still work (with a deprecation notice), so you can move
        callers over gradually. The mapping:
      MD
      DocsUI::Code(<<~'TEXT', filename: "old → new")
        bin/translate --status         → bin/lingo status
        bin/translate --translate      → bin/lingo translate
        bin/translate --validate       → bin/lingo validate
        bin/translate --check-quality  → bin/lingo quality
        bin/translate --fix-quality    → bin/lingo fix-quality
        bin/translate --sync-state     → bin/lingo sync
      TEXT
    end
  end

  def keep_state
    DocsUI::Section("Keep the drift state") do
      md <<~'MD'
        If your script tracked source hashes the same way (per-namespace JSON under
        `.i18n-state/`), locallingo picks them up as-is — no re-translation needed.
        If the format differs, run `lingo sync` once to rebuild the state from your
        current translations, then commit it.
      MD
    end
  end
end
