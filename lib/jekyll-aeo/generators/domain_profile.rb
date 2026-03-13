# frozen_string_literal: true

require "json"
require "fileutils"

module JekyllAeo
  module Generators
    module DomainProfile
      SPEC_URL = "https://ai-domain-data.org/spec/v0.1"

      VALID_ENTITY_TYPES = %w[
        Organization Person Blog NGO Community
        Project CreativeWork SoftwareApplication Thing
      ].freeze

      def self.generate(site)
        config = JekyllAeo::Config.from_site(site)
        return if config["enabled"] == false

        dp_config = config["domain_profile"] || {}
        return if dp_config["enabled"] == false

        profile = build_profile(dp_config, site)
        return unless profile

        output_path = File.join(site.dest, ".well-known", "domain-profile.json")
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, "#{JSON.pretty_generate(profile)}\n")
      end

      def self.build_profile(dp_config, site)
        name = dp_config["name"] || site.config["title"] || site.config["name"]
        description = dp_config["description"] || site.config["description"]
        website = dp_config["website"] || site.config["url"]
        contact = dp_config["contact"]

        unless contact
          Jekyll.logger.warn "AEO Domain Profile:", "Skipped — 'contact' is required but not set"
          return nil
        end

        profile = {
          "spec" => SPEC_URL,
          "name" => name.to_s,
          "description" => description.to_s,
          "website" => website.to_s,
          "contact" => contact.to_s
        }

        add_optional_fields(profile, dp_config)
        profile
      end

      def self.add_optional_fields(profile, dp_config)
        entity_type = dp_config["entity_type"]
        if entity_type
          if VALID_ENTITY_TYPES.include?(entity_type)
            profile["entity_type"] = entity_type
          else
            Jekyll.logger.warn "AEO Domain Profile:",
                               "Invalid entity_type '#{entity_type}' — ignored. " \
                               "Valid: #{VALID_ENTITY_TYPES.join(', ')}"
          end
        end
        profile["logo"] = dp_config["logo"] if dp_config["logo"]
        jsonld = dp_config["jsonld"]
        profile["jsonld"] = jsonld if jsonld.is_a?(Hash)
      end

      private_class_method :build_profile, :add_optional_fields
    end
  end
end
