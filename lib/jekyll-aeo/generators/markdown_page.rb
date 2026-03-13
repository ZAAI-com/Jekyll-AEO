# frozen_string_literal: true

require "fileutils"

module JekyllAeo
  module Generators
    module MarkdownPage
      YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m

      def self.process(obj, site)
        config = JekyllAeo::Config.from_site(site)
        source_path = JekyllAeo::Utils::SkipLogic.resolve_source_path(obj, site)
        return if JekyllAeo::Utils::SkipLogic.skip?(obj, site, config)

        dest_path = md_dest_path(obj, site, config)
        raw = File.read(source_path, encoding: "utf-8")
        body = raw.sub(YAML_FRONT_MATTER_REGEXP, "")
        body = JekyllAeo::Utils::ContentStripper.strip(body, config)

        last_modified = resolve_last_modified(obj, source_path) if config["include_last_modified"]

        if config["md_metadata"]
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
        when Date
          value.to_s
        when String
          (Date.parse(value).to_s rescue value)
        else
          value.to_s
        end
      end

      YAML_NEEDS_QUOTING = /[:\#"'{}\[\],&*?|<>=!%@`\n\r]/.freeze

      def self.yaml_safe_scalar(value)
        str = value.to_s
        return str unless str.match?(YAML_NEEDS_QUOTING) || str.strip != str

        escaped = str.gsub('\\', '\\\\\\\\').gsub('"', '\\"').gsub("\n", '\n')
        "\"#{escaped}\""
      end

      def self.build_metadata_block(obj, site, _config, last_modified)
        lines = []
        lines << "---"

        title = obj.data["title"]
        lines << "title: #{yaml_safe_scalar(title)}" if title && !title.to_s.empty?

        lines << "url: #{obj.url}" if obj.url

        canonical = obj.data["canonical_url"] ||
                    "#{site.config['url']}#{site.config['baseurl'].to_s.chomp('/')}#{obj.url}"
        lines << "canonical: #{canonical}" if canonical && !canonical.to_s.empty?

        description = obj.data["description"]
        lines << "description: #{yaml_safe_scalar(description)}" if description && !description.to_s.empty?

        author = obj.data["author"]
        lines << "author: #{yaml_safe_scalar(author)}" if author && !author.to_s.empty?

        date = obj.data["date"]
        lines << "date: #{format_date(date)}" if date

        lines << "last_modified: #{last_modified}" if last_modified

        lang = obj.data["lang"] || obj.data["language"]
        lines << "lang: #{yaml_safe_scalar(lang)}" if lang && !lang.to_s.empty?

        lines << "---"
        lines << ""

        lines.join("\n")
      end

      def self.md_dest_path(obj, site, config)
        JekyllAeo::Utils::MdUrl.dest_path(obj, site, config)
      end

      private_class_method :build_header, :md_dest_path, :resolve_last_modified,
                           :format_date, :build_metadata_block,
                           :yaml_safe_scalar
    end
  end
end
