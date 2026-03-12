# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "json"

class DomainProfileTest < Minitest::Test
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

  def mock_site(aeo_config: {}, site_config: {})
    source = @source_dir
    dest = @dest_dir
    base_config = {
      "title" => "Test Site",
      "description" => "A test site",
      "url" => "https://example.com",
      "jekyll_aeo" => aeo_config
    }.merge(site_config)

    site = Object.new
    site.define_singleton_method(:source) { source }
    site.define_singleton_method(:dest) { dest }
    site.define_singleton_method(:config) { base_config }
    site
  end

  def output_path
    File.join(@dest_dir, ".well-known", "domain-profile.json")
  end

  def read_profile
    JSON.parse(File.read(output_path))
  end

  def enabled_config(overrides = {})
    { "domain_profile" => { "enabled" => true, "contact" => "hello@example.com" }.merge(overrides) }
  end

  # --- Enabled/Disabled tests ---

  def test_disabled_by_default
    site = mock_site(aeo_config: {})
    JekyllAeo::Generators::DomainProfile.generate(site)
    refute File.exist?(output_path)
  end

  def test_disabled_via_master_switch
    site = mock_site(aeo_config: { "enabled" => false, "domain_profile" => { "enabled" => true, "contact" => "x" } })
    JekyllAeo::Generators::DomainProfile.generate(site)
    refute File.exist?(output_path)
  end

  def test_disabled_via_feature_switch
    site = mock_site(aeo_config: { "domain_profile" => { "enabled" => false } })
    JekyllAeo::Generators::DomainProfile.generate(site)
    refute File.exist?(output_path)
  end

  # --- Generation tests ---

  def test_generates_file_when_enabled
    site = mock_site(aeo_config: enabled_config)
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert File.exist?(output_path), "domain-profile.json should be created"
    profile = read_profile
    assert_equal "https://ai-domain-data.org/spec/v0.1", profile["spec"]
  end

  def test_creates_well_known_directory
    site = mock_site(aeo_config: enabled_config)
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert File.directory?(File.join(@dest_dir, ".well-known"))
  end

  def test_output_is_valid_json
    site = mock_site(aeo_config: enabled_config)
    JekyllAeo::Generators::DomainProfile.generate(site)

    content = File.read(output_path)
    profile = JSON.parse(content)
    assert profile.is_a?(Hash), "Parsed JSON should be a Hash"
    assert content.end_with?("\n"), "File should end with newline"
  end

  # --- Fallback tests ---

  def test_falls_back_to_site_title
    site = mock_site(aeo_config: enabled_config, site_config: { "title" => "My Site" })
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "My Site", read_profile["name"]
  end

  def test_falls_back_to_site_name_when_no_title
    site = mock_site(
      aeo_config: enabled_config,
      site_config: { "name" => "My Site Name" }
    )
    site.config.delete("title")
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "My Site Name", read_profile["name"]
  end

  def test_falls_back_to_site_description
    site = mock_site(aeo_config: enabled_config, site_config: { "description" => "Site desc" })
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "Site desc", read_profile["description"]
  end

  def test_falls_back_to_site_url
    site = mock_site(aeo_config: enabled_config, site_config: { "url" => "https://mg1.de" })
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "https://mg1.de", read_profile["website"]
  end

  # --- Explicit config overrides ---

  def test_explicit_config_overrides_fallbacks
    site = mock_site(
      aeo_config: enabled_config(
        "name" => "Custom Name",
        "description" => "Custom desc",
        "website" => "https://custom.com"
      ),
      site_config: { "title" => "Fallback Title", "description" => "Fallback desc", "url" => "https://fallback.com" }
    )
    JekyllAeo::Generators::DomainProfile.generate(site)

    profile = read_profile
    assert_equal "Custom Name", profile["name"]
    assert_equal "Custom desc", profile["description"]
    assert_equal "https://custom.com", profile["website"]
  end

  # --- Contact required ---

  def test_skips_when_contact_missing
    site = mock_site(aeo_config: { "domain_profile" => { "enabled" => true } })
    JekyllAeo::Generators::DomainProfile.generate(site)

    refute File.exist?(output_path), "Should not generate without contact"
  end

  # --- Optional fields ---

  def test_includes_logo_when_set
    site = mock_site(aeo_config: enabled_config("logo" => "https://example.com/logo.png"))
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "https://example.com/logo.png", read_profile["logo"]
  end

  def test_excludes_logo_when_not_set
    site = mock_site(aeo_config: enabled_config)
    JekyllAeo::Generators::DomainProfile.generate(site)

    refute read_profile.key?("logo")
  end

  def test_includes_valid_entity_type
    site = mock_site(aeo_config: enabled_config("entity_type" => "Organization"))
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal "Organization", read_profile["entity_type"]
  end

  def test_ignores_invalid_entity_type
    site = mock_site(aeo_config: enabled_config("entity_type" => "InvalidType"))
    JekyllAeo::Generators::DomainProfile.generate(site)

    refute read_profile.key?("entity_type")
  end

  def test_includes_jsonld_when_set
    jsonld = { "@context" => "https://schema.org", "@type" => "Organization", "name" => "Test" }
    site = mock_site(aeo_config: enabled_config("jsonld" => jsonld))
    JekyllAeo::Generators::DomainProfile.generate(site)

    assert_equal jsonld, read_profile["jsonld"]
  end

  def test_excludes_jsonld_when_not_hash
    site = mock_site(aeo_config: enabled_config("jsonld" => "not a hash"))
    JekyllAeo::Generators::DomainProfile.generate(site)

    refute read_profile.key?("jsonld")
  end

  # --- All entity types ---

  def test_all_valid_entity_types_accepted
    %w[Organization Person Blog NGO Community Project CreativeWork SoftwareApplication Thing].each do |type|
      site = mock_site(aeo_config: enabled_config("entity_type" => type))
      JekyllAeo::Generators::DomainProfile.generate(site)

      assert_equal type, read_profile["entity_type"], "entity_type '#{type}' should be accepted"
    end
  end

  # --- Required fields in output ---

  def test_all_required_fields_present
    site = mock_site(aeo_config: enabled_config)
    JekyllAeo::Generators::DomainProfile.generate(site)

    profile = read_profile
    %w[spec name description website contact].each do |field|
      assert profile.key?(field), "Required field '#{field}' should be present"
    end
  end
end
