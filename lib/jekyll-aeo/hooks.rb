# frozen_string_literal: true

Jekyll::Hooks.register :documents, :pre_render do |doc|
  JekyllAeo::LinkTag.set_data(doc, doc.site)
end

Jekyll::Hooks.register :pages, :pre_render do |page|
  JekyllAeo::LinkTag.set_data(page, page.site)
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  JekyllAeo::LinkTag.inject(doc, doc.site)
end

Jekyll::Hooks.register :pages, :post_render do |page|
  JekyllAeo::LinkTag.inject(page, page.site)
end

Jekyll::Hooks.register :documents, :post_write do |doc|
  JekyllAeo::Generators::MarkdownPage.process(doc, doc.site)
end

Jekyll::Hooks.register :pages, :post_write do |page|
  JekyllAeo::Generators::MarkdownPage.process(page, page.site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  JekyllAeo::Generators::LlmsTxt.generate(site)
  JekyllAeo::Generators::UrlMap.generate(site)
end
