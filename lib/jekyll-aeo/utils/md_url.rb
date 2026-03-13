# frozen_string_literal: true

module JekyllAeo
  module Utils
    module MdUrl
      def self.for(url, baseurl = "")
        baseurl = baseurl.to_s.chomp("/")
        md_path = if url == "/"
                    "/index.md"
                  elsif url.end_with?("/")
                    url.sub(%r{/\z}, ".md")
                  elsif url.end_with?(".html")
                    url.sub(/\.html\z/, ".md")
                  else
                    "#{url}.md"
                  end
        "#{baseurl}#{md_path}"
      end

      def self.dest_path(obj, site)
        html_path = obj.destination(site.dest)
        dir = File.dirname(html_path)
        base = File.basename(html_path)
        if base == "index.html" && dir != site.dest
          File.join(File.dirname(dir), "#{File.basename(dir)}.md")
        else
          html_path.sub(/\.html\z/, ".md")
        end
      end
    end
  end
end
