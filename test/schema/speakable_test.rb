# frozen_string_literal: true

require "test_helper"

class SpeakableSchemaTest < Minitest::Test
  def test_returns_nil_when_speakable_not_set
    result = JekyllAeo::Schema::Speakable.build({}, {})

    assert_nil result
  end

  def test_returns_nil_when_speakable_false
    result = JekyllAeo::Schema::Speakable.build({ "speakable" => false }, {})

    assert_nil result
  end

  def test_builds_speakable_schema
    page = { "speakable" => true, "title" => "My Page", "url" => "/about/" }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::Speakable.build(page, config)

    assert_equal "https://schema.org", result["@context"]
    assert_equal "WebPage", result["@type"]
    assert_equal "My Page", result["name"]
    assert_equal "https://example.com/about/", result["url"]
  end

  def test_includes_css_selectors
    page = { "speakable" => true, "title" => "Test", "url" => "/" }
    result = JekyllAeo::Schema::Speakable.build(page, {})

    selectors = result["speakable"]["cssSelector"]

    assert_equal 2, selectors.length
    assert_includes selectors.first, "h1"
    assert_includes selectors.last, "p:first-of-type"
  end

  def test_speakable_specification_type
    page = { "speakable" => true, "title" => "Test", "url" => "/" }
    result = JekyllAeo::Schema::Speakable.build(page, {})

    assert_equal "SpeakableSpecification", result["speakable"]["@type"]
  end

  def test_respects_baseurl
    page = { "speakable" => true, "title" => "Test", "url" => "/page/" }
    config = { "url" => "https://example.com", "baseurl" => "/blog" }
    result = JekyllAeo::Schema::Speakable.build(page, config)

    assert_equal "https://example.com/blog/page/", result["url"]
  end

  def test_empty_title_fallback
    page = { "speakable" => true, "url" => "/" }
    result = JekyllAeo::Schema::Speakable.build(page, {})

    assert_equal "", result["name"]
  end
end
