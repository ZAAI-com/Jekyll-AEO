# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module LlmsTxt
      def self.generate(site)
        config = JekyllAeo::Config.from_site(site)
        return if config["enabled"] == false

        llms_config = config["llms_txt"] || {}
        return if llms_config["enabled"] == false

        eligible = collect_eligible(site, config)
        sections = build_sections(eligible, llms_config)

        llms_txt = build_llms_txt(site, sections, llms_config)
        File.write(File.join(site.dest, "llms.txt"), llms_txt)

        llms_full = build_llms_full_txt(site, sections, eligible, llms_config)
        File.write(File.join(site.dest, "llms-full.txt"), llms_full)
      end

      def self.collect_eligible(site, config)
        items = []

        site.documents.each do |doc|
          next if JekyllAeo::Utils::SkipLogic.skip?(doc, site, config)

          items << {
            obj: doc,
            title: doc.data["title"] || "",
            description: doc.data["description"] || "",
            url: doc.url,
            collection: doc.collection&.label,
            dest_md: md_dest_path(doc, site)
          }
        end

        site.pages.each do |page|
          next if JekyllAeo::Utils::SkipLogic.skip?(page, site, config)

          items << {
            obj: page,
            title: page.data["title"] || "",
            description: page.data["description"] || "",
            url: page.url,
            collection: nil,
            dest_md: md_dest_path(page, site)
          }
        end

        items
      end

      def self.build_sections(eligible, llms_config)
        custom_sections = llms_config["sections"]

        if custom_sections
          build_custom_sections(eligible, custom_sections)
        else
          build_auto_sections(eligible)
        end
      end

      def self.build_custom_sections(eligible, section_defs)
        section_defs.map do |section_def|
          title = section_def["title"]
          collection = section_def["collection"]

          items = eligible.select do |item|
            if collection.nil?
              item[:collection].nil?
            else
              item[:collection] == collection
            end
          end

          { title: title, items: items }
        end
      end

      def self.build_auto_sections(eligible)
        grouped = eligible.group_by { |item| item[:collection] }
        sections = []

        # Standalone pages first
        sections << { title: "Pages", items: grouped.delete(nil) } if grouped.key?(nil)

        # Collections alphabetically, "Optional" last
        sorted_keys = grouped.keys.compact.sort_by do |key|
          key == "optional" ? "zzz" : key
        end

        sorted_keys.each do |key|
          sections << { title: titleize(key), items: grouped[key] }
        end

        sections
      end

      def self.titleize(label)
        case label
        when "posts"
          "Blog Posts"
        else
          label.split(/[_-]/).map(&:capitalize).join(" ")
        end
      end

      def self.build_llms_txt(site, sections, llms_config)
        lines = []
        lines << "# #{site.config['title']}"
        lines << ""

        description = llms_config["description"] || site.config["description"]
        lines.push("> #{description}", "") if description && !description.to_s.empty?

        baseurl = site.config["baseurl"].to_s.chomp("/")
        lines << "- [llms-full.txt](#{baseurl}/llms-full.txt): Complete contents of all pages"
        lines << ""

        sections.each do |section|
          next if section[:items].empty?

          lines << "## #{section[:title]}"
          lines << ""

          section[:items].each do |item|
            url_md = md_url(item[:url], site.config["baseurl"])
            entry = "- [#{item[:title]}](#{url_md})"
            if llms_config["include_descriptions"] != false && !item[:description].empty?
              entry += ": #{item[:description]}"
            end
            lines << entry
          end

          lines << ""
        end

        "#{lines.join("\n").rstrip}\n"
      end

      def self.build_llms_full_txt(site, sections, eligible, llms_config)
        mode = llms_config.fetch("full_txt_mode", "all")

        items_to_include = if mode == "linked"
                             sections.flat_map { |s| s[:items] }
                           else
                             eligible
                           end

        lines = []
        lines << "# #{site.config['title']}"
        lines << ""

        description = site.config["description"]
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

      def self.md_dest_path(obj, site)
        JekyllAeo::Utils::MdUrl.dest_path(obj, site)
      end

      def self.md_url(url, baseurl = "")
        JekyllAeo::Utils::MdUrl.for(url, baseurl)
      end

      private_class_method :collect_eligible, :build_sections, :build_custom_sections,
                           :build_auto_sections, :titleize, :build_llms_txt,
                           :build_llms_full_txt, :md_dest_path, :md_url
    end
  end
end
