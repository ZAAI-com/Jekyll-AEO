# frozen_string_literal: true

require "test_helper"

class SkipLogicTest < Minitest::Test
  def default_config
    JekyllAeo::Config::DEFAULTS
  end

  def mock_site(source: "/src", dest: "/dest")
    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) { {} }
    site
  end

  def mock_obj(data: {}, output_ext: ".html", url: "/page/", dest_path: "/dest/page/index.html",
               collection_label: nil, path: "/src/page.md", relative_path: "page.md")
    obj = Object.new
    obj.define_singleton_method(:data) { data }
    obj.define_singleton_method(:output_ext) { output_ext }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:destination) { |_| dest_path }
    obj.define_singleton_method(:relative_path) { relative_path }

    if collection_label
      collection = Object.new
      collection.define_singleton_method(:label) { collection_label }
      obj.define_singleton_method(:collection) { collection }
      obj.define_singleton_method(:path) { path }
    end

    obj
  end

  def test_normal_html_page_not_skipped
    obj = mock_obj(relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::SkipLogic.skip?(obj, site, default_config)
  end

  def test_skip_when_plugin_disabled
    config = default_config.merge("enabled" => false)
    assert JekyllAeo::Utils::SkipLogic.skip?(mock_obj, mock_site, config)
  end

  def test_skip_non_html_output
    obj = mock_obj(output_ext: ".css")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_markdown_copy_false
    obj = mock_obj(data: { "markdown_copy" => false })
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_redirect_page
    obj = mock_obj(data: { "redirect_to" => "/other/" })
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_assets_collection
    obj = mock_obj(collection_label: "assets")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_llms_txt_file
    obj = mock_obj(dest_path: "/dest/llms.txt")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_llms_full_txt_file
    obj = mock_obj(dest_path: "/dest/llms-full.txt")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_excluded_path
    config = default_config.merge("exclude" => ["/privacy/"])
    obj = mock_obj(url: "/privacy/policy/")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, config)
  end

  def test_skip_when_no_source_file
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_resolve_source_path_for_document
    site = mock_site(source: "/src")
    collection = Object.new
    collection.define_singleton_method(:label) { "pages" }

    obj = Object.new
    obj.define_singleton_method(:collection) { collection }
    obj.define_singleton_method(:path) { "/src/_pages/about.md" }

    assert_equal "/src/_pages/about.md", JekyllAeo::Utils::SkipLogic.resolve_source_path(obj, site)
  end

  def test_resolve_source_path_for_page
    site = mock_site(source: "/src")
    obj = Object.new
    obj.define_singleton_method(:relative_path) { "about.md" }

    assert_equal "/src/about.md", JekyllAeo::Utils::SkipLogic.resolve_source_path(obj, site)
  end

  # --- skip_reason tests ---

  def test_skip_reason_returns_nil_for_normal_page
    obj = mock_obj(relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))
    assert_nil JekyllAeo::Utils::SkipLogic.skip_reason(obj, site, default_config)
  end

  def test_skip_reason_plugin_disabled
    config = default_config.merge("enabled" => false)
    reason = JekyllAeo::Utils::SkipLogic.skip_reason(mock_obj, mock_site, config)
    assert_equal "plugin disabled", reason
  end

  def test_skip_reason_non_html
    obj = mock_obj(output_ext: ".css")
    reason = JekyllAeo::Utils::SkipLogic.skip_reason(obj, mock_site, default_config)
    assert_equal "non-HTML output", reason
  end

  def test_skip_reason_redirect
    obj = mock_obj(data: { "redirect_to" => "/other/" })
    reason = JekyllAeo::Utils::SkipLogic.skip_reason(obj, mock_site, default_config)
    assert_equal "redirect", reason
  end

  def test_skip_reason_excluded
    config = default_config.merge("exclude" => ["/privacy/"])
    obj = mock_obj(url: "/privacy/policy/")
    reason = JekyllAeo::Utils::SkipLogic.skip_reason(obj, mock_site, config)
    assert_equal "excluded", reason
  end

  def test_skip_reason_assets_collection
    obj = mock_obj(collection_label: "assets")
    reason = JekyllAeo::Utils::SkipLogic.skip_reason(obj, mock_site, default_config)
    assert_equal "assets collection", reason
  end

  # --- html2dotmd tests ---

  def test_no_source_file_not_skipped_with_html2dotmd
    html2dotmd = default_config["dotmd"]["html2dotmd"].merge("enabled" => true)
    dotmd = default_config["dotmd"].merge("html2dotmd" => html2dotmd)
    config = default_config.merge("dotmd" => dotmd)
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")
    refute JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, config)
  end

  def test_no_source_file_still_skipped_without_html2dotmd
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")
    assert JekyllAeo::Utils::SkipLogic.skip?(obj, mock_site, default_config)
  end

  def test_skip_reason_nil_with_html2dotmd_and_no_source
    html2dotmd = default_config["dotmd"]["html2dotmd"].merge("enabled" => true)
    dotmd = default_config["dotmd"].merge("html2dotmd" => html2dotmd)
    config = default_config.merge("dotmd" => dotmd)
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")
    assert_nil JekyllAeo::Utils::SkipLogic.skip_reason(obj, mock_site, config)
  end

  def test_no_false_positive_for_similar_filename
    obj = mock_obj(dest_path: "/dest/about-llms.txt", relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))
    refute JekyllAeo::Utils::SkipLogic.skip?(obj, site, default_config),
           "about-llms.txt should not be treated as an llms file"
  end
end
