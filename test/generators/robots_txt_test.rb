# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RobotsTxtTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @source_dir = File.join(@tmpdir, "source")
    @dest_dir = File.join(@tmpdir, "public")
    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(@dest_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def mock_site(aeo_config: {}, url: "https://example.com", baseurl: nil)
    source = @source_dir
    dest = @dest_dir
    pages = []
    cfg = { "url" => url, "jekyll_aeo" => aeo_config }
    cfg["baseurl"] = baseurl if baseurl

    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) { cfg }
    site.define_singleton_method(:pages) { pages }
    site.define_singleton_method(:in_source_dir) { |*paths| File.join(source, *paths) }
    site.define_singleton_method(:in_theme_dir) { |*paths| File.join("_theme", *paths) }
    site
  end

  def generate(site)
    JekyllAeo::Generators::RobotsTxt.new.generate(site)
  end

  # --- Enabled / Disabled ---

  def test_disabled_by_default
    site = mock_site
    generate(site)
    assert_empty site.pages
  end

  def test_generates_when_enabled
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    assert_equal 1, site.pages.length
    assert_equal "robots.txt", site.pages.first.name
  end

  def test_disabled_via_master_switch
    site = mock_site(aeo_config: { "enabled" => false, "robots_txt" => { "enabled" => true } })
    generate(site)
    assert_empty site.pages
  end

  def test_skips_when_user_robots_exists
    File.write(File.join(@source_dir, "robots.txt"), "User-agent: *\nDisallow:\n")
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    assert_empty site.pages
  end

  # --- Content ---

  def test_allow_bots_in_output
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "User-agent: Googlebot\nAllow: /"
    assert_includes content, "User-agent: OAI-SearchBot\nAllow: /"
    assert_includes content, "User-agent: Claude-SearchBot\nAllow: /"
    assert_includes content, "User-agent: PerplexityBot\nAllow: /"
  end

  def test_disallow_bots_in_output
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "User-agent: GPTBot\nDisallow: /"
    assert_includes content, "User-agent: ClaudeBot\nDisallow: /"
    assert_includes content, "User-agent: Google-Extended\nDisallow: /"
    assert_includes content, "User-agent: Meta-ExternalAgent\nDisallow: /"
  end

  def test_default_allow_all_others
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "User-agent: *\nAllow: /"
  end

  def test_includes_sitemap_directive
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "Sitemap: https://example.com/sitemap.xml"
  end

  def test_includes_llms_txt_directive
    site = mock_site(aeo_config: { "robots_txt" => { "enabled" => true } })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "Llms-txt: https://example.com/llms.txt"
  end

  def test_sitemap_respects_baseurl
    site = mock_site(
      aeo_config: { "robots_txt" => { "enabled" => true } },
      baseurl: "/blog"
    )
    generate(site)
    content = site.pages.first.content

    assert_includes content, "Sitemap: https://example.com/blog/sitemap.xml"
    assert_includes content, "Llms-txt: https://example.com/blog/llms.txt"
  end

  def test_omits_sitemap_when_disabled
    site = mock_site(aeo_config: {
      "robots_txt" => { "enabled" => true, "include_sitemap" => false }
    })
    generate(site)
    content = site.pages.first.content

    refute_includes content, "Sitemap:"
  end

  def test_omits_llms_txt_when_disabled
    site = mock_site(aeo_config: {
      "robots_txt" => { "enabled" => true, "include_llms_txt" => false }
    })
    generate(site)
    content = site.pages.first.content

    refute_includes content, "Llms-txt:"
  end

  def test_custom_allow_bots
    site = mock_site(aeo_config: {
      "robots_txt" => { "enabled" => true, "allow" => %w[MyBot], "disallow" => [] }
    })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "User-agent: MyBot\nAllow: /"
    refute_includes content, "User-agent: Googlebot"
  end

  def test_custom_rules
    site = mock_site(aeo_config: {
      "robots_txt" => {
        "enabled" => true,
        "custom_rules" => [
          { "user_agent" => "SpecialBot", "disallow" => "/private/" }
        ]
      }
    })
    generate(site)
    content = site.pages.first.content

    assert_includes content, "User-agent: SpecialBot"
    assert_includes content, "Disallow: /private/"
  end
end
