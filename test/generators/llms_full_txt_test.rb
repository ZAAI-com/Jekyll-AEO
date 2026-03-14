# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class LlmsFullTxtTest < Minitest::Test
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

  def mock_document(title:, url:, collection_label:, source_file:, dest_html:, description: "")
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

  def mock_site(documents: [], pages: [], title: "Test Site", description: "A test site", baseurl: nil,
                jekyll_aeo: nil)
    source = @source_dir
    dest = @dest_dir
    docs = documents
    pgs = pages

    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) do
      cfg = { "title" => title, "description" => description }
      cfg["baseurl"] = baseurl if baseurl
      cfg["jekyll_aeo"] = jekyll_aeo if jekyll_aeo
      cfg
    end
    site.define_singleton_method(:documents) { docs }
    site.define_singleton_method(:pages) { pgs }
    site
  end

  def write_source_and_md(source_file, dest_html, md_content)
    source_path = File.join(@source_dir, source_file)
    FileUtils.mkdir_p(File.dirname(source_path))
    File.write(source_path, "---\ntitle: Test\n---\nContent\n")

    clean_md = dest_html.sub(%r{/index\.html\z}, ".md").sub(/\.html\z/, ".md")
    md_path = File.join(@dest_dir, clean_md)
    FileUtils.mkdir_p(File.dirname(md_path))
    File.write(md_path, md_content)
  end

  def test_generates_llms_full_txt
    write_source_and_md("_pages/about.md", "about/index.html", "# About\n\nAbout content.\n")

    doc = mock_document(
      title: "About", description: "", url: "/about/",
      collection_label: "pages", source_file: "_pages/about.md",
      dest_html: "about/index.html"
    )

    site = mock_site(documents: [doc])
    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    full_path = File.join(@dest_dir, "llms-full.txt")

    assert_path_exists full_path, "llms-full.txt should be created"

    content = File.read(full_path)

    assert content.start_with?("# Test Site\n")
    assert_includes content, "---"
    assert_includes content, "About content."
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

    site = mock_site(
      documents: [doc1, doc2],
      jekyll_aeo: {
        "llms_full_txt" => { "full_txt_mode" => "linked" },
        "llms_txt" => {
          "sections" => [
            { "title" => "Main", "collection" => "pages" }
          ]
        }
      }
    )

    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    full_content = File.read(File.join(@dest_dir, "llms-full.txt"))

    assert_includes full_content, "Home content."
    assert_includes full_content, "Extra content."
  end

  def test_disabled_via_master_switch
    site = mock_site(jekyll_aeo: { "enabled" => false })

    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    refute_path_exists File.join(@dest_dir, "llms-full.txt")
  end

  def test_disabled_via_llms_full_txt_switch
    site = mock_site(jekyll_aeo: { "llms_full_txt" => { "enabled" => false } })

    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    refute_path_exists File.join(@dest_dir, "llms-full.txt")
  end

  def test_description_override
    write_source_and_md("_pages/about.md", "about/index.html", "# About\n")

    doc = mock_document(
      title: "About", url: "/about/",
      collection_label: "pages", source_file: "_pages/about.md",
      dest_html: "about/index.html"
    )

    site = mock_site(
      documents: [doc],
      jekyll_aeo: { "llms_full_txt" => { "description" => "Custom full description" } }
    )

    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms-full.txt"))

    assert_includes content, "> Custom full description"
    refute_includes content, "A test site"
  end

  def test_uses_site_description_by_default
    site = mock_site
    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms-full.txt"))

    assert_includes content, "> A test site"
  end

  def test_empty_site
    site = mock_site
    JekyllAeo::Generators::LlmsFullTxt.generate(site)

    content = File.read(File.join(@dest_dir, "llms-full.txt"))

    assert content.start_with?("# Test Site\n")
  end
end
