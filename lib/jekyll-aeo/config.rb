# frozen_string_literal: true

module JekyllAeo
  module Config
    DEFAULTS = {
      "enabled" => true,
      "md_path_style" => "clean",
      "strip_block_tags" => true,
      "protect_indented_code" => false,
      "link_tag" => "auto",
      "exclude" => [],
      "include" => [],
      "html_fallback" => false,
      "llms_txt" => {
        "enabled" => true,
        "description" => nil,
        "full_txt_mode" => "all",
        "sections" => nil,
        "front_matter_keys" => [],
        "show_lastmod" => false
      },
      "url_map" => {
        "enabled" => false,
        "output_filepath" => "docs/Url-Map.md",
        "columns" => %w[page_id url lang layout path redirects markdown_copy skipped]
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
