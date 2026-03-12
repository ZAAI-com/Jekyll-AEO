# frozen_string_literal: true

require "test_helper"
require "json"

class AeoJsonLdTagTest < Minitest::Test
  def mock_site(config = {})
    site = Object.new
    site.define_singleton_method(:config) { config }
    site
  end

  def render_tag(page_data, site_config = {})
    context = Liquid::Context.new
    context.registers[:site] = mock_site(site_config)
    context.registers[:page] = page_data

    tag = JekyllAeo::Tags::AeoJsonLd.parse(
      "aeo_json_ld", "", Liquid::Tokenizer.new(""), Liquid::ParseContext.new
    )
    tag.render(context)
  end

  def test_renders_empty_for_page_with_no_schemas
    # Homepage with no faq/howto/speakable/date, but Organization will trigger
    # Use non-homepage to avoid Organization
    result = render_tag({ "url" => "/", "title" => nil })
    # No title means Organization returns nil, no date means no Article
    assert_equal "", result
  end

  def test_renders_faq_schema
    page = {
      "url" => "/",
      "faq" => [{ "q" => "What?", "a" => "This." }]
    }
    result = render_tag(page)

    assert_includes result, '<script type="application/ld+json">'
    assert_includes result, '"FAQPage"'
    assert_includes result, "What?"
  end

  def test_renders_breadcrumb_schema
    page = { "url" => "/about/", "title" => "About" }
    config = { "url" => "https://example.com" }
    result = render_tag(page, config)

    assert_includes result, '"BreadcrumbList"'
    assert_includes result, "About"
  end

  def test_renders_multiple_schemas
    page = {
      "url" => "/faq/",
      "title" => "FAQ",
      "faq" => [{ "q" => "Q1", "a" => "A1" }]
    }
    config = { "url" => "https://example.com" }
    result = render_tag(page, config)

    # Should have both FAQPage and BreadcrumbList
    assert_includes result, '"FAQPage"'
    assert_includes result, '"BreadcrumbList"'
  end

  def test_each_schema_is_separate_script_block
    page = {
      "url" => "/faq/",
      "title" => "FAQ",
      "faq" => [{ "q" => "Q1", "a" => "A1" }]
    }
    config = { "url" => "https://example.com" }
    result = render_tag(page, config)

    script_count = result.scan('<script type="application/ld+json">').length
    assert script_count >= 2, "Expected at least 2 script blocks, got #{script_count}"
  end

  def test_output_contains_valid_json
    page = {
      "url" => "/about/",
      "title" => "About",
      "faq" => [{ "q" => "Q?", "a" => "A." }]
    }
    config = { "url" => "https://example.com" }
    result = render_tag(page, config)

    # Extract JSON from script blocks
    json_blocks = result.scan(%r{<script type="application/ld\+json">\n(.*?)\n</script>}m)
    refute_empty json_blocks

    json_blocks.each do |block|
      parsed = JSON.parse(block.first)
      assert parsed.key?("@context"), "Each block should have @context"
      assert parsed.key?("@type"), "Each block should have @type"
    end
  end

  def test_renders_organization_on_homepage
    page = { "url" => "/" }
    config = { "url" => "https://example.com", "title" => "My Site" }
    result = render_tag(page, config)

    assert_includes result, '"Organization"'
    assert_includes result, "My Site"
  end

  def test_renders_speakable_when_enabled
    page = { "url" => "/page/", "title" => "Test", "speakable" => true }
    config = { "url" => "https://example.com" }
    result = render_tag(page, config)

    assert_includes result, '"SpeakableSpecification"'
  end

  def test_renders_howto_schema
    page = {
      "url" => "/guide/",
      "title" => "Setup Guide",
      "howto" => {
        "steps" => [{ "text" => "Install it" }, { "text" => "Run it" }]
      }
    }
    result = render_tag(page)

    assert_includes result, '"HowTo"'
    assert_includes result, "Install it"
  end
end
