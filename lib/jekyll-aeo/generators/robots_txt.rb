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

        allow_bots = robots_config["allow"] || []
        allow_bots.each do |bot|
          lines << "User-agent: #{bot}"
          lines << "Allow: /"
          lines << ""
        end

        disallow_bots = robots_config["disallow"] || []
        disallow_bots.each do |bot|
          lines << "User-agent: #{bot}"
          lines << "Disallow: /"
          lines << ""
        end

        lines << "User-agent: *"
        lines << "Allow: /"
        lines << ""

        custom_rules = robots_config["custom_rules"] || []
        custom_rules.each do |rule|
          lines << "User-agent: #{rule['user_agent']}"
          lines << "Allow: #{rule['allow']}" if rule["allow"]
          lines << "Disallow: #{rule['disallow']}" if rule["disallow"]
          lines << ""
        end

        base_url = site.config["url"].to_s.chomp("/")
        baseurl = site.config["baseurl"].to_s.chomp("/")

        if robots_config["include_sitemap"] != false
          lines << "Sitemap: #{base_url}#{baseurl}/sitemap.xml"
        end

        if robots_config["include_llms_txt"] != false
          lines << "Llms-txt: #{base_url}#{baseurl}/llms.txt"
        end

        lines.join("\n") + "\n"
      end
    end
  end
end
