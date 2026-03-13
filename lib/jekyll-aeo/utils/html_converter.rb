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

        ReverseMarkdown.convert(content_node.inner_html, unknown_tags: :bypass).strip
      end

      def self.extract_content(doc, config)
        selector = config["html_fallback_selector"]
        if selector
          doc.at_css(selector)
        else
          doc.at_css("main") || doc.at_css("article") || doc.at_css("body")
        end
      end

      private_class_method :extract_content
    end
  end
end
