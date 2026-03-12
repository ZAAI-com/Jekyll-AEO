# frozen_string_literal: true

module JekyllAeo
  module Utils
    module SkipLogic
      def self.skip?(obj, site, config)
        return true if config["enabled"] == false
        return true unless html_output?(obj)
        return true if obj.data["markdown_copy"] == false
        return true if obj.data["redirect_to"]
        return true if assets_collection?(obj)
        return true if llms_file?(obj, site)
        return true if excluded?(obj, config)
        return true unless source_file_exists?(obj, site)

        false
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

      def self.assets_collection?(obj)
        obj.respond_to?(:collection) && obj.collection&.label == "assets"
      end

      def self.llms_file?(obj, site)
        dest = obj.destination(site.dest)
        dest.end_with?("llms.txt") || dest.end_with?("llms-full.txt")
      end

      def self.excluded?(obj, config)
        excludes = config["exclude"] || []
        excludes.any? { |prefix| obj.url.start_with?(prefix) }
      end

      def self.source_file_exists?(obj, site)
        path = resolve_source_path(obj, site)
        File.exist?(path)
      end

      private_class_method :html_output?, :assets_collection?, :llms_file?,
                           :excluded?, :source_file_exists?
    end
  end
end
