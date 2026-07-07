# frozen_string_literal: true

# What locallingo is, why it exists, and the shape of the toolchain.
class Views::Docs::Pages::Overview < DocsUI::Page
  title "Overview"
  eyebrow "Getting started"

  def lead
    "locallingo extends i18n-tasks with AI translation, source-hash drift " \
      "detection, and quality linting — driven entirely by a single config file, " \
      "with a subcommand CLI and shipped RuboCop cops."
  end

  def content
    what_it_is
    what_you_get
    how_it_fits
    where_next
  end

  private

  def what_it_is
    DocsUI::Section("One toolchain, every app", description: "The whole point.") do
      md <<~'MD'
        Most Rails apps grow the same `bin/translate` script: a wrapper around
        i18n-tasks that calls an LLM to fill in missing translations, tracks what
        changed, and lints the results. Copied between apps, it forks — bug fixes
        and features drift instead of compounding.

        **locallingo is that script, extracted into a gem.** Everything
        app-specific — target locales, provider and model, prompt context and
        glossary, per-language style guides, which validators and quality rules
        run, and post-translate hooks — lives in a `.locallingo.yml` file, with a
        default block plus optional per-package overrides. The behaviour is the
        same in every app; only the config differs.
      MD

      DocsUI::Callout(:note) do
        plain "locallingo sits on top of "
        a(href: "https://github.com/glebm/i18n-tasks", class: "link") { "i18n-tasks" }
        plain ", which it shells out to for normalization. It reads and writes the "
        plain "same flat "
        code { "config/locales/<namespace>.<locale>.yml" }
        plain " files your app already uses."
      end
    end
  end

  def what_you_get
    DocsUI::Section("What you get") do
      md <<~'MD'
        - **AI translation** — translate missing and changed keys through
          [RubyLLM](https://github.com/crmne/ruby_llm): OpenAI, Anthropic, Google,
          and more, chosen by config. Only the keys that actually changed.
        - **Drift detection** — a per-key source hash records the English value a
          translation was made from, so a later edit to the source marks every
          locale's copy *outdated* instead of letting it silently go stale.
        - **CI validation** — `lingo validate --strict` fails on missing and
          outdated keys; `--strict-all` adds duplicate-value and (optional)
          manual-edit checks.
        - **Quality linting** — regex rules, configurable terminology lists,
          optional British-spelling drift, and an optional AI review — with
          auto-fix for the fixable ones.
        - **Multi-package** — one default config plus per-`package` overrides, so
          an engine or gem can translate to its own locales with its own prompt.
        - **RuboCop cops** — `Locallingo/RelativeI18nKey` (with autocorrect) and
          `Locallingo/StrftimeInView`, enforcing fully-qualified keys and
          locale-aware date formatting.
      MD
    end
  end

  def how_it_fits
    DocsUI::Section("How it fits together") do
      md <<~'MD'
        You author English in `config/locales/*.en.yml`. locallingo hashes each
        source value into `.i18n-state/`, translates the missing/changed keys to
        your target locales through your configured provider, and merges the
        results back into the matching locale files. `validate` compares the
        current state against those hashes to report what's missing or outdated;
        `quality` lints the text; the RuboCop cops keep your `t()` calls
        fully-qualified.

        The `lingo` CLI is the entry point; everything it does is also available
        programmatically through `Locallingo::Manager` and
        `Locallingo::QualityChecker`.
      MD
    end
  end

  def where_next
    DocsUI::Section("Where next") do
      md <<~'MD'
        - New here? [Installation](/docs/installation) → [Quick start](/docs/quick-start).
        - Setting it up for your app? [Configuration](/docs/configuration) and the
          [Configuration reference](/docs/configuration-reference).
        - Wiring CI? [Continuous integration](/docs/ci).
        - Coming from your own `bin/translate`? [Migrating from a script](/docs/migrating).
      MD
    end
  end
end
