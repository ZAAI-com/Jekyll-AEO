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

        llms_txt = build_llms_txt(site, sections, llms_config, config)
        File.write(File.join(site.dest, "llms.txt"), llms_txt)
      end

      def self.collect_eligible(site, config)
        items = []

        site.documents.each do |doc|
          next unless JekyllAeo::Utils::IncludeLogic.include?(doc, site, config)

          items << {
            obj: doc,
            title: title_for(doc),
            description: doc.data["description"] || "",
            url: doc.url,
            collection: doc.collection&.label,
            dest_md: md_dest_path(doc, site)
          }
        end

        site.pages.each do |page|
          next unless JekyllAeo::Utils::IncludeLogic.include?(page, site, config)

          items << {
            obj: page,
            title: title_for(page),
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

      def self.md_dest_path(obj, site)
        JekyllAeo::Utils::MdUrl.dest_path(obj, site)
      end

      def self.md_url(url, baseurl = "")
        JekyllAeo::Utils::MdUrl.for(url, baseurl)
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

      def self.title_for(obj)
        title = obj.data["title"]
        return title if title.is_a?(String) && !title.strip.empty?

        segment = obj.url.chomp("/").split("/").last
        return "Untitled" if segment.nil? || segment.empty?

        segment.split(/[_-]/).map(&:capitalize).join(" ")
      end

      def self.build_llms_txt(site, sections, llms_config, config)
        lines = []
        lines << "# #{site.config['title']}"
        lines << ""

        description = llms_config["description"] || site.config["description"]
        lines.push("> #{description}", "") if description && !description.to_s.empty?

        append_full_txt_link(lines, site, config)
        append_sections(lines, sections, llms_config, site)

        "#{lines.join("\n").rstrip}\n"
      end

      def self.append_full_txt_link(lines, site, config)
        full_txt_config = config["llms_full_txt"] || {}
        return if full_txt_config["enabled"] == false

        baseurl = site.config["baseurl"].to_s.chomp("/")
        lines << "- [llms-full.txt](#{baseurl}/llms-full.txt): Complete contents of all pages"
        lines << ""
      end

      def self.append_sections(lines, sections, llms_config, site)
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
      end

      private_class_method :build_custom_sections, :build_auto_sections,
                           :titleize, :title_for, :build_llms_txt,
                           :append_full_txt_link, :append_sections
    end
  end
end
