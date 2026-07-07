# frozen_string_literal: true

module RuboCop
  module Cop
    module Locallingo
      # Enforces fully-qualified i18n keys instead of relative keys.
      #
      # Relative keys (e.g. `t(".notice")`) depend on Rails' lazy lookup, which is
      # implicit and fragile: moving a translation between files, renaming an
      # action, or reusing a string in a different context all silently break the
      # lookup. Fully qualified keys are explicit and grep-able.
      #
      # The autocorrector mirrors Rails' lazy-lookup scope, deriving the prefix
      # from the file path (mapped through `ScopedDirectories`) plus the enclosing
      # method name. When the path does not map to a known convention it flags the
      # offense but leaves qualification to the developer rather than guessing.
      #
      # The set of scoped directories is configurable so the cop fits apps with
      # different layouts:
      #
      #   Locallingo/RelativeI18nKey:
      #     ScopedDirectories: [controllers, mailers, views, components]
      #
      # @example
      #   # bad
      #   t(".title")
      #   t(".nested.key")
      #
      #   # good
      #   t("users.index.title")
      #   t("users.show.nested.key")
      class RelativeI18nKey < Base
        extend AutoCorrector

        MSG = "Use fully-qualified i18n key instead of relative key `%<key>s`."

        DEFAULT_SCOPED_DIRECTORIES = %w[
          controllers mailers views components models services jobs notifiers
        ].freeze

        # @!method t_with_string_arg?(node)
        def_node_matcher :t_with_string_arg?, <<~PATTERN
          (send nil? :t (str $_) ...)
        PATTERN

        def on_send(node)
          t_with_string_arg?(node) do |key|
            next unless key.start_with?(".")

            add_offense(node, message: format(MSG, key:)) do |corrector|
              qualified = qualify(node, key)
              next unless qualified

              corrector.replace(node.first_argument, "\"#{qualified}\"")
            end
          end
        end

        private

        def scoped_directories
          Array(cop_config["ScopedDirectories"]).then do |configured|
            configured.empty? ? DEFAULT_SCOPED_DIRECTORIES : configured
          end
        end

        def qualify(node, relative_key)
          scope = lazy_lookup_scope(node)
          return nil unless scope

          "#{scope}#{relative_key}"
        end

        # Mirrors Rails' lazy-lookup scope. Returns nil if the path does not map
        # to a known convention (we'd rather flag and require manual
        # qualification than guess wrong).
        def lazy_lookup_scope(node)
          path = processed_source.file_path
          return nil if path.nil?

          rel = path.sub(%r{\A.*?app/}, "")
          dir = rel.split("/").first
          return nil unless scoped_directories.include?(dir)

          file_scope = rel.sub(%r{\A[^/]+/}, "").delete_suffix(".rb")
          file_scope = file_scope.delete_suffix("_controller").delete_suffix("_mailer")
          base = file_scope.tr("/", ".")

          method_name = enclosing_method(node)
          method_name ? "#{base}.#{method_name}" : base
        end

        def enclosing_method(node)
          node.each_ancestor(:def).first&.method_name&.to_s
        end
      end
    end
  end
end
