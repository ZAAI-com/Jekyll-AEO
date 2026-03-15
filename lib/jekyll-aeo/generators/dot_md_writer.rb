# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module DotMdWriter
      YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
      LIQUID_PATTERN = /\{[{%]/

      def self.process(obj, site)
        config = JekyllAeo::Config.from_site(site)
        dotmd_config = config["dotmd"]
        source_path = JekyllAeo::Utils::SkipLogic.resolve_source_path(obj, site)
        return if JekyllAeo::Utils::SkipLogic.skip?(obj, site, config)

        dest_path = md_dest_path(obj, site)
        body, dotmd_mode = extract_body(source_path, obj, dotmd_config)
        obj.data["aeo_dotmd_mode"] = dotmd_mode
        return if body.nil?

        if dotmd_config["include_last_modified"] && File.exist?(source_path)
          last_modified = resolve_last_modified(obj, source_path)
        end

        if dotmd_config["dotmd_metadata"]
          metadata = build_metadata_block(obj, site, config, last_modified)
          header = build_header(obj, body, config, last_modified: nil)
          result = metadata + header + body.lstrip
        else
          header = build_header(obj, body, config, last_modified: last_modified)
          result = header + body.lstrip
        end

        result = result.gsub(/\n{3,}/, "\n\n")
        result = "#{result.rstrip}\n"

        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, result)

        root_index = File.basename(dest_path) == "index.md" && File.dirname(dest_path) == site.dest
        File.write(File.join(site.dest, "index.html.md"), result) if root_index
      end

      def self.extract_body(source_path, obj, dotmd_config)
        preferred = obj.data["dotmd_mode"]

        return extract_html2dotmd(obj, dotmd_config) if preferred == "html2dotmd"
        return extract_explicit_md2dotmd(source_path, obj) if preferred == "md2dotmd" && !File.exist?(source_path)

        if File.exist?(source_path)
          extract_from_source(source_path, obj, dotmd_config, preferred)
        else
          html2dotmd_result(obj.output, dotmd_config)
        end
      end

      def self.extract_html2dotmd(obj, dotmd_config)
        html_output = obj.respond_to?(:output) ? obj.output : nil
        return html2dotmd_result(html_output, dotmd_config) if html_output && !html_output.strip.empty?

        Jekyll.logger.warn "Jekyll-AEO:",
                           "dotmd_mode: html2dotmd set but no rendered output for #{obj.url}"
        [nil, "html2dotmd"]
      end

      def self.extract_explicit_md2dotmd(_source_path, obj)
        Jekyll.logger.warn "Jekyll-AEO:",
                           "dotmd_mode: md2dotmd set but no source file for #{obj.url}"
        [nil, "md2dotmd"]
      end

      def self.extract_from_source(source_path, obj, dotmd_config, preferred)
        raw = File.read(source_path, encoding: "utf-8")
        body = raw.sub(YAML_FRONT_MATTER_REGEXP, "")

        if preferred != "md2dotmd" && body.match?(LIQUID_PATTERN)
          html_output = obj.respond_to?(:output) ? obj.output : nil
          return html2dotmd_result(html_output, dotmd_config) if html_output && !html_output.strip.empty?
        end

        [JekyllAeo::Utils::ContentStripper.strip(body, dotmd_config["md2dotmd"]), "md2dotmd"]
      end

      def self.html2dotmd_result(html, dotmd_config)
        [JekyllAeo::Utils::HtmlConverter.convert(html, dotmd_config["html2dotmd"] || {}), "html2dotmd"]
      end

      def self.build_header(obj, body, _config = nil, last_modified: nil)
        header = ""
        title = obj.data["title"]

        header += "# #{title}\n\n" if title && !title.to_s.empty? && !body.lstrip.start_with?("# ")

        description = obj.data["description"]
        if description && !description.to_s.empty?
          lines = description.to_s.split("\n")
          header += if lines.length > 1
                      "#{lines.map { |l| "> #{l}" }.join("\n")}\n\n"
                    else
                      "> #{description}\n\n"
                    end
        end

        header += "> Last updated: #{last_modified}\n\n" if last_modified

        header
      end

      def self.resolve_last_modified(obj, source_path)
        lm = obj.data["last_modified_at"]
        return format_date(lm) if lm

        date = obj.data["date"]
        return format_date(date) if date

        return File.mtime(source_path).strftime("%Y-%m-%d") if File.exist?(source_path)

        nil
      end

      def self.format_date(value)
        case value
        when Time, DateTime
          value.strftime("%Y-%m-%d")
        when String
          begin
            Date.parse(value).to_s
          rescue StandardError
            value
          end
        else
          value.to_s
        end
      end

      YAML_NEEDS_QUOTING = /[:\#"'{}\[\],&*?|<>=!%@`\n\r]/

      def self.yaml_safe_scalar(value)
        str = value.to_s
        return str unless str.match?(YAML_NEEDS_QUOTING) || str.strip != str

        escaped = str.gsub("\\", "\\\\\\\\").gsub('"', '\\"').gsub("\n", '\n')
        "\"#{escaped}\""
      end

      SCALAR_FIELDS = %w[title description author lang].freeze

      def self.build_metadata_block(obj, site, _config, last_modified)
        lines = ["---"]
        metadata_fields(obj, site, last_modified).each do |key, value|
          next if value.nil? || value.to_s.empty?

          lines << "#{key}: #{SCALAR_FIELDS.include?(key) ? yaml_safe_scalar(value) : value}"
        end
        lines << "---"
        lines << ""
        lines.join("\n")
      end

      def self.metadata_fields(obj, site, last_modified)
        canonical = obj.data["canonical_url"] ||
                    "#{site.config['url']}#{site.config['baseurl'].to_s.chomp('/')}#{obj.url}"
        [
          ["title", obj.data["title"]],
          ["url", obj.url],
          ["canonical", canonical],
          ["description", obj.data["description"]],
          ["author", obj.data["author"]],
          ["date", obj.data["date"] ? format_date(obj.data["date"]) : nil],
          ["last_modified", last_modified],
          ["lang", obj.data["lang"] || obj.data["language"]]
        ]
      end

      def self.md_dest_path(obj, site)
        JekyllAeo::Utils::MdUrl.dest_path(obj, site)
      end

      private_class_method :build_header, :md_dest_path, :resolve_last_modified,
                           :format_date, :build_metadata_block,
                           :yaml_safe_scalar, :extract_body, :metadata_fields,
                           :extract_html2dotmd, :extract_explicit_md2dotmd,
                           :extract_from_source, :html2dotmd_result
    end
  end
end
