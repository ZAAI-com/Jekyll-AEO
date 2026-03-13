# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module MarkdownPage
      YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m

      def self.process(obj, site)
        config = JekyllAeo::Config.from_site(site)
        mp_config = config["markdown_pages"]
        source_path = JekyllAeo::Utils::SkipLogic.resolve_source_path(obj, site)
        return if JekyllAeo::Utils::SkipLogic.skip?(obj, site, config)

        dest_path = md_dest_path(obj, site)
        body = extract_body(source_path, obj, mp_config)

        if mp_config["include_last_modified"] && File.exist?(source_path)
          last_modified = resolve_last_modified(obj, source_path)
        end

        if mp_config["md_metadata"]
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
      end

      def self.extract_body(source_path, obj, mp_config)
        if File.exist?(source_path)
          raw = File.read(source_path, encoding: "utf-8")
          body = raw.sub(YAML_FRONT_MATTER_REGEXP, "")
          JekyllAeo::Utils::ContentStripper.strip(body, mp_config)
        else
          JekyllAeo::Utils::HtmlConverter.convert(obj.output, mp_config)
        end
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
                           :yaml_safe_scalar, :extract_body, :metadata_fields
    end
  end
end
