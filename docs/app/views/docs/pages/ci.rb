# frozen_string_literal: true

# Wiring lingo validate into CI.
class Views::Docs::Pages::Ci < DocsUI::Page
  title "Continuous integration"
  eyebrow "Guides"

  def lead = "Make CI fail when translations fall behind — one command, no credentials."

  def content
    the_gate
    github_actions
    tiers
    committing
  end

  private

  def the_gate
    DocsUI::Section("The gate") do
      md <<~'MD'
        `lingo validate --strict` is the CI command. It reads the committed locale
        files and `.i18n-state/`, reports what's missing or outdated, and exits `1`
        if any strict-tier violation is present — no API key required, so it's safe
        to run on every build.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bundle exec bin/lingo validate --strict
      BASH
    end
  end

  def github_actions
    DocsUI::Section("GitHub Actions") do
      md <<~'MD'
        Add it as a step after `bundle install`:
      MD
      DocsUI::Code(<<~'YAML', filename: ".github/workflows/ci.yml")
        - name: Validate translations
          run: bundle exec bin/lingo validate --strict
      YAML
    end
  end

  def tiers
    DocsUI::Section("Choosing a tier") do
      md <<~'MD'
        `--strict` fails on the `strict` tier (missing + outdated by default) — the
        pragmatic gate that keeps translations from silently falling behind.
        `--strict-all` uses the `strict_all` tier, which additionally fails on
        duplicate values (and, if enabled, manual edits) — a stricter bar for teams
        that want zero drift. Both tiers are configurable; see the
        [Configuration reference](/docs/configuration-reference).
      MD
    end
  end

  def committing
    DocsUI::Section("Commit the state") do
      md <<~'MD'
        For CI to detect drift, the `.i18n-state/` files must be committed
        alongside the locale files — they're the shared record of which source
        value each translation was made from. Treat them like any other source
        file in review.
      MD
      DocsUI::Callout(:note) do
        plain "Use "
        code { "lingo hash" }
        plain " as a cache key to skip translation steps when the source locale "
        plain "hasn't changed between builds."
      end
    end
  end
end
