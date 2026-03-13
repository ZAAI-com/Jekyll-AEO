# frozen_string_literal: true

module JekyllAeo
  module LinkTag
    def self.inject(obj, site)
      config = JekyllAeo::Config.from_site(site)
      dotmd_config = config["dotmd"]
      return unless dotmd_config["link_tag"] == "auto"
      return if JekyllAeo::Utils::SkipLogic.skip?(obj, site, config)

      md_url = JekyllAeo::Utils::MdUrl.for(obj.url, site.config["baseurl"])
      tag = %(<link rel="alternate" type="text/markdown" href="#{md_url}">)
      obj.output = obj.output.sub("</head>", "#{tag}\n</head>")
    end

    def self.set_data(obj, site)
      config = JekyllAeo::Config.from_site(site)
      dotmd_config = config["dotmd"]
      return unless dotmd_config["link_tag"] == "data"
      return if JekyllAeo::Utils::SkipLogic.skip?(obj, site, config)

      md_url = JekyllAeo::Utils::MdUrl.for(obj.url, site.config["baseurl"])
      obj.data["md_url"] = md_url
      obj.data["md_link_tag"] = %(<link rel="alternate" type="text/markdown" href="#{md_url}">)
    end
  end
end
