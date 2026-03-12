# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class UrlMapTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @source_dir = File.join(@tmpdir, "source")
    @dest_dir = File.join(@tmpdir, "public")
    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(@dest_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def mock_collection(label)
    col = Object.new
    col.define_singleton_method(:label) { label }
    col
  end

  def mock_document(url:, collection_label:, source_file:, data: {}, dest_html: nil)
    dest_html ||= url.end_with?("/") ? "#{url}index.html" : "#{url}.html"
    d = { "title" => "", "layout" => "" }.merge(data)
    col = mock_collection(collection_label)
    src_dir = @source_dir
    dst_dir = @dest_dir
    path = File.join(src_dir, source_file)

    obj = Object.new
    obj.define_singleton_method(:data) { d }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| File.join(dst_dir, dest_html) }
    obj.define_singleton_method(:collection) { col }
    obj.define_singleton_method(:path) { path }
    obj.define_singleton_method(:relative_path) { source_file }
    obj
  end

  def mock_page(url:, source_file:, data: {}, dest_html: nil)
    dest_html ||= url.end_with?("/") ? "#{url}index.html" : "#{url}.html"
    d = { "title" => "", "layout" => "" }.merge(data)
    dst_dir = @dest_dir

    obj = Object.new
    obj.define_singleton_method(:data) { d }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| File.join(dst_dir, dest_html) }
    obj.define_singleton_method(:relative_path) { source_file }
    obj
  end

  def mock_site(documents: [], pages: [], aeo_config: { "url_map" => { "enabled" => true } })
    source = @source_dir
    dest = @dest_dir
    docs = documents
    pgs = pages

    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) { { "jekyll_aeo" => aeo_config } }
    site.define_singleton_method(:documents) { docs }
    site.define_singleton_method(:pages) { pgs }
    site
  end

  def write_source(source_file)
    path = File.join(@source_dir, source_file)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "---\ntitle: Test\n---\nContent\n")
  end

  def output_path
    File.join(@source_dir, "docs/Url-Map.md")
  end

  # --- Enabled/Disabled tests ---

  def test_disabled_by_default
    site = mock_site(aeo_config: {})
    JekyllAeo::Generators::UrlMap.generate(site)
    refute File.exist?(output_path)
  end

  def test_disabled_via_master_switch
    site = mock_site(aeo_config: { "enabled" => false, "url_map" => { "enabled" => true } })
    JekyllAeo::Generators::UrlMap.generate(site)
    refute File.exist?(output_path)
  end

  def test_disabled_via_url_map_switch
    site = mock_site(aeo_config: { "url_map" => { "enabled" => false } })
    JekyllAeo::Generators::UrlMap.generate(site)
    refute File.exist?(output_path)
  end

  def test_generates_file_when_enabled
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: { "layout" => "page" })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    assert File.exist?(output_path), "url-map.md should be created"
    content = File.read(output_path)
    assert content.start_with?("# URL Map\n")
  end

  # --- Output path ---

  def test_custom_output_file
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md")
    site = mock_site(pages: [page], aeo_config: {
                       "url_map" => { "enabled" => true, "output_filepath" => "custom/map.md" }
                     })
    JekyllAeo::Generators::UrlMap.generate(site)

    custom_path = File.join(@source_dir, "custom/map.md")
    assert File.exist?(custom_path), "custom output_file should work"
  end

  # --- Columns ---

  def test_all_columns_by_default
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: { "layout" => "page" })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "Page ID"
    assert_includes content, "URL"
    assert_includes content, "Lang"
    assert_includes content, "Layout"
    assert_includes content, "Path"
    assert_includes content, "Redirects"
    assert_includes content, "Markdown Copy"
    assert_includes content, "Skipped"
  end

  def test_custom_columns
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: { "layout" => "page" })
    site = mock_site(pages: [page], aeo_config: {
                       "url_map" => { "enabled" => true, "columns" => %w[url path] }
                     })
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "| URL | Path |"
    refute_includes content, "Page ID"
    refute_includes content, "Markdown Copy"
    refute_includes content, "Skipped"
  end

  # --- Sections ---

  def test_sections_grouped_by_collection
    write_source("_pages/about.md")
    write_source("_products/widget.md")

    doc1 = mock_document(url: "/about/", collection_label: "pages", source_file: "_pages/about.md")
    doc2 = mock_document(url: "/products/widget/", collection_label: "products", source_file: "_products/widget.md")
    site = mock_site(documents: [doc1, doc2])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "## Pages"
    assert_includes content, "## Products"
  end

  def test_pages_section_first
    write_source("about.md")
    write_source("_posts/2024-01-01-hello.md")

    page = mock_page(url: "/about/", source_file: "about.md")
    doc = mock_document(url: "/blog/hello/", collection_label: "posts", source_file: "_posts/2024-01-01-hello.md")
    site = mock_site(documents: [doc], pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    pages_pos = content.index("## Pages")
    posts_pos = content.index("## Posts")
    assert pages_pos < posts_pos, "Pages section should come before Posts"
  end

  def test_items_sorted_by_url
    write_source("contact.md")
    write_source("about.md")

    page1 = mock_page(url: "/contact/", source_file: "contact.md")
    page2 = mock_page(url: "/about/", source_file: "about.md")
    site = mock_site(pages: [page1, page2])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    about_pos = content.index("/about/")
    contact_pos = content.index("/contact/")
    assert about_pos < contact_pos, "Items should be sorted alphabetically by URL"
  end

  # --- Column values ---

  def test_page_id_and_lang_from_frontmatter
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: {
                       "page_id" => "about_page", "lang" => "en", "layout" => "page"
                     })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "about_page"
    assert_includes content, "en"
  end

  def test_redirect_from_displayed
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: {
                       "redirect_from" => ["/about-us/", "/old-about/"]
                     })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "/about-us/, /old-about/"
  end

  def test_markdown_copy_url
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md")
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "/about.md"
  end

  def test_skipped_pages_show_reason
    write_source("secret.md")
    page = mock_page(url: "/secret/", source_file: "secret.md", data: { "redirect_to" => "/other/" })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "redirect"
  end

  def test_skipped_page_has_empty_markdown_copy
    write_source("secret.md")
    page = mock_page(url: "/secret/", source_file: "secret.md", data: { "redirect_to" => "/other/" })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    lines = content.lines.select { |l| l.include?("/secret/") }
    assert_equal 1, lines.length
    # The markdown_copy cell should be empty for skipped pages
    cells = lines.first.split("|").map(&:strip)
    md_copy_index = 7 # 0=empty, 1=page_id, 2=url, 3=lang, 4=layout, 5=path, 6=redirects, 7=markdown_copy
    assert_equal "", cells[md_copy_index]
  end

  # --- Edge cases ---

  def test_empty_site
    site = mock_site
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert content.start_with?("# URL Map\n")
    refute_includes content, "##"
  end

  def test_pipe_characters_escaped
    write_source("about.md")
    page = mock_page(url: "/about/", source_file: "about.md", data: {
                       "page_id" => "about|page", "layout" => "default"
                     })
    site = mock_site(pages: [page])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, 'about\|page'
  end

  def test_non_html_pages_excluded
    page_html = mock_page(url: "/about/", source_file: "about.md")
    write_source("about.md")

    page_css = Object.new
    page_css.define_singleton_method(:data) { {} }
    page_css.define_singleton_method(:output_ext) { ".css" }
    page_css.define_singleton_method(:url) { "/style.css" }
    page_css.define_singleton_method(:relative_path) { "style.css" }

    site = mock_site(pages: [page_html, page_css])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    assert_includes content, "/about/"
    refute_includes content, "style.css"
  end

  def test_assets_collection_excluded
    write_source("_assets/logo.md")
    doc = mock_document(url: "/assets/logo/", collection_label: "assets", source_file: "_assets/logo.md")
    site = mock_site(documents: [doc])
    JekyllAeo::Generators::UrlMap.generate(site)

    content = File.read(output_path)
    refute_includes content, "logo"
  end
end
