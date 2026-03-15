# frozen_string_literal: true

require "reverse_markdown"
require "nokogiri"

module JekyllAeo
  module Utils
    module HtmlConverter
      STRIP_ELEMENTS = %w[script style nav header footer].freeze

      def self.convert(html, config = {})
        return "" if html.nil? || html.strip.empty?

        doc = Nokogiri::HTML(html)
        content_node = extract_content(doc, config)
        return "" unless content_node

        STRIP_ELEMENTS.each { |tag| content_node.css(tag).each(&:remove) }
        promote_code_languages(content_node)

        ReverseMarkdown.convert(content_node.inner_html, unknown_tags: :bypass, github_flavored: true).strip
      end

      def self.extract_content(doc, config)
        selector = config["selector"]
        if selector
          doc.at_css(selector)
        else
          doc.at_css("main") || doc.at_css("article") || doc.at_css("body")
        end
      end

      # Jekyll/Rouge: <div class="language-python"><div class="highlight"><pre>…
      # ReverseMarkdown: reads `highlight-{lang}` from <pre>'s parent
      def self.promote_code_languages(node)
        node.css('div[class*="language-"]').each do |div|
          next unless div["class"] =~ /language-(\S+)/

          pre = div.at_css("pre")
          pre.parent["class"] = "highlight-#{Regexp.last_match(1)}" if pre&.parent
        end
      end

      private_class_method :extract_content, :promote_code_languages
    end
  end
end
