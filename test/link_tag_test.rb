# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class LinkTagTest < Minitest::Test
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

  def mock_page(url: "/about/", source_file: "about.md")
    data = { "title" => "About" }
    dest = File.join(@dest_dir, "about", "index.html")
    rel_path = source_file
    output = "<html><head><title>About</title></head><body>Hello</body></html>"

    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { ".html" }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| dest }
    obj.define_singleton_method(:relative_path) { rel_path }
    obj.define_singleton_method(:output) { output }
    obj.define_singleton_method(:output=) do |val|
      output = val
      obj.define_singleton_method(:output) { output }
    end
    obj
  end

  def write_source(filename, content = "")
    File.write(File.join(@source_dir, filename), content)
  end

  # --- auto mode ---

  def test_auto_injects_link_tag_before_head_close
    write_source("about.md")
    page = mock_page
    site = mock_site
    JekyllAeo::LinkTag.inject(page, site)

    assert_includes page.output, '<link rel="alternate" type="text/markdown" href="/about.md">'
    assert_includes page.output, %(<link rel="alternate" type="text/markdown" href="/about.md">\n</head>)
  end

  def test_auto_uses_spec_path_style
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "md_path_style" => "spec" })
    JekyllAeo::LinkTag.inject(page, site)

    assert_includes page.output, '<link rel="alternate" type="text/markdown" href="/about/index.html.md">'
  end

  def test_auto_includes_baseurl
    write_source("about.md")
    page = mock_page
    site = mock_site("baseurl" => "/blog")
    JekyllAeo::LinkTag.inject(page, site)

    assert_includes page.output, '<link rel="alternate" type="text/markdown" href="/blog/about.md">'
  end

  def test_auto_skips_when_mode_is_data
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => "data" })
    original_output = page.output
    JekyllAeo::LinkTag.inject(page, site)

    assert_equal original_output, page.output
  end

  def test_auto_skips_when_mode_is_false
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => false })
    original_output = page.output
    JekyllAeo::LinkTag.inject(page, site)

    assert_equal original_output, page.output
  end

  def test_auto_skips_no_head_tag
    write_source("about.md")
    page = mock_page
    page.output = "<html><body>No head here</body></html>"
    site = mock_site
    JekyllAeo::LinkTag.inject(page, site)

    refute_includes page.output, "link rel"
  end

  def test_auto_skips_non_html
    page = mock_page
    page.define_singleton_method(:output_ext) { ".css" }
    site = mock_site
    original_output = page.output
    JekyllAeo::LinkTag.inject(page, site)

    assert_equal original_output, page.output
  end

  # --- data mode ---

  def test_data_sets_md_url
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => "data" })
    JekyllAeo::LinkTag.set_data(page, site)

    assert_equal "/about.md", page.data["md_url"]
  end

  def test_data_sets_md_link_tag
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => "data" })
    JekyllAeo::LinkTag.set_data(page, site)

    assert_equal '<link rel="alternate" type="text/markdown" href="/about.md">', page.data["md_link_tag"]
  end

  def test_data_includes_baseurl
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => "data" }, "baseurl" => "/blog")
    JekyllAeo::LinkTag.set_data(page, site)

    assert_equal "/blog/about.md", page.data["md_url"]
    assert_includes page.data["md_link_tag"], "/blog/about.md"
  end

  def test_data_uses_spec_path_style
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => "data", "md_path_style" => "spec" })
    JekyllAeo::LinkTag.set_data(page, site)

    assert_equal "/about/index.html.md", page.data["md_url"]
  end

  def test_data_skips_when_mode_is_auto
    write_source("about.md")
    page = mock_page
    site = mock_site
    JekyllAeo::LinkTag.set_data(page, site)

    assert_nil page.data["md_url"]
    assert_nil page.data["md_link_tag"]
  end

  def test_data_skips_when_mode_is_false
    write_source("about.md")
    page = mock_page
    site = mock_site("jekyll_aeo" => { "link_tag" => false })
    JekyllAeo::LinkTag.set_data(page, site)

    assert_nil page.data["md_url"]
  end

  # --- root page ---

  def test_auto_root_page
    write_source("index.md")
    page = mock_page(url: "/", source_file: "index.md")
    dest_dir = @dest_dir
    page.define_singleton_method(:destination) { |_| File.join(dest_dir, "index.html") }
    site = mock_site
    JekyllAeo::LinkTag.inject(page, site)

    assert_includes page.output, 'href="/index.md"'
  end
end
