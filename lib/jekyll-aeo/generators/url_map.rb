# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module UrlMap
      COLUMN_HEADERS = {
        "page_id" => "Page ID",
        "url" => "URL",
        "lang" => "Lang",
        "layout" => "Layout",
        "path" => "Path",
        "redirects" => "Redirects",
        "markdown_copy" => "Markdown Copy",
        "skipped" => "Skipped"
      }.freeze

      def self.generate(site)
        config = JekyllAeo::Config.from_site(site)
        return if config["enabled"] == false

        url_map_config = config["url_map"] || {}
        return if url_map_config["enabled"] == false

        columns = url_map_config["columns"] || COLUMN_HEADERS.keys
        items = collect_all_items(site, config, columns)
        sections = build_sections(items)
        markdown = build_markdown(sections, columns, config)

        output_file = File.join(site.source, url_map_config["output_filepath"] || "docs/Url-Map.md")
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, markdown)
      end

      def self.collect_all_items(site, config, columns)
        items = []
        needs_skip = columns.include?("skipped")
        needs_md = columns.include?("markdown_copy")

        site.documents.each do |doc|
          next unless doc.output_ext == ".html"
          next if doc.respond_to?(:collection) && doc.collection&.label == "assets"

          items << build_item(doc, doc.collection&.label, site, config, needs_skip, needs_md)
        end

        site.pages.each do |page|
          next unless page.output_ext == ".html"

          items << build_item(page, nil, site, config, needs_skip, needs_md)
        end

        items
      end

      def self.build_item(obj, collection_label, site, config, needs_skip, needs_md)
        redirect_from = obj.data["redirect_from"]
        redirects_str = case redirect_from
                        when Array then redirect_from.join(", ")
                        when String then redirect_from
                        else ""
                        end

        item = {
          url: obj.url,
          page_id: obj.data["page_id"] || "",
          lang: obj.data["lang"] || "",
          layout: obj.data["layout"] || "",
          path: obj.relative_path,
          redirects: redirects_str,
          collection: collection_label
        }

        item[:skipped] = JekyllAeo::Utils::SkipLogic.skip_reason(obj, site, config) || "" if needs_skip
        item[:markdown_copy] = md_url(obj.url, config) if needs_md && (!needs_skip || item[:skipped].empty?)
        item[:markdown_copy] ||= "" if needs_md

        item
      end

      def self.build_sections(items)
        grouped = items.group_by { |item| item[:collection] }
        sections = []

        if grouped.key?(nil)
          sections << { title: "Pages", items: grouped.delete(nil).sort_by { |i| i[:url] } }
        end

        sorted_keys = grouped.keys.compact.sort
        sorted_keys.each do |key|
          sections << { title: titleize(key), items: grouped[key].sort_by { |i| i[:url] } }
        end

        sections
      end

      def self.build_markdown(sections, columns, _config)
        lines = []
        lines << "# URL Map"
        lines << ""

        sections.each do |section|
          next if section[:items].empty?

          lines << "## #{section[:title]}"
          lines << ""
          lines << table_header(columns)
          lines << table_separator(columns)

          section[:items].each do |item|
            lines << table_row(item, columns)
          end

          lines << ""
        end

        lines.join("\n").rstrip + "\n"
      end

      def self.table_header(columns)
        cells = columns.map { |col| COLUMN_HEADERS[col] || col }
        "| #{cells.join(' | ')} |"
      end

      def self.table_separator(columns)
        cells = columns.map { |col| "-" * (COLUMN_HEADERS[col] || col).length }
        "| #{cells.join(' | ')} |"
      end

      def self.table_row(item, columns)
        cells = columns.map { |col| escape_pipe(item[col.to_sym].to_s) }
        "| #{cells.join(' | ')} |"
      end

      def self.escape_pipe(value)
        value.gsub("|", "\\|")
      end

      def self.md_url(url, config)
        if config["md_path_style"] == "spec"
          url.end_with?("/") ? "#{url}index.html.md" : "#{url}.md"
        elsif url == "/"
          "/index.md"
        elsif url.end_with?("/")
          url.sub(%r{/\z}, ".md")
        else
          "#{url}.md"
        end
      end

      def self.titleize(label)
        case label
        when "posts"
          "Posts"
        else
          label.split(/[_-]/).map(&:capitalize).join(" ")
        end
      end

      private_class_method :collect_all_items, :build_item, :build_sections,
                           :build_markdown, :table_header, :table_separator,
                           :table_row, :escape_pipe, :md_url, :titleize
    end
  end
end
