# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class MarkdownPageTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @source_dir = File.join(@tmpdir, "source")
    @dest_dir = File.join(@tmpdir, "public")
    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(File.join(@dest_dir, "page"))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def mock_site(config_overrides = {})
    source = @source_dir
    dest = @dest_dir
    cfg = config_overrides
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) { cfg }
    site
  end

  def no_lastmod_site(extra = {})
    mock_site({ "jekyll_aeo" => { "markdown_pages" => { "include_last_modified" => false }.merge(extra) } })
  end

  def mock_page(title: "Test Page", description: nil, source_file: "page.md",
                dest_path: nil, url: "/page/", last_modified_at: nil, date: nil,
                author: nil, lang: nil, canonical_url: nil, output: nil)
    data = { "title" => title }
    data["description"] = description if description
    data["last_modified_at"] = last_modified_at if last_modified_at
    data["date"] = date if date
    data["author"] = author if author
    data["lang"] = lang if lang
    data["canonical_url"] = canonical_url if canonical_url

    dest = dest_path || File.join(@dest_dir, "page", "index.html")
    rel_path = source_file
    html_output = output

    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| dest }
    obj.define_singleton_method(:relative_path) { rel_path }
    obj.define_singleton_method(:output) { html_output } if html_output
    obj
  end

  def write_source(filename, content)
    File.write(File.join(@source_dir, filename), content)
  end

  def read_output(path)
    File.read(path)
  end

  # --- Default (clean) path style ---

  def test_generates_md_file_with_clean_path
    write_source("page.md", "---\ntitle: Test Page\n---\nSome content here.\n")
    page = mock_page
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    assert File.exist?(output_path), "Expected .md file at clean path"

    content = read_output(output_path)
    assert content.start_with?("# Test Page\n"), "Expected title header"
    assert_includes content, "Some content here."
  end

  def test_does_not_prepend_title_when_h1_exists
    write_source("page.md", "---\ntitle: Test Page\n---\n# My Custom Heading\n\nContent.\n")
    page = mock_page
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "# Test Page\n"
    assert_includes content, "# My Custom Heading"
  end

  def test_adds_description_blockquote
    write_source("page.md", "---\ntitle: Test Page\ndescription: A great page\n---\nContent.\n")
    page = mock_page(description: "A great page")
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> A great page"
  end

  def test_multiline_description_blockquoted
    desc = "Line one\nLine two\nLine three"
    write_source("page.md", "---\ntitle: Test Page\n---\nContent.\n")
    page = mock_page(description: desc)
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Line one\n> Line two\n> Line three"
  end

  def test_strips_yaml_front_matter
    write_source("page.md", "---\ntitle: Test\nlayout: page\n---\nBody content.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "layout: page"
    refute_includes content, "---"
    assert_includes content, "Body content."
  end

  def test_strips_liquid_from_body
    write_source("page.md", "---\ntitle: Test\n---\nHello {% if true %}world{% endif %}.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "Hello world."
    refute_includes content, "{% if"
  end

  def test_collapses_blank_lines
    write_source("page.md", "---\ntitle: Test\n---\n\n\n\n\nContent.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "\n\n\n"
  end

  def test_clean_path_style
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    assert File.exist?(File.join(@dest_dir, "page.md")),
           "Clean style: /page/index.html -> /page.md"
  end

  def test_creates_directories_as_needed
    deep_dest = File.join(@dest_dir, "deep", "nested", "page", "index.html")
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(dest_path: deep_dest)
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    assert File.exist?(File.join(@dest_dir, "deep", "nested", "page.md"))
  end

  def test_ensures_trailing_newline
    write_source("page.md", "---\ntitle: Test\n---\nContent")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert content.end_with?("\n"), "Should end with newline"
  end

  # --- Feature 2: Last-modified ---

  def test_includes_last_modified_from_last_modified_at
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", last_modified_at: Time.new(2025, 6, 15))
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Last updated: 2025-06-15"
  end

  def test_includes_last_modified_from_date
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", date: Time.new(2024, 1, 1))
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Last updated: 2024-01-01"
  end

  def test_last_modified_at_takes_priority_over_date
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", last_modified_at: Time.new(2025, 6, 15), date: Time.new(2024, 1, 1))
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Last updated: 2025-06-15"
    refute_includes content, "2024-01-01"
  end

  def test_last_modified_falls_back_to_mtime
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Last updated:"
  end

  def test_last_modified_disabled_via_config
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", last_modified_at: Time.new(2025, 6, 15))
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "Last updated"
  end

  def test_last_modified_after_description
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", description: "A page", last_modified_at: Time.new(2025, 6, 15))
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    desc_pos = content.index("> A page")
    last_mod_pos = content.index("> Last updated:")
    assert desc_pos < last_mod_pos, "Last updated should appear after description"
  end

  # --- Feature 4: Structured metadata header ---

  def test_md_metadata_disabled_by_default
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, no_lastmod_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute content.start_with?("---\n"), "Metadata block should not appear by default"
  end

  def test_md_metadata_block_when_enabled
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(
      title: "Test Page", description: "A test", url: "/page/",
      author: "Manuel", date: Time.new(2025, 3, 10), lang: "en"
    )
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert content.start_with?("---\n"), "Should start with metadata block"
    assert_includes content, "title: Test Page"
    assert_includes content, "url: /page/"
    assert_includes content, "description: A test"
    assert_includes content, "author: Manuel"
    assert_includes content, "date: 2025-03-10"
    assert_includes content, "lang: en"
  end

  def test_md_metadata_includes_canonical
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "canonical: https://example.com/page/"
  end

  def test_md_metadata_uses_front_matter_canonical
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/", canonical_url: "https://other.com/page/")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "canonical: https://other.com/page/"
    refute_includes content, "canonical: https://example.com/page/"
  end

  def test_md_metadata_omits_empty_fields
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/")
    site = mock_site("jekyll_aeo" => { "markdown_pages" => { "md_metadata" => true,
                                                             "include_last_modified" => false } })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "author:"
    refute_includes content, "lang:"
    refute_includes content, "date:"
  end

  def test_md_metadata_with_last_modified
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", last_modified_at: Time.new(2025, 6, 15))
    site = mock_site("jekyll_aeo" => { "markdown_pages" => { "md_metadata" => true } })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "last_modified: 2025-06-15"
  end

  def test_md_metadata_no_duplicate_last_modified
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", last_modified_at: Time.new(2025, 6, 15))
    site = mock_site("jekyll_aeo" => { "markdown_pages" => { "md_metadata" => true } })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "> Last updated:", "Should not have blockquote last_modified when metadata enabled"
    assert_includes content, "last_modified: 2025-06-15"
  end

  def test_md_metadata_preserves_title_and_description
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test Page", description: "A test")
    site = mock_site("jekyll_aeo" => { "markdown_pages" => { "md_metadata" => true,
                                                             "include_last_modified" => false } })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "# Test Page"
    assert_includes content, "> A test"
  end

  # --- Bug fix: YAML-safe quoting for metadata scalars ---

  def test_md_metadata_quotes_title_with_colon
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "FAQ: Setup Guide")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, 'title: "FAQ: Setup Guide"'
  end

  def test_md_metadata_quotes_description_with_hash
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", description: "Use # for headings")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, 'description: "Use # for headings"'
  end

  def test_md_metadata_quotes_author_with_special_chars
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", author: "Name: Alias")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, 'author: "Name: Alias"'
  end

  def test_md_metadata_plain_values_unquoted
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "My Simple Title", author: "Manuel", lang: "en")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "title: My Simple Title"
    assert_includes content, "author: Manuel"
    assert_includes content, "lang: en"
  end

  # --- Bug fix: canonical URL includes baseurl ---

  def test_md_metadata_canonical_includes_baseurl
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/")
    site = mock_site("url" => "https://example.com", "baseurl" => "/docs", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "canonical: https://example.com/docs/page/"
  end

  def test_md_metadata_canonical_nil_baseurl
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/")
    site = mock_site("url" => "https://example.com", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "canonical: https://example.com/page/"
  end

  def test_md_metadata_canonical_baseurl_trailing_slash
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page(title: "Test", url: "/page/")
    site = mock_site("url" => "https://example.com", "baseurl" => "/docs/", "jekyll_aeo" => {
                       "markdown_pages" => { "md_metadata" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "canonical: https://example.com/docs/page/"
  end

  # --- HTML fallback ---

  def test_html_fallback_generates_md_from_html_output
    html = "<html><body><main><h1>Generated Page</h1><p>Plugin content.</p></main></body></html>"
    page = mock_page(
      title: "Generated Page", source_file: "nonexistent_xyz.md", output: html
    )
    site = mock_site("jekyll_aeo" => {
                       "markdown_pages" => { "html_fallback" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    assert File.exist?(output_path), "Expected .md file from HTML fallback"

    content = read_output(output_path)
    assert_includes content, "Plugin content."
  end

  def test_html_fallback_disabled_skips_no_source_page
    html = "<html><body><p>Content</p></body></html>"
    page = mock_page(title: "Test", source_file: "nonexistent_xyz.md", output: html)
    site = no_lastmod_site
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    refute File.exist?(output_path), "Should not generate .md when html_fallback is disabled"
  end

  def test_html_fallback_extracts_main_content
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Test</title></head>
      <body>
        <header><h1>Site Header</h1></header>
        <nav><a href="/">Home</a></nav>
        <main>
          <h2>Page Content</h2>
          <p>Important text from plugin.</p>
        </main>
        <footer><p>Copyright 2025</p></footer>
        <script>alert('hi');</script>
      </body>
      </html>
    HTML
    page = mock_page(
      title: "Test", source_file: "nonexistent_xyz.md", output: html
    )
    site = mock_site("jekyll_aeo" => {
                       "markdown_pages" => { "html_fallback" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "Important text from plugin."
    refute_includes content, "Site Header"
    refute_includes content, "Copyright 2025"
    refute_includes content, "alert"
  end

  def test_html_fallback_adds_title_and_description
    html = "<html><body><main><p>Plugin content.</p></main></body></html>"
    page = mock_page(
      title: "My Title", description: "My desc",
      source_file: "nonexistent_xyz.md", output: html
    )
    site = mock_site("jekyll_aeo" => {
                       "markdown_pages" => { "html_fallback" => true, "include_last_modified" => false }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "# My Title"
    assert_includes content, "> My desc"
    assert_includes content, "Plugin content."
  end

  def test_html_fallback_no_last_modified_from_mtime
    html = "<html><body><main><p>Content.</p></main></body></html>"
    page = mock_page(
      title: "Test", source_file: "nonexistent_xyz.md", output: html
    )
    site = mock_site("jekyll_aeo" => {
                       "markdown_pages" => { "html_fallback" => true }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "Last updated:", "Should not have mtime-based last_modified for fallback pages"
  end

  def test_html_fallback_with_custom_selector
    html = <<~HTML
      <html><body>
        <div class="sidebar">Side content</div>
        <div class="main-content">
          <p>Selected content.</p>
        </div>
      </body></html>
    HTML
    page = mock_page(
      title: "Test", source_file: "nonexistent_xyz.md", output: html
    )
    site = mock_site("jekyll_aeo" => {
                       "markdown_pages" => {
                         "html_fallback" => true,
                         "html_fallback_selector" => ".main-content",
                         "include_last_modified" => false
                       }
                     })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "Selected content."
    refute_includes content, "Side content"
  end
end
