# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class LlmsTxtTest < Minitest::Test
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

  def mock_document(title:, description: "", url:, collection_label:, source_file:, dest_html:)
    data = { "title" => title, "description" => description }
    col = mock_collection(collection_label)
    src_dir = @source_dir
    dst_dir = @dest_dir
    path = File.join(src_dir, source_file)

    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| File.join(dst_dir, dest_html) }
    obj.define_singleton_method(:collection) { col }
    obj.define_singleton_method(:path) { path }
    obj.define_singleton_method(:relative_path) { source_file }
    obj
  end

  def mock_page(title:, description: "", url:, source_file:, dest_html:)
    data = { "title" => title, "description" => description }
    dst_dir = @dest_dir

    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| File.join(dst_dir, dest_html) }
    obj.define_singleton_method(:relative_path) { source_file }
    obj
  end

  def mock_site(documents: [], pages: [], title: "Test Site", description: "A test site")
    source = @source_dir
    dest = @dest_dir
    docs = documents
    pgs = pages

    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      { "title" => title, "description" => description }
    end
    site.define_singleton_method(:documents) { docs }
    site.define_singleton_method(:pages) { pgs }
    site
  end

  def write_source_and_md(source_file, dest_html, md_content)
    # Write source file so skip logic passes
    source_path = File.join(@source_dir, source_file)
    FileUtils.mkdir_p(File.dirname(source_path))
    File.write(source_path, "---\ntitle: Test\n---\nContent\n")

    # Write the .md output file at clean-style path (default)
    clean_md = dest_html.sub(%r{/index\.html\z}, ".md").sub(/\.html\z/, ".md")
    md_path = File.join(@dest_dir, clean_md)
    FileUtils.mkdir_p(File.dirname(md_path))
    File.write(md_path, md_content)
  end

  def test_generates_llms_txt_with_clean_links
    write_source_and_md("_pages/about.md", "about/index.html", "# About\n\nAbout content.\n")

    doc = mock_document(
      title: "About", description: "About us", url: "/about/",
      collection_label: "pages", source_file: "_pages/about.md",
      dest_html: "about/index.html"
    )

    site = mock_site(documents: [doc])
    JekyllAeo::Generators::LlmsTxt.generate(site)

    llms_path = File.join(@dest_dir, "llms.txt")
    assert File.exist?(llms_path), "llms.txt should be created"

    content = File.read(llms_path)
    assert content.start_with?("# Test Site\n")
    assert_includes content, "> A test site"
    assert_includes content, "## Pages"
    assert_includes content, "- [About](/about.md): About us"
  end

  def test_generates_llms_full_txt
    write_source_and_md("_pages/about.md", "about/index.html", "# About\n\nAbout content.\n")

    doc = mock_document(
      title: "About", description: "", url: "/about/",
      collection_label: "pages", source_file: "_pages/about.md",
      dest_html: "about/index.html"
    )

    site = mock_site(documents: [doc])
    JekyllAeo::Generators::LlmsTxt.generate(site)

    full_path = File.join(@dest_dir, "llms-full.txt")
    assert File.exist?(full_path), "llms-full.txt should be created"

    content = File.read(full_path)
    assert content.start_with?("# Test Site\n")
    assert_includes content, "---"
    assert_includes content, "About content."
  end

  def test_auto_sections_grouped_by_collection
    write_source_and_md("_pages/home.md", "index.html", "# Home\n")
    write_source_and_md("_products/widget.md", "products/widget/index.html", "# Widget\n")

    doc1 = mock_document(
      title: "Home", url: "/", collection_label: "pages",
      source_file: "_pages/home.md", dest_html: "index.html"
    )
    doc2 = mock_document(
      title: "Widget", url: "/products/widget/", collection_label: "products",
      source_file: "_products/widget.md", dest_html: "products/widget/index.html"
    )

    site = mock_site(documents: [doc1, doc2])
    JekyllAeo::Generators::LlmsTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms.txt"))
    assert_includes content, "## Pages"
    assert_includes content, "## Products"
  end

  def test_custom_sections_from_config
    write_source_and_md("_pages/home.md", "index.html", "# Home\n")

    doc = mock_document(
      title: "Home", url: "/", collection_label: "pages",
      source_file: "_pages/home.md", dest_html: "index.html"
    )

    source = @source_dir
    dest = @dest_dir
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      {
        "title" => "Test Site",
        "description" => "A test site",
        "jekyll_aeo" => {
          "llms_txt" => {
            "sections" => [
              { "title" => "Main Pages", "collection" => "pages" }
            ]
          }
        }
      }
    end
    site.define_singleton_method(:documents) { [doc] }
    site.define_singleton_method(:pages) { [] }

    JekyllAeo::Generators::LlmsTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms.txt"))
    assert_includes content, "## Main Pages"
  end

  def test_description_override_in_config
    source = @source_dir
    dest = @dest_dir
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      {
        "title" => "Test Site",
        "description" => "Original",
        "jekyll_aeo" => {
          "llms_txt" => { "description" => "Custom override" }
        }
      }
    end
    site.define_singleton_method(:documents) { [] }
    site.define_singleton_method(:pages) { [] }

    JekyllAeo::Generators::LlmsTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms.txt"))
    assert_includes content, "> Custom override"
    refute_includes content, "Original"
  end

  def test_disabled_via_master_switch
    source = @source_dir
    dest = @dest_dir
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      { "title" => "Test", "jekyll_aeo" => { "enabled" => false } }
    end
    site.define_singleton_method(:documents) { [] }
    site.define_singleton_method(:pages) { [] }

    JekyllAeo::Generators::LlmsTxt.generate(site)

    refute File.exist?(File.join(@dest_dir, "llms.txt"))
  end

  def test_disabled_via_llms_txt_switch
    source = @source_dir
    dest = @dest_dir
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      { "title" => "Test", "jekyll_aeo" => { "llms_txt" => { "enabled" => false } } }
    end
    site.define_singleton_method(:documents) { [] }
    site.define_singleton_method(:pages) { [] }

    JekyllAeo::Generators::LlmsTxt.generate(site)

    refute File.exist?(File.join(@dest_dir, "llms.txt"))
  end

  def test_full_txt_mode_linked
    write_source_and_md("_pages/home.md", "index.html", "# Home\n\nHome content.\n")
    write_source_and_md("_pages/extra.md", "extra/index.html", "# Extra\n\nExtra content.\n")

    doc1 = mock_document(
      title: "Home", url: "/", collection_label: "pages",
      source_file: "_pages/home.md", dest_html: "index.html"
    )
    doc2 = mock_document(
      title: "Extra", url: "/extra/", collection_label: "pages",
      source_file: "_pages/extra.md", dest_html: "extra/index.html"
    )

    source = @source_dir
    dest = @dest_dir
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      {
        "title" => "Test",
        "description" => "Desc",
        "jekyll_aeo" => {
          "llms_txt" => {
            "full_txt_mode" => "linked",
            "sections" => [
              { "title" => "Main", "collection" => "pages" }
            ]
          }
        }
      }
    end
    site.define_singleton_method(:documents) { [doc1, doc2] }
    site.define_singleton_method(:pages) { [] }

    JekyllAeo::Generators::LlmsTxt.generate(site)

    full_content = File.read(File.join(@dest_dir, "llms-full.txt"))
    assert_includes full_content, "Home content."
    assert_includes full_content, "Extra content."
  end

  def test_empty_site
    site = mock_site
    JekyllAeo::Generators::LlmsTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms.txt"))
    assert content.start_with?("# Test Site\n")
  end

  def test_standalone_pages_in_pages_section
    write_source_and_md("about.md", "about/index.html", "# About\n")

    page = mock_page(
      title: "About", url: "/about/",
      source_file: "about.md", dest_html: "about/index.html"
    )

    site = mock_site(pages: [page])
    JekyllAeo::Generators::LlmsTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms.txt"))
    assert_includes content, "## Pages"
    assert_includes content, "[About]"
  end
end
