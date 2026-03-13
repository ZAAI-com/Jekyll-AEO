# frozen_string_literal: true

module JekyllAeo
  module Schema
    module FaqPage
      def self.build(page, _site_config)
        faq = page["faq"]
        return nil unless faq.is_a?(Array) && faq.any?

        entities = faq.filter_map do |item|
          next unless item.is_a?(Hash) && item["q"] && item["a"]

          {
            "@type" => "Question",
            "name" => item["q"],
            "acceptedAnswer" => {
              "@type" => "Answer",
              "text" => item["a"]
            }
          }
        end

        return nil if entities.empty?

        {
          "@context" => "https://schema.org",
          "@type" => "FAQPage",
          "mainEntity" => entities
        }
      end
    end
  end
end
