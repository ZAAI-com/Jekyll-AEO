# frozen_string_literal: true

module JekyllAeo
  module Utils
    module ContentStripper
      FENCE_OPEN = /^(\s{0,3})((`{3,})|(~{3,}))/
      LIQUID_RAW_ENDRAW = /\{%-?\s*raw\s*-?%\}(.*?)\{%-?\s*endraw\s*-?%\}/
      LIQUID_RAW_OPEN = /\{%-?\s*raw\s*-?%\}/
      LIQUID_RAW_CLOSE = /\{%-?\s*endraw\s*-?%\}/
      LIQUID_COMMENT_OPEN = /\{%-?\s*comment\s*-?%\}/
      LIQUID_COMMENT_CLOSE = /\{%-?\s*endcomment\s*-?%\}/
      LIQUID_CAPTURE_OPEN = /\{%-?\s*capture\s+\w+\s*-?%\}/
      LIQUID_CAPTURE_CLOSE = /\{%-?\s*endcapture\s*-?%\}/
      LIQUID_BLOCK_TAG = /\{%-?.*?-?%\}/
      LIQUID_OUTPUT_TAG = /\{\{-?.*?-?\}\}/
      KRAMDOWN_IAL = /\s*\{:.*?\}/

      def self.strip(content, config = {})
        return "" if content.nil? || content.strip.empty?

        strip_block_tags = config.fetch("strip_block_tags", true)
        protect_indented = config.fetch("protect_indented_code", false)

        lines = content.lines
        state = :normal
        fence_close_pattern = nil
        silent_close_pattern = nil
        prev_blank = false

        result_lines = []

        lines.each do |line|
          case state
          when :in_fence
            result_lines << line
            if line.rstrip =~ fence_close_pattern
              state = :normal
              fence_close_pattern = nil
            end

          when :in_raw
            if line =~ LIQUID_RAW_CLOSE
              result_lines << line.sub(LIQUID_RAW_CLOSE, "")
              state = :normal
            else
              result_lines << line
            end

          when :in_silent_block
            if line =~ silent_close_pattern
              state = :normal
              silent_close_pattern = nil
            end
            # discard all lines (including closing tag)

          when :in_indented_code
            if line =~ /\A\s*\n?\z/ || line =~ /\A {4,}/
              result_lines << line
            else
              state = :normal
              prev_blank = false
              result_lines << strip_line(line)
            end

          when :normal
            # Check for fenced code block opening
            if (match = line.match(FENCE_OPEN))
              state = :in_fence
              char = match[3] ? "`" : "~"
              count = (match[3] || match[4]).length
              fence_close_pattern = /\A\s{0,3}#{Regexp.escape(char)}{#{count},}\s*\z/
              result_lines << line

            # Check for {% raw %} opening
            elsif line =~ LIQUID_RAW_OPEN
              if line =~ LIQUID_RAW_ENDRAW
                # Single-line raw/endraw: strip both tags, keep inner content verbatim
                result_lines << line.gsub(LIQUID_RAW_ENDRAW, '\1')
              else
                state = :in_raw
                result_lines << line.sub(LIQUID_RAW_OPEN, "")
              end

            # Check for silent block opening (comment/capture) when strip_block_tags enabled
            elsif strip_block_tags && line =~ LIQUID_COMMENT_OPEN
              state = :in_silent_block
              silent_close_pattern = LIQUID_COMMENT_CLOSE

            elsif strip_block_tags && line =~ LIQUID_CAPTURE_OPEN
              state = :in_silent_block
              silent_close_pattern = LIQUID_CAPTURE_CLOSE

            # Check for indented code block
            elsif protect_indented && prev_blank && line =~ /\A {4,}/
              state = :in_indented_code
              result_lines << line

            else
              result_lines << strip_line(line)
            end

            prev_blank = line =~ /\A\s*\n?\z/
          end
        end

        result_lines.join
      end

      def self.strip_line(line)
        stripped = line
        stripped = stripped.gsub(LIQUID_BLOCK_TAG, "")
        stripped = stripped.gsub(LIQUID_OUTPUT_TAG, "")
        stripped.gsub(KRAMDOWN_IAL, "")
      end

      private_class_method :strip_line
    end
  end
end
