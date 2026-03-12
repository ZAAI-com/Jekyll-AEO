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
    assert_equal "clean", config["md_path_style"]
    assert_equal true, config["strip_block_tags"]
    assert_equal false, config["protect_indented_code"]
    assert_equal "auto", config["link_tag"]
    assert_equal [], config["exclude"]
    assert_equal [], config["include"]
    assert_equal false, config["html_fallback"]
    assert_equal true, config["llms_txt"]["enabled"]
    assert_nil config["llms_txt"]["description"]
    assert_equal "all", config["llms_txt"]["full_txt_mode"]
    assert_nil config["llms_txt"]["sections"]
    assert_equal [], config["llms_txt"]["front_matter_keys"]
    assert_equal false, config["llms_txt"]["show_lastmod"]
  end

  def test_user_overrides_top_level
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "enabled" => false,
                                                     "strip_block_tags" => false,
                                                     "protect_indented_code" => true,
                                                     "exclude" => ["/privacy/"]
                                                   }))

    assert_equal false, config["enabled"]
    assert_equal false, config["strip_block_tags"]
    assert_equal true, config["protect_indented_code"]
    assert_equal ["/privacy/"], config["exclude"]
  end

  def test_deep_merge_llms_txt
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "llms_txt" => {
                                                       "description" => "Custom description",
                                                       "full_txt_mode" => "linked"
                                                     }
                                                   }))

    assert_equal "Custom description", config["llms_txt"]["description"]
    assert_equal "linked", config["llms_txt"]["full_txt_mode"]
    # Defaults preserved for unset keys
    assert_equal true, config["llms_txt"]["enabled"]
    assert_nil config["llms_txt"]["sections"]
  end

  def test_deep_merge_preserves_defaults_for_missing_keys
    config = JekyllAeo::Config.from_site(mock_site({
                                                     "llms_txt" => { "enabled" => false }
                                                   }))

    assert_equal false, config["llms_txt"]["enabled"]
    assert_equal "all", config["llms_txt"]["full_txt_mode"]
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
end
