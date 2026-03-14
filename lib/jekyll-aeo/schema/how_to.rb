# frozen_string_literal: true

module JekyllAeo
  module Schema
    module HowTo
      def self.build(page, _site_config, _aeo_config = {})
        howto = page["howto"]
        return nil unless howto.is_a?(Hash)

        steps = howto["steps"]
        return nil unless steps.is_a?(Array) && steps.any?

        step_entities = steps.each_with_index.filter_map { |step, i| build_step(step, i) }
        return nil if step_entities.empty?

        schema = { "@context" => "https://schema.org", "@type" => "HowTo", "step" => step_entities }
        add_optional_fields(schema, howto, page)
        schema
      end

      def self.build_step(step, index)
        return unless step.is_a?(Hash) && step["text"]

        entity = { "@type" => "HowToStep", "position" => index + 1, "text" => step["text"] }
        entity["name"] = step["name"] if step["name"]
        entity["url"] = step["url"] if step["url"]
        entity["image"] = step["image"] if step["image"]
        entity
      end

      def self.add_optional_fields(schema, howto, page)
        schema["name"] = howto["name"] || page["title"] if howto["name"] || page["title"]
        schema["description"] = howto["description"] if howto["description"]
        schema["totalTime"] = howto["totalTime"] if howto["totalTime"]
      end

      private_class_method :build_step, :add_optional_fields
    end
  end
end
