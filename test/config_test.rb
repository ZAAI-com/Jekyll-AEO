# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def mock_site(user_config = {})
    site = Minitest::Mock.new
    site.expect(:config, { "jekyll_aeo" => user_config })
    site
  end

  def mock_site_no_config
    site = Minitest::Mock.new
    site.expect(:config, {})
    site
  end

  def test_defaults_when_no_config
    config = JekyllAeo::Config.from_site(mock_site_no_config)

    assert_equal true, config["enabled"]
    assert_equal [], config["exclude"]
    assert_equal "auto", config["dotmd"]["link_tag"]
    assert_equal true, config["dotmd"]["md2dotmd"]["strip_block_tags"]
    assert_equal false, config["dotmd"]["md2dotmd"]["protect_indented_code"]
    assert_equal true, config["dotmd"]["include_last_modified"]
    assert_equal false, config["dotmd"]["dotmd_metadata"]
    assert_equal false, config["dotmd"]["html2dotmd"]["enabled"]
    assert_equal true, config["llms_txt"]["enabled"]
    assert_nil config["llms_txt"]["description"]
    assert_nil config["llms_txt"]["sections"]
    assert_equal [], config["llms_txt"]["front_matter_keys"]
    assert_equal false, config["llms_txt"]["show_lastmod"]
    assert_equal true, config["llms_txt"]["include_descriptions"]
    assert_equal true, config["llms_full_txt"]["enabled"]
    assert_nil config["llms_full_txt"]["description"]
    assert_equal "all", config["llms_full_txt"]["full_txt_mode"]
    assert_equal false, config["robots_txt"]["enabled"]
    assert_equal %w[GPTBot ClaudeBot Google-Extended Meta-ExternalAgent Amazonbot], config["robots_txt"]["disallow"]
    assert_equal true, config["robots_txt"]["include_sitemap"]
    assert_equal true, config["robots_txt"]["include_llms_txt"]
    assert_equal [], config["robots_txt"]["custom_rules"]
  end

  def test_user_overrides_top_level
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "enabled" => false,
                                                     "exclude" => ["/privacy/"],
                                                     "dotmd" => {
                                                       "md2dotmd" => {
                                                         "strip_block_tags" => false,
                                                         "protect_indented_code" => true
                                                       }
                                                     }
                                                   }))

    assert_equal false, config["enabled"]
    assert_equal ["/privacy/"], config["exclude"]
    assert_equal false, config["dotmd"]["md2dotmd"]["strip_block_tags"]
    assert_equal true, config["dotmd"]["md2dotmd"]["protect_indented_code"]
  end

  def test_deep_merge_llms_txt
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "llms_txt" => {
                                                       "description" => "Custom description"
                                                     }
                                                   }))

    assert_equal "Custom description", config["llms_txt"]["description"]
    # Defaults preserved for unset keys
    assert_equal true, config["llms_txt"]["enabled"]
    assert_nil config["llms_txt"]["sections"]
  end

  def test_deep_merge_llms_full_txt
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "llms_full_txt" => {
                                                       "full_txt_mode" => "linked"
                                                     }
                                                   }))

    assert_equal "linked", config["llms_full_txt"]["full_txt_mode"]
    assert_equal true, config["llms_full_txt"]["enabled"]
    assert_nil config["llms_full_txt"]["description"]
  end

  def test_deep_merge_preserves_defaults_for_missing_keys
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "llms_txt" => { "enabled" => false }
                                                   }))

    assert_equal false, config["llms_txt"]["enabled"]
    assert_equal "all", config["llms_full_txt"]["full_txt_mode"]
  end

  def test_enabled_false_propagated
    config = JekyllAeo::Config.from_site(mock_site({ "enabled" => false }))
    assert_equal false, config["enabled"]
  end

  def test_defaults_include_url_map
    config = JekyllAeo::Config.from_site(mock_site_no_config)
    assert_equal false, config["url_map"]["enabled"]
    assert_equal "docs/Url-Map.md", config["url_map"]["output_filepath"]
    assert_equal %w[page_id url lang layout path redirects markdown_copy skipped], config["url_map"]["columns"]
  end

  def test_deep_merge_url_map
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "url_map" => { "enabled" => true, "columns" => %w[url path] }
                                                   }))
    assert_equal true, config["url_map"]["enabled"]
    assert_equal %w[url path], config["url_map"]["columns"]
    assert_equal "docs/Url-Map.md", config["url_map"]["output_filepath"]
  end

  def test_deep_merge_drops_unknown_keys
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "bogus_key" => "should be dropped",
                                                     "llms_txt" => {
                                                       "enabled" => true,
                                                       "unknown_nested" => "also dropped"
                                                     }
                                                   }))

    assert_nil config["bogus_key"], "Unknown top-level keys should be filtered out"
    assert_nil config["llms_txt"]["unknown_nested"], "Unknown nested keys should be filtered out"
    assert_equal true, config["llms_txt"]["enabled"]
  end
end
