# frozen_string_literal: true

require "test_helper"

class BreadcrumbListSchemaTest < Minitest::Test
  def test_returns_nil_for_homepage
    result = JekyllAeo::Schema::BreadcrumbList.build({ "url" => "/" }, {})
    assert_nil result
  end

  def test_returns_nil_when_no_url
    result = JekyllAeo::Schema::BreadcrumbList.build({}, {})
    assert_nil result
  end

  def test_builds_breadcrumbs_for_simple_url
    page = { "url" => "/about/", "title" => "About Us" }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, config)

    assert_equal "https://schema.org", result["@context"]
    assert_equal "BreadcrumbList", result["@type"]
    assert_equal 2, result["itemListElement"].length

    home = result["itemListElement"][0]
    assert_equal 1, home["position"]
    assert_equal "Home", home["name"]
    assert_equal "https://example.com/", home["item"]

    about = result["itemListElement"][1]
    assert_equal 2, about["position"]
    assert_equal "About Us", about["name"]
    assert_equal "https://example.com/about/", about["item"]
  end

  def test_builds_breadcrumbs_for_nested_url
    page = { "url" => "/products/widgets/blue/", "title" => "Blue Widget" }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, config)

    assert_equal 4, result["itemListElement"].length

    items = result["itemListElement"]
    assert_equal "Home", items[0]["name"]
    assert_equal "Products", items[1]["name"]
    assert_equal "Widgets", items[2]["name"]
    assert_equal "Blue Widget", items[3]["name"]
  end

  def test_uses_page_title_for_last_segment
    page = { "url" => "/docs/setup/", "title" => "Getting Started" }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, config)

    last = result["itemListElement"].last
    assert_equal "Getting Started", last["name"]
  end

  def test_titleizes_intermediate_segments
    page = { "url" => "/user-guide/advanced-features/", "title" => "Advanced" }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, config)

    mid = result["itemListElement"][1]
    assert_equal "User Guide", mid["name"]
  end

  def test_respects_baseurl
    page = { "url" => "/about/", "title" => "About" }
    config = { "url" => "https://example.com", "baseurl" => "/blog" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, config)

    home = result["itemListElement"][0]
    assert_equal "https://example.com/blog/", home["item"]

    about = result["itemListElement"][1]
    assert_equal "https://example.com/blog/about/", about["item"]
  end

  def test_positions_are_sequential
    page = { "url" => "/a/b/c/" }
    result = JekyllAeo::Schema::BreadcrumbList.build(page, {})

    positions = result["itemListElement"].map { |i| i["position"] }
    assert_equal [1, 2, 3, 4], positions
  end
end
