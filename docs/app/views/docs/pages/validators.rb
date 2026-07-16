# frozen_string_literal: true

# The four validators, their violation types, and when to enable each.
class Views::Docs::Pages::Validators < DocsUI::Page
  title "Validators"
  eyebrow "Validation & quality"

  def lead = "What lingo validate checks — each validator is config-gated and maps to a violation type."

  def content
    overview
    missing
    outdated
    duplicate_values
    manual_edits
  end

  private

  def overview
    DocsUI::Section("Config-gated checks") do
      md <<~'MD'
        `validate` runs the validators you enable under `validators:` and reports
        their violations. Each violation has a *type*; the `strict` tiers decide
        which types make the command exit non-zero (see the
        [Configuration reference](/docs/configuration-reference)).

        | Validator | Type | Default |
        | --- | --- | --- |
        | Missing | `missing` | on |
        | Outdated | `outdated` | on |
        | Duplicate values | `duplicate_value` | off |
        | Manual edits | `manual_edit` | off |
      MD
    end
  end

  def missing
    DocsUI::Section("Missing") do
      md <<~'MD'
        Reports keys present in the source locale but absent from a target locale —
        the untranslated ones. The fix is a `lingo translate`.
      MD
    end
  end

  def outdated
    DocsUI::Section("Outdated") do
      md <<~'MD'
        Reports target keys whose recorded source hash no longer matches the
        current English value — i.e. the source text changed after the translation
        was made, so the translation may no longer be accurate. See
        [Drift & state](/docs/drift-state) for how this is tracked. The fix is
        `lingo translate` (or `--force-key` for a single key). For keys flagged
        `manual` the suggestion differs: update the hand-curated value yourself,
        then `accept-edits --key` it — machine translation is never pushed onto
        protected keys.
      MD
    end
  end

  def duplicate_values
    DocsUI::Section("Duplicate values") do
      md <<~'MD'
        Flags a source-locale key whose value matches an
        `activerecord.attributes.*` value — a sign you're re-declaring a label
        Rails already provides. The AR key wins; the offending key should reuse
        it. Runs on the source locale only, to avoid false positives from
        grammatical differences in other locales. Off by default; enable it and
        add `duplicate_value` to your `strict_all` tier for a stricter CI gate.
      MD
    end
  end

  def manual_edits
    DocsUI::Section("Manual edits") do
      md <<~'MD'
        When enabled, locallingo records a `target_hash` alongside each key's
        source hash. If a target value's current hash no longer matches — someone
        hand-edited it — this validator surfaces it so the next `translate`
        doesn't silently overwrite the edit. Confirm the edit with
        `lingo accept-edits --locale <l> --key <key>` to protect that key (or run
        it unscoped to accept every flagged edit). See
        [Drift & state](/docs/drift-state).
      MD
    end
  end
end
