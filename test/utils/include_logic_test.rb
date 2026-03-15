# frozen_string_literal: true

require "test_helper"

# rubocop:disable Minitest/AssertIncludes, Minitest/RefuteIncludes
class IncludeLogicTest < Minitest::Test
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

  def mock_static_file(url:, relative_path:)
    obj = Jekyll::StaticFile.allocate
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:relative_path) { relative_path }
    obj
  end

  def test_normal_html_page_included
    obj = mock_obj(relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, default_config)
  end

  def test_excluded_when_plugin_disabled
    config = default_config.merge("enabled" => false)

    refute JekyllAeo::Utils::IncludeLogic.include?(mock_obj, mock_site, config)
  end

  def test_excluded_non_html_output
    obj = mock_obj(output_ext: ".css")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_excluded_dotmd_mode_disabled
    obj = mock_obj(data: { "dotmd_mode" => "disabled" })

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_exclude_reason_dotmd_mode_disabled
    obj = mock_obj(data: { "dotmd_mode" => "disabled" })
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, default_config)

    assert_equal "dotmd_mode: disabled", reason
  end

  def test_excluded_redirect_page
    obj = mock_obj(data: { "redirect_to" => "/other/" })

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_excluded_static_file
    obj = mock_static_file(url: "/assets/style.css", relative_path: "_assets/style.css")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_excluded_llms_txt_file
    obj = mock_obj(dest_path: "/dest/llms.txt")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_excluded_llms_full_txt_file
    obj = mock_obj(dest_path: "/dest/llms-full.txt")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_excluded_path
    config = default_config.merge("exclude" => ["/privacy/"])
    obj = mock_obj(url: "/privacy/policy/")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, config)
  end

  def test_excluded_when_no_source_file
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_resolve_source_path_for_document
    site = mock_site(source: "/src")
    collection = Object.new
    collection.define_singleton_method(:label) { "pages" }

    obj = Object.new
    obj.define_singleton_method(:collection) { collection }
    obj.define_singleton_method(:path) { "/src/_pages/about.md" }

    assert_equal "/src/_pages/about.md", JekyllAeo::Utils::IncludeLogic.resolve_source_path(obj, site)
  end

  def test_resolve_source_path_for_page
    site = mock_site(source: "/src")
    obj = Object.new
    obj.define_singleton_method(:relative_path) { "about.md" }

    assert_equal "/src/about.md", JekyllAeo::Utils::IncludeLogic.resolve_source_path(obj, site)
  end

  # --- exclude_reason tests ---

  def test_exclude_reason_returns_nil_for_normal_page
    obj = mock_obj(relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert_nil JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, site, default_config)
  end

  def test_exclude_reason_plugin_disabled
    config = default_config.merge("enabled" => false)
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(mock_obj, mock_site, config)

    assert_equal "plugin disabled", reason
  end

  def test_exclude_reason_non_html
    obj = mock_obj(output_ext: ".css")
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, default_config)

    assert_equal "non-HTML output", reason
  end

  def test_exclude_reason_redirect
    obj = mock_obj(data: { "redirect_to" => "/other/" })
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, default_config)

    assert_equal "redirect", reason
  end

  def test_exclude_reason_excluded
    config = default_config.merge("exclude" => ["/privacy/"])
    obj = mock_obj(url: "/privacy/policy/")
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, config)

    assert_equal "excluded", reason
  end

  def test_exclude_reason_static_file
    obj = mock_static_file(url: "/assets/style.css", relative_path: "_assets/style.css")
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, default_config)

    assert_equal "static file", reason
  end

  # --- html2dotmd tests ---

  def test_no_source_file_included_with_html2dotmd
    html2dotmd = default_config["dotmd"]["html2dotmd"].merge("enabled" => true)
    dotmd = default_config["dotmd"].merge("html2dotmd" => html2dotmd)
    config = default_config.merge("dotmd" => dotmd)
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, config)
  end

  def test_no_source_file_still_excluded_without_html2dotmd
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, mock_site, default_config)
  end

  def test_exclude_reason_nil_with_html2dotmd_and_no_source
    html2dotmd = default_config["dotmd"]["html2dotmd"].merge("enabled" => true)
    dotmd = default_config["dotmd"].merge("html2dotmd" => html2dotmd)
    config = default_config.merge("dotmd" => dotmd)
    obj = mock_obj(relative_path: "nonexistent_file_xyz.md")

    assert_nil JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, config)
  end

  def test_static_file_excluded_before_output_ext_check
    # Jekyll::StaticFile lacks output_ext — must not crash
    obj = mock_static_file(url: "/assets/style.css", relative_path: "_assets/style.css")

    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, mock_site, default_config)

    assert_equal "static file", reason
  end

  def test_no_false_positive_for_similar_filename
    obj = mock_obj(dest_path: "/dest/about-llms.txt", relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, default_config),
           "about-llms.txt should not be treated as an llms file"
  end

  # --- include_layouts tests ---

  def test_include_layouts_nil_includes_all
    obj = mock_obj(data: { "layout" => "redirect" }, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, default_config)
  end

  def test_include_layouts_allows_listed_layout
    config = default_config.merge("include_layouts" => %w[post page])
    obj = mock_obj(data: { "layout" => "post" }, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_layouts_excludes_unlisted_layout
    config = default_config.merge("include_layouts" => %w[post page])
    obj = mock_obj(data: { "layout" => "redirect" }, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_layouts_exclude_reason_shows_layout_name
    config = default_config.merge("include_layouts" => %w[post page])
    obj = mock_obj(data: { "layout" => "redirect" }, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, site, config)

    assert_equal "layout: redirect", reason
  end

  def test_include_layouts_excludes_nil_layout
    config = default_config.merge("include_layouts" => %w[post])
    obj = mock_obj(data: {}, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_layouts_empty_excludes_everything
    config = default_config.merge("include_layouts" => [])
    obj = mock_obj(data: { "layout" => "post" }, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  # --- include_collections tests ---

  def test_include_collections_nil_includes_all
    obj = mock_obj(data: {}, collection_label: "drafts", path: __FILE__, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, default_config)
  end

  def test_include_collections_allows_listed_collection
    config = default_config.merge("include_collections" => %w[posts])
    obj = mock_obj(data: {}, collection_label: "posts", path: __FILE__, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_collections_excludes_unlisted_collection
    config = default_config.merge("include_collections" => %w[posts])
    obj = mock_obj(data: {}, collection_label: "drafts", relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_collections_exclude_reason_shows_collection_name
    config = default_config.merge("include_collections" => %w[posts])
    obj = mock_obj(data: {}, collection_label: "drafts", relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))
    reason = JekyllAeo::Utils::IncludeLogic.exclude_reason(obj, site, config)

    assert_equal "collection: drafts", reason
  end

  def test_include_collections_pages_always_pass
    config = default_config.merge("include_collections" => %w[posts])
    obj = mock_obj(data: {}, relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    assert JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end

  def test_include_collections_empty_excludes_all_documents
    config = default_config.merge("include_collections" => [])
    obj = mock_obj(data: {}, collection_label: "posts", relative_path: File.basename(__FILE__))
    site = mock_site(source: File.dirname(__FILE__))

    refute JekyllAeo::Utils::IncludeLogic.include?(obj, site, config)
  end
end
# rubocop:enable Minitest/AssertIncludes, Minitest/RefuteIncludes
