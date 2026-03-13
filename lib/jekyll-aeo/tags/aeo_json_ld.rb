# frozen_string_literal: true

require "json"

module JekyllAeo
  module Tags
    class AeoJsonLd < Liquid::Tag
      BUILDERS = [
        JekyllAeo::Schema::FaqPage,
        JekyllAeo::Schema::HowTo,
        JekyllAeo::Schema::BreadcrumbList,
        JekyllAeo::Schema::Organization,
        JekyllAeo::Schema::Speakable,
        JekyllAeo::Schema::Article
      ].freeze

      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]

        results = BUILDERS.filter_map { |builder| builder.build(page, site.config) }

        results.map do |schema|
          json = JSON.pretty_generate(schema).gsub("</", "<\\/")
          "<script type=\"application/ld+json\">\n#{json}\n</script>"
        end.join("\n")
      end
    end
  end
end

Liquid::Template.register_tag("aeo_json_ld", JekyllAeo::Tags::AeoJsonLd)
