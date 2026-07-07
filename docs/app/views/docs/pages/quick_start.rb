# frozen_string_literal: true

# The five-minute path: status → translate → validate.
class Views::Docs::Pages::QuickStart < DocsUI::Page
  title "Quick start"
  eyebrow "Getting started"

  def lead = "From a config file to translated, validated locales in three commands."

  def content
    check_status
    translate
    validate
    keep_in_sync
  end

  private

  def check_status
    DocsUI::Section("1. See where you stand") do
      md <<~'MD'
        `status` reports, per target locale, how many keys are translated,
        missing, or outdated — no credentials required.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo status
      BASH
      DocsUI::Code(<<~'TEXT', filename: "output")
        📊 Translation Status
        ============================================================

        ⚠️ de
           Total keys: 412
           Translated: 407
           Missing: 5
           Outdated: 0
      TEXT
    end
  end

  def translate
    DocsUI::Section("2. Fill the gaps") do
      md <<~'MD'
        `translate` sends the missing and changed keys to your configured provider
        and merges the results back into `config/locales/`. Only what's actually
        missing or outdated is translated — the source-hash state makes re-runs
        cheap.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo translate            # all target locales
        bin/lingo translate --locale de   # just one
        bin/lingo translate --force       # re-translate everything
      BASH
      DocsUI::Callout(:note) do
        plain "After a successful translate, locallingo runs your configured "
        code { "after_translate" }
        plain " hooks — by default "
        code { "i18n-tasks normalize -p" }
        plain " to keep the YAML tidy."
      end
    end
  end

  def validate
    DocsUI::Section("3. Validate") do
      md <<~'MD'
        `validate` reports anything missing or outdated and, with `--strict`,
        exits non-zero — the command you run in CI.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo validate --strict       # fails on missing / outdated
        bin/lingo validate --strict-all   # also fails on duplicate values
      BASH
    end
  end

  def keep_in_sync
    DocsUI::Section("Keep the state honest") do
      md <<~'MD'
        If you hand-edit locale files (or set up locallingo on an existing app),
        rebuild the drift state from the current translations so nothing reads as
        spuriously outdated:
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo sync
      BASH
      md <<~'MD'
        That's the whole loop. Next: the full [CLI reference](/docs/cli) and how
        [drift & state](/docs/drift-state) tracking works.
      MD
    end
  end
end
