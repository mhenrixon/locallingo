# frozen_string_literal: true

module Locallingo
  module Validators
    # Reports keys present in the source locale but absent from a target locale.
    class Missing
      def initialize(cli_name: "lingo")
        @cli_name = cli_name
      end

      # +source+ and +target+ are flat key=>value hashes for one target +locale+.
      def call(source:, target:, locale:)
        (source.keys - target.keys).map do |key|
          {
            type: :missing,
            locale:,
            key:,
            suggestion: "Run: #{@cli_name} translate --locale #{locale}"
          }
        end
      end
    end
  end
end
