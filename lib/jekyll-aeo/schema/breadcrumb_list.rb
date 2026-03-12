# frozen_string_literal: true

module JekyllAeo
  module Schema
    module BreadcrumbList
      def self.build(page, site_config)
        url = page["url"]
        return nil if url.nil? || url == "/"

        base_url = site_config["url"].to_s.chomp("/")
        baseurl = site_config["baseurl"].to_s.chomp("/")

        segments = url.split("/").reject(&:empty?)
        return nil if segments.empty?

        items = []
        items << {
          "@type" => "ListItem",
          "position" => 1,
          "name" => "Home",
          "item" => "#{base_url}#{baseurl}/"
        }

        accumulated = ""
        segments.each_with_index do |segment, index|
          accumulated += "/#{segment}"
          name = if page["title"] && index == segments.length - 1
                   page["title"]
                 else
                   segment.split(/[_-]/).map(&:capitalize).join(" ")
                 end
          items << {
            "@type" => "ListItem",
            "position" => index + 2,
            "name" => name,
            "item" => "#{base_url}#{baseurl}#{accumulated}/"
          }
        end

        {
          "@context" => "https://schema.org",
          "@type" => "BreadcrumbList",
          "itemListElement" => items
        }
      end
    end
  end
end
