# frozen_string_literal: true

module JekyllAeo
  module Utils
    module MdUrl
      def self.for(url, config, baseurl = "")
        baseurl = baseurl.to_s.chomp("/")
        md_path = if config["md_path_style"] == "spec"
                    url.end_with?("/") ? "#{url}index.html.md" : "#{url}.md"
                  elsif url == "/"
                    "/index.md"
                  elsif url.end_with?("/")
                    url.sub(%r{/\z}, ".md")
                  else
                    "#{url}.md"
                  end
        "#{baseurl}#{md_path}"
      end
    end
  end
end
