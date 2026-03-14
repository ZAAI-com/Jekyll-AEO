# frozen_string_literal: true

require "test_helper"

class FaqPageSchemaTest < Minitest::Test
  def test_returns_nil_when_no_faq
    result = JekyllAeo::Schema::FaqPage.build({}, {})

    assert_nil result
  end

  def test_returns_nil_when_faq_empty
    result = JekyllAeo::Schema::FaqPage.build({ "faq" => [] }, {})

    assert_nil result
  end

  def test_returns_nil_when_faq_not_array
    result = JekyllAeo::Schema::FaqPage.build({ "faq" => "not array" }, {})

    assert_nil result
  end

  def test_builds_faq_page_schema
    page = {
      "faq" => [
        { "q" => "What is AEO?", "a" => "Answer Engine Optimization." }
      ]
    }
    result = JekyllAeo::Schema::FaqPage.build(page, {})

    assert_equal "https://schema.org", result["@context"]
    assert_equal "FAQPage", result["@type"]
    assert_equal 1, result["mainEntity"].length

    question = result["mainEntity"].first

    assert_equal "Question", question["@type"]
    assert_equal "What is AEO?", question["name"]
    assert_equal "Answer", question["acceptedAnswer"]["@type"]
    assert_equal "Answer Engine Optimization.", question["acceptedAnswer"]["text"]
  end

  def test_multiple_questions
    page = {
      "faq" => [
        { "q" => "Q1", "a" => "A1" },
        { "q" => "Q2", "a" => "A2" },
        { "q" => "Q3", "a" => "A3" }
      ]
    }
    result = JekyllAeo::Schema::FaqPage.build(page, {})

    assert_equal 3, result["mainEntity"].length
  end

  def test_skips_invalid_items
    page = {
      "faq" => [
        { "q" => "Valid?", "a" => "Yes" },
        { "q" => "Missing answer" },
        { "a" => "Missing question" },
        "not a hash"
      ]
    }
    result = JekyllAeo::Schema::FaqPage.build(page, {})

    assert_equal 1, result["mainEntity"].length
    assert_equal "Valid?", result["mainEntity"].first["name"]
  end

  def test_returns_nil_when_all_items_invalid
    page = {
      "faq" => [
        { "q" => "No answer" },
        { "a" => "No question" }
      ]
    }
    result = JekyllAeo::Schema::FaqPage.build(page, {})

    assert_nil result
  end
end
