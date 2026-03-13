# frozen_string_literal: true

module JekyllAeo
  module Schema
    module Speakable
      def self.build(page, site_config, _aeo_config = {})
        return nil unless page["speakable"] == true

        base_url = site_config["url"].to_s.chomp("/")
        baseurl = site_config["baseurl"].to_s.chomp("/")
        url = "#{base_url}#{baseurl}#{page['url']}"

        selectors = [
          ".post-title, .page-title, h1",
          ".post-content p:first-of-type, .page-content p:first-of-type"
        ]

        {
          "@context" => "https://schema.org",
          "@type" => "WebPage",
          "name" => page["title"] || "",
          "url" => url,
          "speakable" => {
            "@type" => "SpeakableSpecification",
            "cssSelector" => selectors
          }
        }
      end
    end
  end
end
