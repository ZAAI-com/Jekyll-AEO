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

  def mock_page(title: "Test Page", description: nil, source_file: "page.md",
                dest_path: nil, url: "/page/")
    data = { "title" => title }
    data["description"] = description if description

    dest = dest_path || File.join(@dest_dir, "page", "index.html")
    rel_path = source_file

    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| dest }
    obj.define_singleton_method(:relative_path) { rel_path }
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
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    assert File.exist?(output_path), "Expected .md file at clean path"

    content = read_output(output_path)
    assert content.start_with?("# Test Page\n"), "Expected title header"
    assert_includes content, "Some content here."
  end

  def test_does_not_prepend_title_when_h1_exists
    write_source("page.md", "---\ntitle: Test Page\n---\n# My Custom Heading\n\nContent.\n")
    page = mock_page
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute content.start_with?("# Test Page\n"), "Should not prepend title when H1 exists"
    assert content.start_with?("# My Custom Heading\n"), "Should keep original H1"
  end

  def test_adds_description_blockquote
    write_source("page.md", "---\ntitle: Test Page\ndescription: A great page\n---\nContent.\n")
    page = mock_page(description: "A great page")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> A great page"
  end

  def test_multiline_description_blockquoted
    desc = "Line one\nLine two\nLine three"
    write_source("page.md", "---\ntitle: Test Page\n---\nContent.\n")
    page = mock_page(description: desc)
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "> Line one\n> Line two\n> Line three"
  end

  def test_strips_yaml_front_matter
    write_source("page.md", "---\ntitle: Test\nlayout: page\n---\nBody content.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "layout: page"
    refute_includes content, "---"
    assert_includes content, "Body content."
  end

  def test_strips_liquid_from_body
    write_source("page.md", "---\ntitle: Test\n---\nHello {% if true %}world{% endif %}.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    assert_includes content, "Hello world."
    refute_includes content, "{% if"
  end

  def test_collapses_blank_lines
    write_source("page.md", "---\ntitle: Test\n---\n\n\n\n\nContent.\n")
    page = mock_page(title: "Test")
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    output_path = File.join(@dest_dir, "page.md")
    content = read_output(output_path)
    refute_includes content, "\n\n\n"
  end

  def test_clean_path_style_default
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page
    JekyllAeo::Generators::MarkdownPage.process(page, mock_site)

    assert File.exist?(File.join(@dest_dir, "page.md")),
           "Default clean style: /page/index.html -> /page.md"
    refute File.exist?(File.join(@dest_dir, "page", "index.html.md")),
           "Should not create spec-style path by default"
  end

  def test_spec_path_style
    write_source("page.md", "---\ntitle: Test\n---\nContent.\n")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "md_path_style" => "spec" })
    JekyllAeo::Generators::MarkdownPage.process(page, site)

    assert File.exist?(File.join(@dest_dir, "page", "index.html.md")),
           "Spec style: /page/index.html -> /page/index.html.md"
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
end
