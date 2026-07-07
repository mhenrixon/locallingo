# frozen_string_literal: true

# The shipped i18n RuboCop cops and how to enable them.
class Views::Docs::Pages::RubocopCops < DocsUI::Page
  title "RuboCop cops"
  eyebrow "Enforcement"

  def lead = "locallingo ships two i18n cops so fully-qualified keys and locale-aware dates are enforced, not just documented."

  def content
    enabling
    relative_i18n_key
    strftime_in_view
    rails_cops
  end

  private

  def enabling
    DocsUI::Section("Enabling the cops") do
      md <<~'MD'
        The cops load lazily — `require`ing them pulls in RuboCop, which is a
        development-time dependency, never a runtime one. In your app's
        `.rubocop.yml`:
      MD
      DocsUI::Code(<<~'YAML', filename: ".rubocop.yml")
        require:
          - locallingo/rubocop
        inherit_gem:
          locallingo: config/default.yml
      YAML
      md <<~'MD'
        `inherit_gem` brings in locallingo's shipped defaults (enabled state,
        include globs, `ScopedDirectories`); override any of it in your own file.
      MD
    end
  end

  def relative_i18n_key
    DocsUI::Section("Locallingo/RelativeI18nKey") do
      md <<~'MD'
        Flags relative lazy-lookup keys like `t(".title")` and — where the file
        path maps to a known convention — **autocorrects** them to the
        fully-qualified key derived from the path and enclosing method. Relative
        keys silently break when a translation moves file, an action is renamed, or
        a string is reused; fully-qualified keys are explicit and grep-able.
      MD
      DocsUI::Code(<<~'RUBY', filename: "before / after")
        # bad
        t(".title")

        # good (autocorrected in app/views/users/index.rb)
        t("users.index.title")
      RUBY
      md <<~'MD'
        Configure which directories map to a lazy-lookup scope with
        `ScopedDirectories` — defaults to controllers, mailers, views, components,
        models, services, jobs, notifiers.
      MD
    end
  end

  def strftime_in_view
    DocsUI::Section("Locallingo/StrftimeInView") do
      md <<~'MD'
        Flags `.strftime(...)` in view files — hardcoded date formats bypass
        locale-aware formatting. Use `I18n.l(value, format: :name)` with named
        formats in `config/locales/{date,time}.*.yml` instead. `.strftime` inside a
        `value:` pair (an HTML `datetime-local` input, which must follow the HTML
        spec) is exempt.
      MD
      DocsUI::Code(<<~'RUBY', filename: "before / after")
        # bad
        created_at.strftime("%B %d, %Y")

        # good
        I18n.l(created_at, format: :long)
      RUBY
    end
  end

  def rails_cops
    DocsUI::Section("Recommended: disable the Rails defaults") do
      md <<~'MD'
        Rails ships cops that push keys the *other* way — toward relative lazy
        lookup. Disable them so they don't fight `Locallingo/RelativeI18nKey`:
      MD
      DocsUI::Code(<<~'YAML', filename: ".rubocop.yml")
        Rails/I18nLazyLookup:
          Enabled: false
        Rails/I18nLocaleTexts:
          Enabled: false
      YAML
    end
  end
end
