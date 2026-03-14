# frozen_string_literal: true

require "test_helper"

class ArticleSchemaTest < Minitest::Test
  def test_returns_nil_when_no_date
    result = JekyllAeo::Schema::Article.build({ "title" => "Post" }, {})

    assert_nil result
  end

  def test_builds_article_schema
    page = {
      "title" => "My Post",
      "date" => Time.new(2025, 6, 15, 12, 0, 0),
      "url" => "/blog/my-post/"
    }
    config = { "url" => "https://example.com" }
    result = JekyllAeo::Schema::Article.build(page, config)

    assert_equal "https://schema.org", result["@context"]
    assert_equal "Article", result["@type"]
    assert_equal "My Post", result["headline"]
    assert_equal "https://example.com/blog/my-post/", result["url"]
    assert_includes result["datePublished"], "2025-06-15"
  end

  def test_includes_author_when_present
    page = {
      "title" => "Post",
      "date" => "2025-06-15",
      "url" => "/post/",
      "author" => "Manuel Gruber"
    }
    result = JekyllAeo::Schema::Article.build(page, {})

    assert_equal "Person", result["author"]["@type"]
    assert_equal "Manuel Gruber", result["author"]["name"]
  end

  def test_omits_author_when_absent
    page = { "title" => "Post", "date" => "2025-06-15", "url" => "/post/" }
    result = JekyllAeo::Schema::Article.build(page, {})

    refute result.key?("author")
  end

  def test_includes_description
    page = {
      "title" => "Post",
      "date" => "2025-06-15",
      "url" => "/post/",
      "description" => "A great post"
    }
    result = JekyllAeo::Schema::Article.build(page, {})

    assert_equal "A great post", result["description"]
  end

  def test_includes_date_modified
    page = {
      "title" => "Post",
      "date" => "2025-06-15",
      "url" => "/post/",
      "last_modified_at" => Time.new(2025, 7, 1, 12, 0, 0)
    }
    result = JekyllAeo::Schema::Article.build(page, {})

    assert_includes result["dateModified"], "2025-07-01"
  end

  def test_skips_when_seo_tag_present
    # Register a fake "seo" tag to simulate jekyll-seo-tag
    Liquid::Template.register_tag("seo", Class.new(Liquid::Tag))

    page = { "title" => "Post", "date" => "2025-06-15", "url" => "/post/" }
    result = JekyllAeo::Schema::Article.build(page, {})

    assert_nil result
  ensure
    # Clean up the fake tag
    Liquid::Template.tags.delete("seo")
  end

  def test_builds_when_seo_tag_absent
    Liquid::Template.tags.delete("seo")

    page = { "title" => "Post", "date" => "2025-06-15", "url" => "/post/" }
    result = JekyllAeo::Schema::Article.build(page, {})

    refute_nil result
    assert_equal "Article", result["@type"]
  end

  def test_respects_baseurl
    page = { "title" => "Post", "date" => "2025-06-15", "url" => "/post/" }
    config = { "url" => "https://example.com", "baseurl" => "/blog" }
    result = JekyllAeo::Schema::Article.build(page, config)

    assert_equal "https://example.com/blog/post/", result["url"]
  end
end
