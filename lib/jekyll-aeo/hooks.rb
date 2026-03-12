# frozen_string_literal: true

Jekyll::Hooks.register :documents, :post_write do |doc|
  JekyllAeo::Generators::MarkdownPage.process(doc, doc.site)
end

Jekyll::Hooks.register :pages, :post_write do |page|
  JekyllAeo::Generators::MarkdownPage.process(page, page.site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  JekyllAeo::Generators::LlmsTxt.generate(site)
end
