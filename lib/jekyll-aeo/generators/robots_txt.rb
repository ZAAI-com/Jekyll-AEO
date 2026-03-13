# frozen_string_literal: true

module JekyllAeo
  module Generators
    class RobotsTxt < Jekyll::Generator
      priority :low
      safe true

      def generate(site)
        config = JekyllAeo::Config.from_site(site)
        return if config["enabled"] == false

        robots_config = config["robots_txt"] || {}
        return if robots_config["enabled"] == false
        return if user_robots_exists?(site)

        content = build_content(robots_config, site)
        page = Jekyll::PageWithoutAFile.new(site, site.source, "", "robots.txt")
        page.content = content
        page.data["layout"] = nil
        site.pages << page
      end

      private

      def user_robots_exists?(site)
        File.exist?(File.join(site.source, "robots.txt"))
      end

      def build_content(robots_config, site)
        lines = []
        bot_rules(lines, robots_config["allow"] || [], "Allow")
        bot_rules(lines, robots_config["disallow"] || [], "Disallow")
        lines << "User-agent: *"
        lines << "Allow: /"
        lines << ""
        custom_rules(lines, robots_config["custom_rules"] || [])
        append_metadata_lines(lines, robots_config, site)
        "#{lines.join("\n")}\n"
      end

      def bot_rules(lines, bots, directive)
        bots.each do |bot|
          lines << "User-agent: #{bot}"
          lines << "#{directive}: /"
          lines << ""
        end
      end

      def custom_rules(lines, rules)
        rules.each do |rule|
          lines << "User-agent: #{rule['user_agent']}"
          lines << "Allow: #{rule['allow']}" if rule["allow"]
          lines << "Disallow: #{rule['disallow']}" if rule["disallow"]
          lines << ""
        end
      end

      def append_metadata_lines(lines, robots_config, site)
        base_url = site.config["url"].to_s.chomp("/")
        baseurl = site.config["baseurl"].to_s.chomp("/")
        lines << "Sitemap: #{base_url}#{baseurl}/sitemap.xml" if robots_config["include_sitemap"] != false
        lines << "Llms-txt: #{base_url}#{baseurl}/llms.txt" if robots_config["include_llms_txt"] != false
      end
    end
  end
end
