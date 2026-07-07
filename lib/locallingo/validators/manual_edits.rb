# frozen_string_literal: true

require_relative "../state_store"

module Locallingo
  module Validators
    # Detects target values that were hand-edited after Locallingo wrote them.
    #
    # When enabled, the Manager records a `target_hash` alongside `source_hash`
    # for each translated key. If the current target value's hash differs from
    # the recorded `target_hash` (and the key is not already flagged `manual`),
    # it was edited by a human — surface it so the operator can protect it with
    # `accept-edits` before the next translate run overwrites it.
    class ManualEdits
      def initialize(cli_name: "lingo")
        @cli_name = cli_name
      end

      # +target+ is the flat target hash; +locale_state+ its loaded state.
      def call(target:, locale_state:, locale:)
        target.filter_map do |key, value|
          entry = locale_state[key]
          next unless entry.is_a?(Hash)
          next if entry["manual"]

          stored = entry["target_hash"]
          next unless stored && stored != StateStore.hash(value)

          {
            type: :manual_edit,
            locale:,
            key:,
            suggestion: "Value was hand-edited. Protect it: #{@cli_name} accept-edits --locale #{locale}"
          }
        end
      end
    end
  end
end
