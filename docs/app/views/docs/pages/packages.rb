# frozen_string_literal: true

# Per-package overrides: one app, many locale sets and prompts.
class Views::Docs::Pages::Packages < DocsUI::Page
  title "Multiple packages"
  eyebrow "Configuration"

  def lead = "One default config, plus per-directory overrides for engines, gems, or packages."

  def content
    why
    declaring
    running
    inheritance
  end

  private

  def why
    DocsUI::Section("Why packages") do
      md <<~'MD'
        A monorepo or an engine-heavy app often has more than one set of locales:
        a billing engine that ships to different markets than the host, a gem with
        its own prompt and glossary. `packages:` lets each location override the
        defaults it needs while inheriting everything else — so you keep one
        config file, not one per package.

        Most apps never need this; an empty `packages:` (the default) means the
        whole app uses `defaults`.
      MD
    end
  end

  def declaring
    DocsUI::Section("Declaring packages") do
      md <<~'MD'
        Each entry has a `path` (relative to the app root) and any keys it
        overrides. Paths like `locales_dir` and `state_dir` resolve *under* the
        package path.
      MD
      DocsUI::Code(<<~'YAML', filename: ".locallingo.yml")
        defaults:
          target_locales: [de, sv]
          context: "Acme, a business application"

        packages:
          - path: engines/billing
            context: "the Acme billing engine"
            target_locales: [de]
            quality:
              british_spellings: true
      YAML
    end
  end

  def running
    DocsUI::Section("Running against a package") do
      md <<~'MD'
        Pass `--package` with the same `path` to scope any command to that
        package's config, locales, and state.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo status   --package engines/billing
        bin/lingo translate --package engines/billing --locale de
        bin/lingo validate --package engines/billing --strict
      BASH
    end
  end

  def inheritance
    DocsUI::Section("What's inherited") do
      md <<~'MD'
        A package entry is deep-merged onto `defaults`. In the example above, the
        billing package overrides `context`, narrows `target_locales` to `[de]`,
        and turns on `quality.british_spellings` — while still inheriting the
        default `provider`, models, `validators`, and `strict` tiers. You only
        restate what changes.
      MD
    end
  end
end
