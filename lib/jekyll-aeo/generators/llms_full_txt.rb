# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module LlmsFullTxt
      def self.generate(site)
        config = JekyllAeo::Config.from_site(site)
        return if config["enabled"] == false

        full_config = config["llms_full_txt"] || {}
        return if full_config["enabled"] == false

        warn_deprecated_full_txt_mode(site)

        llms_config = config["llms_txt"] || {}
        eligible = LlmsTxt.collect_eligible(site, config)
        sections = LlmsTxt.build_sections(eligible, llms_config)

        content = build_content(site, sections, eligible, full_config)
        File.write(File.join(site.dest, "llms-full.txt"), content)
      end

      def self.build_content(site, sections, eligible, full_config)
        mode = full_config.fetch("full_txt_mode", "all")

        items_to_include = if mode == "linked"
                             sections.flat_map { |s| s[:items] }
                           else
                             eligible
                           end

        lines = []
        lines << "# #{site.config['title']}"
        lines << ""

        description = full_config["description"] || site.config["description"]
        if description && !description.to_s.empty?
          lines << "> #{description}"
          lines << ""
        end

        items_to_include.each do |item|
          lines << "---"
          lines << ""

          next unless File.exist?(item[:dest_md])

          content = File.read(item[:dest_md], encoding: "utf-8")
          lines << content.strip
          lines << ""
        end

        "#{lines.join("\n").rstrip}\n"
      end

      def self.warn_deprecated_full_txt_mode(site)
        user_config = site.config["jekyll_aeo"] || {}
        llms_txt_config = user_config["llms_txt"] || {}
        return unless llms_txt_config.key?("full_txt_mode")

        Jekyll.logger.warn "AEO:", "'llms_txt.full_txt_mode' has moved to 'llms_full_txt.full_txt_mode'"
      end

      private_class_method :build_content, :warn_deprecated_full_txt_mode
    end
  end
end
