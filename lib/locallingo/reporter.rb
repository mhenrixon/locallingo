# frozen_string_literal: true

require "json"

module Locallingo
  # Renders status/violation/quality output for the CLI (text + JSON) and
  # computes strict exit codes. Extracted from the original bin/translate
  # printers so the CLI stays thin.
  class Reporter
    SEVERITY_ICONS = { error: "🔴", warning: "🟡", info: "🔵" }.freeze
    TYPE_ICONS = {
      missing: "❌", outdated: "🔄", duplicate_value: "🔁", manual_edit: "✏️"
    }.freeze

    def initialize(config:, format: :text, io: $stdout, cli_name: "lingo")
      @config = config
      @format = format
      @io = io
      @cli_name = cli_name
    end

    def status(status)
      return json(status) if json?

      puts "\n📊 Translation Status"
      puts "=" * 60
      status.each { |locale, info| print_locale_status(locale, info) }
      puts ""
    end

    # Prints violations and returns the strict exit code.
    def violations(violations, strict: false, strict_all: false)
      if json?
        json(violations)
        return exit_code(violations, strict:, strict_all:)
      end

      if violations.empty?
        puts "\n✅ All translations valid!"
        return 0
      end

      puts "\n❌ Translation Issues Found"
      puts "=" * 60
      violations.group_by { |v| v[:type] }.each { |type, items| print_violation_group(type, items) }
      puts "\nTotal: #{violations.size} issues"

      exit_code(violations, strict:, strict_all:)
    end

    def quality(suggestions, locale:)
      return json(suggestions) if json?

      if suggestions.empty?
        puts "\n✅ No quality issues found!"
        return
      end

      puts "\n📝 Translation Quality Suggestions"
      puts "=" * 60
      print_quality_by_severity(suggestions)
      print_quality_summary(suggestions, locale)
    end

    # Exit code for a strict tier, per the configured strict_types.
    def exit_code(violations, strict:, strict_all:)
      return 0 unless strict || strict_all

      tier = strict_all ? :strict_all : :strict
      error_types = @config.strict_types(tier)
      violations.any? { |v| error_types.include?(v[:type]) } ? 1 : 0
    end

    private

    def json? = @format == :json
    def puts(str = "") = @io.puts(str)

    def json(data)
      @io.puts(JSON.pretty_generate(data))
    end

    def print_locale_status(locale, info)
      icon = info[:missing].zero? && info[:outdated].zero? ? "✅" : "⚠️"
      puts "\n#{icon} #{locale}"
      puts "   Total keys: #{info[:total_keys]}"
      puts "   Translated: #{info[:translated]}"
      puts "   Missing: #{info[:missing]}"
      puts "   Outdated: #{info[:outdated]}"
      print_key_list("Missing (first 10):", info[:missing_keys])
      print_key_list("Outdated (first 10):", info[:outdated_keys])
    end

    def print_key_list(label, keys)
      return unless keys&.any?

      puts "   #{label}"
      keys.each { |k| puts "     - #{k}" }
    end

    def print_violation_group(type, items)
      puts "\n#{TYPE_ICONS.fetch(type, "❓")} #{type.to_s.tr("_", " ").capitalize} (#{items.size})"
      items.first(10).each do |v|
        puts "   #{v[:locale]}: #{v[:key]}"
        puts "      → #{v[:suggestion]}"
      end
      puts "   ... and #{items.size - 10} more" if items.size > 10
    end

    def print_quality_by_severity(suggestions)
      by_severity = suggestions.group_by { |s| s[:severity] }
      %i[error warning info].each do |severity|
        items = by_severity[severity] || []
        next if items.empty?

        fixable = items.count { |s| s[:fix] }
        note = fixable.positive? ? " (#{fixable} auto-fixable)" : ""
        puts "\n#{SEVERITY_ICONS[severity]} #{severity.to_s.capitalize} (#{items.size})#{note}"
        items.first(20).each { |s| print_quality_item(s) }
        puts "   ... and #{items.size - 20} more" if items.size > 20
      end
    end

    def print_quality_item(suggestion)
      puts "   #{suggestion[:key]}"
      puts "      Text: #{truncate(suggestion[:text].to_s, 60)}"
      puts "      Issue: #{suggestion[:issue]}"
      puts "      Fix: Replace '#{suggestion[:fix][:from]}' → '#{suggestion[:fix][:to]}'" if suggestion[:fix]
      puts ""
    end

    def print_quality_summary(suggestions, locale)
      fixable = suggestions.count { |s| s[:fix] }
      puts "\n#{"-" * 60}"
      puts "Summary: #{suggestions.size} issues found"
      if fixable.positive?
        puts "\nTo auto-fix #{fixable} issues, run:"
        puts "  #{@cli_name} fix-quality --locale #{locale}"
      end
      puts ""
    end

    def truncate(text, length)
      text.length > length ? "#{text[0, length]}..." : text
    end
  end
end
