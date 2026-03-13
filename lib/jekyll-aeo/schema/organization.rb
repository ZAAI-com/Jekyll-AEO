# frozen_string_literal: true

module JekyllAeo
  module Schema
    module Organization
      def self.build(page, site_config)
        return nil unless page["url"] == "/"

        name = site_config["title"] || site_config["name"]
        return nil unless name

        base_url = site_config["url"].to_s.chomp("/")

        schema = {
          "@context" => "https://schema.org",
          "@type" => "Organization",
          "name" => name,
          "url" => base_url.empty? ? "/" : base_url
        }

        description = site_config["description"]
        schema["description"] = description if description && !description.to_s.empty?

        logo = site_config.dig("jekyll_aeo", "domain_profile", "logo")
        schema["logo"] = logo if logo

        same_as = site_config.dig("jekyll_aeo", "domain_profile", "jsonld", "sameAs")
        schema["sameAs"] = same_as if same_as.is_a?(Array) && same_as.any?

        schema
      end
    end
  end
end
