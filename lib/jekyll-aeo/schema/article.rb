# frozen_string_literal: true

module JekyllAeo
  module Schema
    module Article
      def self.build(page, site_config)
        return nil unless page["date"]
        return nil if seo_tag_present?

        base_url = site_config["url"].to_s.chomp("/")
        baseurl = site_config["baseurl"].to_s.chomp("/")

        schema = {
          "@context" => "https://schema.org",
          "@type" => "Article",
          "headline" => page["title"] || "",
          "url" => "#{base_url}#{baseurl}#{page['url']}",
          "datePublished" => format_date(page["date"])
        }

        description = page["description"] || page["excerpt"]
        schema["description"] = description.to_s if description

        author = page["author"]
        if author
          schema["author"] = {
            "@type" => "Person",
            "name" => author
          }
        end

        lm = page["last_modified_at"]
        schema["dateModified"] = format_date(lm) if lm

        schema
      end

      def self.seo_tag_present?
        !Liquid::Template.tags["seo"].nil?
      rescue StandardError
        false
      end

      def self.format_date(value)
        case value
        when Time, DateTime
          value.iso8601
        else
          value.to_s
        end
      end

      private_class_method :seo_tag_present?, :format_date
    end
  end
end
