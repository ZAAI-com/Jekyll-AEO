# frozen_string_literal: true

require "minitest/autorun"
require "json"

class ExampleSiteTest < Minitest::Test
  SITE_DIR = File.expand_path("../../demo/example.com", __dir__)
  DEST_DIR = File.join(SITE_DIR, "_public")

  def self.build_site
    return if @built

    Bundler.with_unbundled_env do
      Dir.chdir(SITE_DIR) do
        system("bundle install --quiet", exception: true)
        system("bundle exec jekyll build --quiet", exception: true)
      end
    end
    @built = true
  end

  def setup
    self.class.build_site
  end

  # --- File existence ---

  def test_llms_txt_exists
    assert_path_exists File.join(DEST_DIR, "llms.txt"), "llms.txt should be generated"
  end

  def test_llms_full_txt_exists
    assert_path_exists File.join(DEST_DIR, "llms-full.txt"), "llms-full.txt should be generated"
  end

  def test_robots_txt_exists
    assert_path_exists File.join(DEST_DIR, "robots.txt"), "robots.txt should be generated"
  end

  def test_domain_profile_exists
    assert_path_exists File.join(DEST_DIR, ".well-known", "domain-profile.json"),
                       "domain-profile.json should be generated"
  end

  def test_markdown_copies_exist
    %w[index.md faq.md howto.md code-examples.md].each do |md|
      assert_path_exists File.join(DEST_DIR, md), "#{md} should be generated"
    end
  end

  def test_root_index_html_md_exists
    assert_path_exists File.join(DEST_DIR, "index.html.md"), "index.html.md should be generated"
    assert_equal File.read(File.join(DEST_DIR, "index.md")),
                 File.read(File.join(DEST_DIR, "index.html.md")),
                 "index.html.md should have same content as index.md"
  end

  def test_post_markdown_copies_exist
    %w[blog/getting-started-with-aeo.md blog/structured-data-guide.md].each do |md|
      assert_path_exists File.join(DEST_DIR, md), "#{md} should be generated"
    end
  end

  # --- llms.txt content ---

  def test_llms_txt_has_title
    content = File.read(File.join(DEST_DIR, "llms.txt"))

    assert_includes content, "# Example.com"
  end

  def test_llms_txt_lists_pages
    content = File.read(File.join(DEST_DIR, "llms.txt"))

    assert_includes content, "Frequently Asked Questions"
    assert_includes content, "How to Install jekyll-aeo"
  end

  def test_llms_txt_lists_posts
    content = File.read(File.join(DEST_DIR, "llms.txt"))

    assert_includes content, "Getting Started with AEO"
    assert_includes content, "Structured Data Guide"
  end

  # --- robots.txt content ---

  def test_robots_txt_allows_search_bots
    content = File.read(File.join(DEST_DIR, "robots.txt"))

    assert_includes content, "User-agent: Googlebot\nAllow: /"
  end

  def test_robots_txt_disallows_training_bots
    content = File.read(File.join(DEST_DIR, "robots.txt"))

    assert_includes content, "User-agent: GPTBot\nDisallow: /"
  end

  def test_robots_txt_includes_llms_txt_reference
    content = File.read(File.join(DEST_DIR, "robots.txt"))

    assert_includes content, "Llms-txt: https://example.com/llms.txt"
  end

  # --- domain-profile.json ---

  def test_domain_profile_content
    json = JSON.parse(File.read(File.join(DEST_DIR, ".well-known", "domain-profile.json")))

    assert_equal "Example.com", json["name"]
    assert_equal "hello@example.com", json["contact"]
    assert_equal "Organization", json["entity_type"]
  end

  # --- JSON-LD schemas in HTML ---

  def test_homepage_has_organization_schema
    html = File.read(File.join(DEST_DIR, "index.html"))

    assert_match(/"@type":\s*"Organization"/, html)
  end

  def test_faq_page_has_faq_schema
    html = File.read(File.join(DEST_DIR, "faq", "index.html"))

    assert_match(/"@type":\s*"FAQPage"/, html)
  end

  def test_faq_page_has_breadcrumb_schema
    html = File.read(File.join(DEST_DIR, "faq", "index.html"))

    assert_match(/"@type":\s*"BreadcrumbList"/, html)
  end

  def test_howto_page_has_howto_schema
    html = File.read(File.join(DEST_DIR, "howto", "index.html"))

    assert_match(/"@type":\s*"HowTo"/, html)
  end

  def test_post_has_speakable_schema
    html = File.read(File.join(DEST_DIR, "blog", "getting-started-with-aeo", "index.html"))

    assert_match(/"@type":\s*"SpeakableSpecification"/, html)
  end

  def test_post_with_faq_has_faq_schema
    html = File.read(File.join(DEST_DIR, "blog", "structured-data-guide", "index.html"))

    assert_match(/"@type":\s*"FAQPage"/, html)
  end

  # --- Link tag injection ---

  def test_pages_have_markdown_link_tag
    html = File.read(File.join(DEST_DIR, "faq", "index.html"))

    assert_includes html, 'rel="alternate" type="text/markdown"'
  end

  def test_posts_have_markdown_link_tag
    html = File.read(File.join(DEST_DIR, "blog", "getting-started-with-aeo", "index.html"))

    assert_includes html, 'rel="alternate" type="text/markdown"'
  end

  # --- Markdown copy content ---

  def test_faq_markdown_has_title
    content = File.read(File.join(DEST_DIR, "faq.md"))

    assert_includes content, "Frequently Asked Questions"
  end

  def test_howto_markdown_preserves_code_fence
    content = File.read(File.join(DEST_DIR, "howto.md"))

    assert_includes content, "```ruby"
    assert_includes content, 'gem "jekyll-aeo"'
  end

  def test_code_examples_preserves_indented_code
    content = File.read(File.join(DEST_DIR, "code-examples.md"))

    assert_includes content, "def indented_example():"
  end
end
