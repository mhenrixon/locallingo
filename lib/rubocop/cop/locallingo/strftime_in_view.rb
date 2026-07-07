# frozen_string_literal: true

module RuboCop
  module Cop
    module Locallingo
      # Enforces `I18n.l(value, format: :name)` instead of `.strftime(...)` in
      # view files.
      #
      # Hardcoded strftime patterns bypass locale-aware formatting. Use I18n.l
      # with named formats defined in config/locales/time.*.yml and date.*.yml.
      #
      # `.strftime` inside a `value:` pair is exempt: HTML datetime-local input
      # values must follow the HTML spec, not locale display formatting.
      #
      # Scope with the standard RuboCop `Include`/`Exclude` in your config:
      #
      #   Locallingo/StrftimeInView:
      #     Include: [app/views/**/*.rb]
      #     Exclude: [app/views/**/*_mailer/**/*.rb]
      #
      # @example
      #   # bad
      #   @user.created_at.strftime("%B %d, %Y")
      #
      #   # good
      #   I18n.l(@user.created_at, format: :long)
      class StrftimeInView < Base
        MSG = "Use `I18n.l(value, format: :name)` instead of `.strftime(...)`. " \
              "Define formats in config/locales/{time,date}.*.yml."

        RESTRICT_ON_SEND = %i[strftime].freeze

        def on_send(node)
          return if in_html_input_context?(node)

          add_offense(node.loc.selector)
        end

        private

        # Allow strftime for HTML datetime-local input values, where the format
        # is dictated by the HTML spec, not user display.
        def in_html_input_context?(node)
          node.each_ancestor(:pair).any? do |pair|
            pair.key.value == :value if pair.key.respond_to?(:value)
          end
        end
      end
    end
  end
end
