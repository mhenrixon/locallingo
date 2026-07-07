# frozen_string_literal: true

# How source-hash state powers drift detection and manual-edit protection.
class Views::Docs::Pages::DriftState < DocsUI::Page
  title "Drift & state"
  eyebrow "Validation & quality"

  def lead = "Per-key source hashes are how locallingo knows what changed — and what's safe to skip."

  def content
    the_idea
    the_files
    outdated
    manual_edits
    syncing
  end

  private

  def the_idea
    DocsUI::Section("The idea") do
      md <<~'MD'
        Re-translating everything on every run is slow and expensive. locallingo
        instead records a small hash of the English value each key was translated
        from. On the next run it re-hashes the current source: if the hash still
        matches, the translation is up to date and is skipped; if it differs, the
        source text changed and the translation is *outdated*.

        The result is that `translate` only touches keys that are genuinely
        missing or changed, and `validate` can tell you exactly which translations
        drifted.
      MD
    end
  end

  def the_files
    DocsUI::Section("The state files") do
      md <<~'MD'
        State lives under `state_dir` (default `.i18n-state/`), split into one JSON
        file per top-level namespace and locale — `accounts.de.json`,
        `admin.sv.json` — so diffs stay small and reviewable. Commit them: they're
        how CI and your teammates share the same view of what's current.
      MD
      DocsUI::Code(<<~'JSON', filename: ".i18n-state/accounts.de.json")
        {
          "accounts.show.title": { "source_hash": "3f2a9c11" }
        }
      JSON
    end
  end

  def outdated
    DocsUI::Section("Detecting drift") do
      md <<~'MD'
        When you edit an English string, its hash changes. The next
        `lingo validate` compares the stored `source_hash` against the current
        value and reports the key as `outdated` for every target locale — so a
        source edit can't silently leave stale translations behind.
      MD
    end
  end

  def manual_edits
    DocsUI::Section("Protecting manual edits") do
      md <<~'MD'
        With `validators.manual_edits` enabled, state entries also carry a
        `target_hash` and a `manual` flag. If someone hand-tunes a translation, its
        target hash no longer matches and `validate` flags a `manual_edit`.
        Running `lingo accept-edits` stamps the current values as intentional
        (setting `manual: true`), and `translate --force` then leaves them alone.
      MD
    end
  end

  def syncing
    DocsUI::Section("Rebuilding state") do
      md <<~'MD'
        Adopting locallingo on an existing app, or making a batch of manual edits,
        can leave the state out of step with the files. `lingo sync` rewrites the
        state from the current translations so nothing reads as spuriously
        outdated.
      MD
      DocsUI::Callout(:note) do
        plain "Run "
        code { "lingo sync" }
        plain " once when you first add locallingo to an app with existing "
        plain "translations — otherwise every key looks 'outdated' until its "
        plain "first translate."
      end
    end
  end
end
