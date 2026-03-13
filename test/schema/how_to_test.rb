# frozen_string_literal: true

require "test_helper"

class HowToSchemaTest < Minitest::Test
  def test_returns_nil_when_no_howto
    result = JekyllAeo::Schema::HowTo.build({}, {})
    assert_nil result
  end

  def test_returns_nil_when_howto_not_hash
    result = JekyllAeo::Schema::HowTo.build({ "howto" => "not hash" }, {})
    assert_nil result
  end

  def test_returns_nil_when_no_steps
    result = JekyllAeo::Schema::HowTo.build({ "howto" => {} }, {})
    assert_nil result
  end

  def test_returns_nil_when_steps_empty
    result = JekyllAeo::Schema::HowTo.build({ "howto" => { "steps" => [] } }, {})
    assert_nil result
  end

  def test_builds_how_to_schema
    page = {
      "title" => "Install Ruby",
      "howto" => {
        "steps" => [
          { "text" => "Download Ruby" },
          { "text" => "Run installer" }
        ]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})

    assert_equal "https://schema.org", result["@context"]
    assert_equal "HowTo", result["@type"]
    assert_equal "Install Ruby", result["name"]
    assert_equal 2, result["step"].length

    step1 = result["step"].first
    assert_equal "HowToStep", step1["@type"]
    assert_equal 1, step1["position"]
    assert_equal "Download Ruby", step1["text"]
  end

  def test_step_positions_are_sequential
    page = {
      "howto" => {
        "steps" => [
          { "text" => "Step 1" },
          { "text" => "Step 2" },
          { "text" => "Step 3" }
        ]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})

    positions = result["step"].map { |s| s["position"] }
    assert_equal [1, 2, 3], positions
  end

  def test_optional_step_fields
    page = {
      "howto" => {
        "steps" => [
          { "text" => "Do it", "name" => "Step Name", "url" => "https://example.com", "image" => "/img.png" }
        ]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})
    step = result["step"].first

    assert_equal "Step Name", step["name"]
    assert_equal "https://example.com", step["url"]
    assert_equal "/img.png", step["image"]
  end

  def test_optional_howto_fields
    page = {
      "howto" => {
        "name" => "Custom Name",
        "description" => "A guide",
        "totalTime" => "PT30M",
        "steps" => [{ "text" => "Do it" }]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})

    assert_equal "Custom Name", result["name"]
    assert_equal "A guide", result["description"]
    assert_equal "PT30M", result["totalTime"]
  end

  def test_skips_steps_without_text
    page = {
      "howto" => {
        "steps" => [
          { "text" => "Valid step" },
          { "name" => "No text" },
          "not a hash"
        ]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})

    assert_equal 1, result["step"].length
  end

  def test_howto_name_falls_back_to_page_title
    page = {
      "title" => "Page Title",
      "howto" => {
        "steps" => [{ "text" => "Do it" }]
      }
    }
    result = JekyllAeo::Schema::HowTo.build(page, {})

    assert_equal "Page Title", result["name"]
  end
end
