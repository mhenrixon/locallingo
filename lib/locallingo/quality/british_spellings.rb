# frozen_string_literal: true

module Locallingo
  module Quality
    # American -> British spelling drift, applied to the source locale only.
    # Opt-in via `quality.british_spellings: true`. Ported from zazu/app.
    module BritishSpellings
      SPELLINGS = {
        "organization" => "organisation",
        "color" => "colour",
        "center" => "centre",
        "favor" => "favour",
        "honor" => "honour",
        "labor" => "labour",
        "analyze" => "analyse",
        "optimize" => "optimise",
        "recognize" => "recognise",
        "realize" => "realise",
        "apologize" => "apologise",
        "authorize" => "authorise",
        "personalize" => "personalise",
        "familiarize" => "familiarise"
      }.freeze

      module_function

      # Auto-fixable British-spelling suggestions for one key/text pair.
      def check(key, text, locale)
        SPELLINGS.filter_map do |american, british|
          next unless text.match?(/\b#{Regexp.escape(american)}\b/i)

          {
            key:, text:, locale:,
            category: :british_spelling,
            issue: "Use British spelling '#{british}' instead of '#{american}'",
            match: american,
            fix: { from: american, to: british },
            severity: :warning,
            source: :static
          }
        end
      end
    end
  end
end
