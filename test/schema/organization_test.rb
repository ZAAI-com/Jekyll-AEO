# frozen_string_literal: true

require "test_helper"

class OrganizationSchemaTest < Minitest::Test
  def test_returns_nil_for_non_homepage
    result = JekyllAeo::Schema::Organization.build(
      { "url" => "/about/" },
      { "title" => "My Site" }
    )

    assert_nil result
  end

  def test_returns_nil_when_no_site_name
    result = JekyllAeo::Schema::Organization.build({ "url" => "/" }, {})

    assert_nil result
  end

  def test_builds_organization_schema_for_homepage
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "ZAAI" }
    result = JekyllAeo::Schema::Organization.build(page, config)

    assert_equal "https://schema.org", result["@context"]
    assert_equal "Organization", result["@type"]
    assert_equal "ZAAI", result["name"]
    assert_equal "https://example.com", result["url"]
  end

  def test_includes_description_when_present
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "ZAAI", "description" => "AI company" }
    result = JekyllAeo::Schema::Organization.build(page, config)

    assert_equal "AI company", result["description"]
  end

  def test_omits_description_when_empty
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "ZAAI", "description" => "" }
    result = JekyllAeo::Schema::Organization.build(page, config)

    refute result.key?("description")
  end

  def test_includes_logo_from_domain_profile
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "ZAAI" }
    aeo_config = { "domain_profile" => { "logo" => "https://example.com/logo.png" } }
    result = JekyllAeo::Schema::Organization.build(page, config, aeo_config)

    assert_equal "https://example.com/logo.png", result["logo"]
  end

  def test_includes_same_as_from_domain_profile
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "ZAAI" }
    aeo_config = {
      "domain_profile" => {
        "jsonld" => { "sameAs" => ["https://github.com/zaai", "https://twitter.com/zaai"] }
      }
    }
    result = JekyllAeo::Schema::Organization.build(page, config, aeo_config)

    assert_equal ["https://github.com/zaai", "https://twitter.com/zaai"], result["sameAs"]
  end

  def test_uses_name_config_as_fallback
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "name" => "Fallback Name" }
    result = JekyllAeo::Schema::Organization.build(page, config)

    assert_equal "Fallback Name", result["name"]
  end

  def test_url_fallback_when_empty
    page = { "url" => "/" }
    config = { "title" => "ZAAI" }
    result = JekyllAeo::Schema::Organization.build(page, config)

    assert_equal "/", result["url"]
  end
end
