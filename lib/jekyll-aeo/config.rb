# frozen_string_literal: true

module JekyllAeo
  module Config
    DEFAULTS = {
      "enabled" => true,
      "exclude" => [],
      "dotmd" => {
        "link_tag" => "auto",
        "include_last_modified" => true,
        "dotmd_metadata" => false,
        "md2dotmd" => {
          "strip_block_tags" => true,
          "protect_indented_code" => false
        },
        "html2dotmd" => {
          "enabled" => false,
          "selector" => nil
        }
      },
      "llms_txt" => {
        "enabled" => true,
        "description" => nil,
        "sections" => nil,
        "front_matter_keys" => [],
        "show_lastmod" => false,
        "include_descriptions" => true
      },
      "llms_full_txt" => {
        "enabled" => true,
        "description" => nil,
        "full_txt_mode" => "all"
      },
      "url_map" => {
        "enabled" => false,
        "output_filepath" => "docs/Url-Map.md",
        "columns" => %w[layout url url_dotmd dotmd_mode skipped path page_id lang redirects],
        "show_created_at" => true
      },
      "robots_txt" => {
        "enabled" => false,
        "allow" => %w[Googlebot Bingbot OAI-SearchBot ChatGPT-User Claude-SearchBot
                      Claude-User PerplexityBot Applebot-Extended],
        "disallow" => %w[GPTBot ClaudeBot Google-Extended Meta-ExternalAgent Amazonbot],
        "include_sitemap" => true,
        "include_llms_txt" => true,
        "custom_rules" => []
      },
      "domain_profile" => {
        "enabled" => false,
        "name" => nil,
        "description" => nil,
        "website" => nil,
        "contact" => nil,
        "logo" => nil,
        "entity_type" => nil,
        "jsonld" => nil
      }
    }.freeze

    def self.from_site(site)
      user_config = site.config["jekyll_aeo"] || {}
      deep_merge(DEFAULTS, user_config)
    end

    # Strict-schema merge: iterates only over keys defined in +defaults+,
    # intentionally dropping any user-supplied keys that are not part of
    # the known schema.  This prevents typos from silently propagating and
    # keeps the config surface predictable for downstream consumers.
    def self.deep_merge(defaults, overrides)
      defaults.each_with_object({}) do |(key, default_val), result|
        override_val = overrides[key]

        result[key] = if default_val.is_a?(Hash) && override_val.is_a?(Hash)
                        deep_merge(default_val, override_val)
                      elsif overrides.key?(key)
                        override_val
                      else
                        default_val
                      end
      end
    end

    private_class_method :deep_merge
  end
end
