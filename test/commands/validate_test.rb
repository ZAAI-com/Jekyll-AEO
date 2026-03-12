# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class ValidateTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def write_file(relative_path, content)
    path = File.join(@tmpdir, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def valid_llms_txt(links: ["- [About](/about.md)"])
    "# Test Site\n\n> A test site\n\n#{links.join("\n")}\n"
  end

  def test_valid_site_passes
    write_file("llms.txt", valid_llms_txt)
    write_file("llms-full.txt", "# Test Site\n\n---\n\n# About\n")
    write_file("about.md", "# About\n")

    errors, warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_empty errors
    assert_empty warnings
  end

  def test_missing_llms_txt
    write_file("llms-full.txt", "content")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_equal 1, errors.size
    assert_match(/llms\.txt not found/, errors.first)
  end

  def test_missing_llms_full_txt
    write_file("llms.txt", valid_llms_txt(links: []))

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_equal 1, errors.size
    assert_match(/llms-full\.txt not found/, errors.first)
  end

  def test_empty_llms_full_txt
    write_file("llms.txt", valid_llms_txt(links: []))
    write_file("llms-full.txt", "")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_equal 1, errors.size
    assert_match(/llms-full\.txt is empty/, errors.first)
  end

  def test_llms_txt_no_h1
    write_file("llms.txt", "No heading here\n")
    write_file("llms-full.txt", "content")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert(errors.any? { |e| e.include?("H1 heading") })
  end

  def test_missing_referenced_md
    write_file("llms.txt", valid_llms_txt(links: ["- [About](/about.md)", "- [Contact](/contact.md)"]))
    write_file("llms-full.txt", "content")
    write_file("about.md", "# About\n")
    # contact.md intentionally missing

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_equal 1, errors.size
    assert_match(%r{/contact\.md}, errors.first)
  end

  def test_all_referenced_md_exist
    write_file("llms.txt", valid_llms_txt(links: ["- [A](/a.md)", "- [B](/b.md)"]))
    write_file("llms-full.txt", "content")
    write_file("a.md", "# A\n")
    write_file("b.md", "# B\n")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir)
    assert_empty errors
  end

  def test_baseurl_stripped_for_file_lookup
    write_file("llms.txt", valid_llms_txt(links: ["- [About](/docs/about.md)"]))
    write_file("llms-full.txt", "content")
    write_file("about.md", "# About\n")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir, "/docs")
    assert_empty errors
  end

  def test_baseurl_not_stripped_when_empty
    write_file("llms.txt", valid_llms_txt(links: ["- [About](/about.md)"]))
    write_file("llms-full.txt", "content")
    write_file("about.md", "# About\n")

    errors, _warnings = JekyllAeo::Commands::Validate.validate(@tmpdir, "")
    assert_empty errors
  end
end
