# frozen_string_literal: true

module Locallingo
  # Converts between nested locale hashes (as loaded from YAML) and the flat
  # dotted-key representation the engine works in, and back.
  #
  # Flat keys use dot notation with bracket indices for arrays, e.g.
  # `items[0].name`. This is a faithful extraction of the algorithms that lived
  # in TranslationManager (flatten_hash / parse_key_segments / set_nested_value /
  # navigate_or_create) so the round-trip behavior is byte-identical.
  module KeyFlattener
    module_function

    # Flatten a nested hash to `{ "a.b.c" => "value" }`. Arrays are indexed with
    # bracket notation. Only leaf values are kept; the caller decides which types
    # to retain.
    def flatten(hash, prefix = "")
      result = {}
      hash.each do |key, value|
        full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        case value
        when Hash
          result.merge!(flatten(value, full_key))
        when Array
          value.each_with_index do |item, i|
            if item.is_a?(String)
              result["#{full_key}[#{i}]"] = item
            elsif item.is_a?(Hash)
              result.merge!(flatten(item, "#{full_key}[#{i}]"))
            end
          end
        else
          result[full_key] = value
        end
      end
      result
    end

    # Set a flattened +key+ to +value+ inside the nested +hash+, creating
    # intermediate hashes/arrays as needed.
    def set_nested_value(hash, key, value)
      segments = parse_key_segments(key)
      current = hash

      segments[0..-2].each do |segment|
        current = navigate_or_create(current, segment)
      end

      final_segment = segments.last
      if final_segment[:index]
        current[final_segment[:key]] ||= []
        current[final_segment[:key]][final_segment[:index]] = value
      else
        current[final_segment[:key]] = value
      end
    end

    # Parse a flattened key into segments, handling both dot notation and bracket
    # indices.
    #   "items[0].name" => [{key: "items", index: 0}, {key: "name", index: nil}]
    #   "matrix[0][1]"  => [{key: "matrix", index: 0}, {key: nil, index: 1}]
    def parse_key_segments(key)
      segments = []
      parts = key.split(".")

      parts.each do |part|
        if part =~ /^([^\[]*)\[(\d+)\](.*)$/
          base_key = ::Regexp.last_match(1)
          index = ::Regexp.last_match(2).to_i
          remainder = ::Regexp.last_match(3)

          segments << if base_key.empty?
                        { key: nil, index: }
                      else
                        { key: base_key, index: }
                      end

          while remainder =~ /^\[(\d+)\](.*)$/
            segments << { key: nil, index: ::Regexp.last_match(1).to_i }
            remainder = ::Regexp.last_match(2)
          end
        else
          segments << { key: part, index: nil }
        end
      end

      segments
    end

    # Navigate to or create the appropriate container (hash or array) for a
    # segment.
    def navigate_or_create(current, segment)
      if segment[:index]
        if segment[:key]
          current[segment[:key]] ||= []
          ensure_array_size(current[segment[:key]], segment[:index])
          current[segment[:key]][segment[:index]] ||= {}
          current[segment[:key]][segment[:index]]
        else
          ensure_array_size(current, segment[:index])
          current[segment[:index]] ||= {}
          current[segment[:index]]
        end
      else
        current[segment[:key]] ||= {}
        current[segment[:key]]
      end
    end

    def ensure_array_size(array, index)
      array << nil while array.size <= index
    end
  end
end
