# frozen_string_literal: true

require "test_helper"

class MdUrlTest < Minitest::Test
  # --- URL generation ---

  def test_root_url
    assert_equal "/index.md", JekyllAeo::Utils::MdUrl.for("/")
  end

  def test_pretty_url
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/")
  end

  def test_nested_pretty_url
    assert_equal "/blog/post.md", JekyllAeo::Utils::MdUrl.for("/blog/post/")
  end

  def test_html_url
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about.html")
  end

  def test_nested_html_url
    assert_equal "/blog/post.md", JekyllAeo::Utils::MdUrl.for("/blog/post.html")
  end

  def test_404_html
    assert_equal "/404.md", JekyllAeo::Utils::MdUrl.for("/404.html")
  end

  def test_non_html_extension
    assert_equal "/feed.xml.md", JekyllAeo::Utils::MdUrl.for("/feed.xml")
  end

  def test_no_extension
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about")
  end

  # --- Baseurl ---

  def test_baseurl_prepended
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about/", "/docs")
  end

  def test_baseurl_nil_handled
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/", nil)
  end

  def test_baseurl_trailing_slash_normalized
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about/", "/docs/")
  end

  def test_baseurl_empty_string
    assert_equal "/about.md", JekyllAeo::Utils::MdUrl.for("/about/", "")
  end

  def test_baseurl_with_html_url
    assert_equal "/docs/about.md", JekyllAeo::Utils::MdUrl.for("/about.html", "/docs")
  end

  # --- dest_path ---

  def test_dest_path_pretty
    obj = Object.new
    obj.define_singleton_method(:destination) { |dest| File.join(dest, "about", "index.html") }

    site = Object.new
    site.define_singleton_method(:dest) { "/site" }

    assert_equal "/site/about.md", JekyllAeo::Utils::MdUrl.dest_path(obj, site)
  end

  def test_dest_path_html
    obj = Object.new
    obj.define_singleton_method(:destination) { |dest| File.join(dest, "about.html") }

    site = Object.new
    site.define_singleton_method(:dest) { "/site" }

    assert_equal "/site/about.md", JekyllAeo::Utils::MdUrl.dest_path(obj, site)
  end
end
