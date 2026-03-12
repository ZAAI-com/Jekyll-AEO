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
        header = build_header(obj, body)
        result = header + body.lstrip
        result = result.gsub(/\n{3,}/, "\n\n")
        result = "#{result.rstrip}\n"

        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, result)
      end

      def self.build_header(obj, body)
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

        header
      end

      def self.md_dest_path(obj, site, config)
        html_path = obj.destination(site.dest)
        if config["md_path_style"] == "spec"
          "#{html_path}.md"
        else
          dir = File.dirname(html_path)
          base = File.basename(html_path)
          if base == "index.html" && dir != site.dest
            File.join(File.dirname(dir), "#{File.basename(dir)}.md")
          else
            html_path.sub(/\.html\z/, ".md")
          end
        end
      end

      private_class_method :build_header, :md_dest_path
    end
  end
end
