# frozen_string_literal: true

module JekyllAeo
  module Utils
    module IncludeLogic
      def self.exclude_reason(obj, site, config)
        return "plugin disabled" if config["enabled"] == false
        return "static file" if static_file?(obj)
        return "non-HTML output" unless html_output?(obj)
        return "dotmd_mode: disabled" if obj.data["dotmd_mode"] == "disabled"
        return "redirect" if obj.data["redirect_to"]
        return "layout: #{obj.data['layout']}" unless included_layout?(obj, config)
        return "collection: #{obj.collection.label}" unless included_collection?(obj, config)
        return "llms file" if llms_file?(obj, site)
        return "excluded" if excluded?(obj, config)
        return "no source file" unless source_available?(obj, site, config)

        nil
      end

      def self.include?(obj, site, config)
        exclude_reason(obj, site, config).nil?
      end

      def self.resolve_source_path(obj, site)
        if obj.respond_to?(:collection)
          obj.path
        else
          File.join(site.source, obj.relative_path)
        end
      end

      def self.html_output?(obj)
        obj.output_ext == ".html"
      end

      def self.static_file?(obj)
        obj.is_a?(Jekyll::StaticFile)
      end

      def self.included_layout?(obj, config)
        include_layouts = config["include_layouts"]
        return true if include_layouts.nil?

        include_layouts.include?(obj.data["layout"])
      end

      def self.included_collection?(obj, config)
        return true unless obj.respond_to?(:collection)

        include_collections = config["include_collections"]
        return true if include_collections.nil?

        include_collections.include?(obj.collection&.label)
      end

      def self.llms_file?(obj, site)
        dest = obj.destination(site.dest)
        return false unless dest.is_a?(String)

        basename = File.basename(dest)
        %w[llms.txt llms-full.txt].include?(basename)
      end

      def self.excluded?(obj, config)
        excludes = config["exclude"] || []
        excludes.any? { |prefix| obj.url.start_with?(prefix) }
      end

      def self.source_file_exists?(obj, site)
        path = resolve_source_path(obj, site)
        File.exist?(path)
      end

      def self.source_available?(obj, site, config)
        html2dotmd = config.dig("dotmd", "html2dotmd") || {}
        source_file_exists?(obj, site) || html2dotmd["enabled"]
      end

      private_class_method :html_output?, :static_file?, :included_layout?,
                           :included_collection?, :llms_file?,
                           :excluded?, :source_file_exists?, :source_available?
    end
  end
end
