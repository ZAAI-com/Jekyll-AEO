# frozen_string_literal: true

require "test_helper"

class MdUrlTest < Minitest::Test
  def clean_config
    { "md_path_style" => "clean" }
  end

  def spec_config
    { "md_path_style" => "spec" }
  end

  # --- Clean mode ---

  def test_clean_root_url
    assert_equal "/index.md", JekyllAeo::Utils::MdUrl.for("/", clean_config)
  end

  def test_clean_pretty_url
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/", clean_config)
  end

  def test_clean_nested_pretty_url
    assert_equal "/blog/post.md", JekyllAeo::Utils::MdUrl.for("/blog/post/", clean_config)
  end

  def test_clean_html_url
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about.html", clean_config)
  end

  def test_clean_nested_html_url
    assert_equal "/blog/post.md", JekyllAeo::Utils::MdUrl.for("/blog/post.html", clean_config)
  end

  def test_clean_404_html
    assert_equal "/404.md", JekyllAeo::Utils::MdUrl.for("/404.html", clean_config)
  end

  def test_clean_non_html_extension
    assert_equal "/feed.xml.md", JekyllAeo::Utils::MdUrl.for("/feed.xml", clean_config)
  end

  def test_clean_no_extension
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about", clean_config)
  end

  # --- Spec mode ---

  def test_spec_trailing_slash
    assert_equal "/about/index.html.md", JekyllAeo::Utils::MdUrl.for("/about/", spec_config)
  end

  def test_spec_no_trailing_slash
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about", spec_config)
  end

  def test_spec_html_url
    assert_equal "/about.html.md", JekyllAeo::Utils::MdUrl.for("/about.html", spec_config)
  end

  def test_spec_root
    assert_equal "/index.html.md", JekyllAeo::Utils::MdUrl.for("/", spec_config)
  end

  # --- Baseurl ---

  def test_baseurl_prepended
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about/", clean_config, "/docs")
  end

  def test_baseurl_nil_handled
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/", clean_config, nil)
  end

  def test_baseurl_trailing_slash_normalized
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about/", clean_config, "/docs/")
  end

  def test_baseurl_empty_string
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/", clean_config, "")
  end

  def test_baseurl_with_html_url
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about.html", clean_config, "/docs")
  end

  # --- dest_path ---

  def test_dest_path_clean_pretty
    obj = Object.new
    obj.define_singleton_method(:destination) { |dest| File.join(dest, "about", "index.html") }

    site = Object.new
    site.define_singleton_method(:dest) { "/site" }

    assert_equal "/site/about.md", JekyllAeo::Utils::MdUrl.dest_path(obj, site, clean_config)
  end

  def test_dest_path_clean_html
    obj = Object.new
    obj.define_singleton_method(:destination) { |dest| File.join(dest, "about.html") }

    site = Object.new
    site.define_singleton_method(:dest) { "/site" }

    assert_equal "/site/about.md", JekyllAeo::Utils::MdUrl.dest_path(obj, site, clean_config)
  end

  def test_dest_path_spec
    obj = Object.new
    obj.define_singleton_method(:destination) { |dest| File.join(dest, "about", "index.html") }

    site = Object.new
    site.define_singleton_method(:dest) { "/site" }

    assert_equal "/site/about/index.html.md", JekyllAeo::Utils::MdUrl.dest_path(obj, site, spec_config)
  end
end
