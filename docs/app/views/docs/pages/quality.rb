# frozen_string_literal: true

# Quality linting: static rules, terminology, British spellings, AI, auto-fix.
class Views::Docs::Pages::Quality < DocsUI::Page
  title "Quality linting"
  eyebrow "Validation & quality"

  def lead = "Catch awkward, informal, or inconsistent copy — statically, and optionally with an AI pass."

  def content
    running
    static_rules
    terminology
    british
    ai_pass
    fixing
  end

  private

  def running
    DocsUI::Section("Running quality") do
      md <<~'MD'
        `quality` lints a locale's text (the source locale by default) and prints
        suggestions grouped by severity. It runs entirely offline unless you pass
        `--ai`.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo quality                 # lint the source locale
        bin/lingo quality --locale de     # lint a target locale
        bin/lingo quality --ai            # add an AI review pass
      BASH
    end
  end

  def static_rules
    DocsUI::Section("Static rules") do
      md <<~'MD'
        A set of regex rules flags common issues without any model call:

        - **Terminology** — `cannot` vs `can not`, verb `log in` vs noun `login`,
          `click here`, doubled `please`.
        - **Clarity** — vague words (`stuff`, `things`), abbreviations (`ASAP`,
          `FYI`), double spaces.
        - **Business tone** — `sorry`, `oops`, `awesome`, `cool`.
        - **Accessibility** — positional references (`see below`, `above`),
          colour-only meaning.
        - **Placeholders** — spaces inside `%{…}`, uppercase placeholder names.
      MD
    end
  end

  def terminology
    DocsUI::Section("Terminology lists") do
      md <<~'MD'
        `quality.terminology` selects a built-in list — `business` (the default)
        or `banking` — or a path to your own YAML mapping terms to suggestions
        (a `nil` suggestion marks a term as reviewed and acceptable). Flagged
        terms produce info-level suggestions, e.g. "wire transfer → consider
        'bank transfer'".
      MD
    end
  end

  def british
    DocsUI::Section("British spellings") do
      md <<~'MD'
        With `quality.british_spellings: true`, the source locale is checked for
        American→British drift (`organization → organisation`, `color → colour`,
        `analyze → analyse`, …). These are auto-fixable.
      MD
    end
  end

  def ai_pass
    DocsUI::Section("The AI pass") do
      md <<~'MD'
        `--ai` samples the locale and asks your `quality.model` to suggest
        improvements for clarity, professionalism, and friendliness, each tagged
        with a severity. It samples rather than reviewing everything, to keep the
        cost bounded. Needs provider credentials; without them it warns and skips.
      MD
    end
  end

  def fixing
    DocsUI::Section("Auto-fixing") do
      md <<~'MD'
        `fix-quality` rewrites the *fixable* suggestions — the universal fixes
        (`can not → cannot`) and British spellings — back into the locale files,
        preserving the original case. Preview first with `--dry-run`.
      MD
      DocsUI::Code(<<~'BASH', filename: "shell")
        bin/lingo fix-quality --locale en --dry-run
        bin/lingo fix-quality --locale en
      BASH
    end
  end
end
