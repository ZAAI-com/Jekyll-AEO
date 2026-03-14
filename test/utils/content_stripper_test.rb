# frozen_string_literal: true

require "test_helper"

class ContentStripperTest < Minitest::Test
  def strip(content, config = {})
    JekyllAeo::Utils::ContentStripper.strip(content, config)
  end

  # --- Basic Liquid stripping ---

  def test_strips_liquid_block_tags
    input = "Hello {% if true %}world{% endif %} there"

    assert_equal "Hello world there", strip(input)
  end

  def test_strips_liquid_output_tags
    input = "Hello {{ name }} there"

    assert_equal "Hello  there", strip(input)
  end

  def test_strips_trimmed_liquid_tags
    input = "Hello {%- if true -%}world{%- endif -%} there"

    assert_equal "Hello world there", strip(input)
  end

  def test_strips_liquid_for_loop_tags_preserves_content
    input = "{% for item in items %}\n### Item\n{% endfor %}\n"

    assert_equal "\n### Item\n\n", strip(input)
  end

  # --- Kramdown IAL stripping ---

  def test_strips_kramdown_ial_inline
    input = "![image](url){:width=\"300\" style=\"max-width:100%\"}"

    assert_equal "![image](url)", strip(input)
  end

  def test_strips_kramdown_ial_block
    input = "{: .special-class}\n"

    assert_equal "\n", strip(input)
  end

  def test_strips_kramdown_ial_with_id
    input = "## Heading {: #my-id}\n"

    assert_equal "## Heading\n", strip(input)
  end

  # --- Fenced code block protection ---

  def test_preserves_liquid_inside_backtick_fence
    input = "```\n{% for item in items %}\n{{ item.name }}\n{% endfor %}\n```\n"

    assert_equal input, strip(input)
  end

  def test_preserves_liquid_inside_tilde_fence
    input = "~~~\n{% for item in items %}\n{{ item.name }}\n{% endfor %}\n~~~\n"

    assert_equal input, strip(input)
  end

  def test_preserves_liquid_inside_fence_with_language
    input = "```liquid\n{% for item in items %}\n{% endfor %}\n```\n"

    assert_equal input, strip(input)
  end

  def test_nested_fences_four_backticks_containing_three
    input = "````\n```\n{% tag %}\n```\n````\n"

    assert_equal input, strip(input)
  end

  def test_backtick_fence_not_closed_by_tilde
    input = "```\n{% tag %}\n~~~\n{% tag2 %}\n```\n"

    assert_equal input, strip(input)
  end

  def test_tilde_fence_not_closed_by_backtick
    input = "~~~\n{% tag %}\n```\n{% tag2 %}\n~~~\n"

    assert_equal input, strip(input)
  end

  def test_preserves_kramdown_inside_fence
    input = "```\n{: .class}\n{:width=\"300\"}\n```\n"

    assert_equal input, strip(input)
  end

  def test_fence_with_indentation
    input = "   ```\n{% tag %}\n   ```\n"

    assert_equal input, strip(input)
  end

  # --- {% raw %} / {% endraw %} handling ---

  def test_single_line_raw_endraw
    input = "{% raw %}{{ preserved }}{% endraw %}"

    assert_equal "{{ preserved }}", strip(input)
  end

  def test_multi_line_raw_endraw
    input = "{% raw %}\n{{ preserved }}\n{% tag %}\n{% endraw %}\n"
    result = strip(input)

    assert_includes result, "{{ preserved }}"
    assert_includes result, "{% tag %}"
  end

  def test_raw_inside_fenced_code_block_preserved
    input = "```\n{% raw %}\n{{ code }}\n{% endraw %}\n```\n"

    assert_equal input, strip(input)
  end

  # --- Silent block stripping (comment/capture) ---

  def test_comment_block_stripped_when_enabled
    input = "Before\n{% comment %}\nHidden content\n{% endcomment %}\nAfter\n"
    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "Before"
    assert_includes result, "After"
    refute_includes result, "Hidden content"
  end

  def test_comment_block_content_preserved_when_disabled
    input = "Before\n{% comment %}\nVisible content\n{% endcomment %}\nAfter\n"
    result = strip(input, "strip_block_tags" => false)

    assert_includes result, "Before"
    assert_includes result, "After"
    assert_includes result, "Visible content"
  end

  def test_capture_block_stripped_when_enabled
    input = "Before\n{% capture myvar %}\nCaptured\n{% endcapture %}\nAfter\n"
    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "Before"
    assert_includes result, "After"
    refute_includes result, "Captured"
  end

  def test_capture_block_content_preserved_when_disabled
    input = "Before\n{% capture myvar %}\nCaptured\n{% endcapture %}\nAfter\n"
    result = strip(input, "strip_block_tags" => false)

    assert_includes result, "Captured"
  end

  def test_if_block_content_always_preserved
    input = "{% if condition %}\nKept content\n{% endif %}\n"
    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "Kept content"
  end

  def test_for_block_content_always_preserved
    input = "{% for item in items %}\nKept content\n{% endfor %}\n"
    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "Kept content"
  end

  def test_unless_block_content_always_preserved
    input = "{% unless condition %}\nKept content\n{% endunless %}\n"
    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "Kept content"
  end

  # --- Indented code block protection ---

  def test_indented_code_not_protected_by_default
    input = "Text\n\n    {% tag %}\n    {{ var }}\n\nMore text\n"
    result = strip(input, "protect_indented_code" => false)

    refute_includes result, "{% tag %}"
    refute_includes result, "{{ var }}"
  end

  def test_indented_code_protected_when_enabled
    input = "Text\n\n    {% tag %}\n    {{ var }}\n\nMore text\n"
    result = strip(input, "protect_indented_code" => true)

    assert_includes result, "{% tag %}"
    assert_includes result, "{{ var }}"
  end

  # --- Edge cases ---

  def test_empty_input
    assert_equal "", strip("")
    assert_equal "", strip(nil)
    assert_equal "", strip("   \n  \n  ")
  end

  def test_blank_line_only_content
    assert_equal "", strip("\n\n\n")
  end

  def test_no_liquid_or_kramdown
    input = "# Hello\n\nJust plain markdown.\n"

    assert_equal input, strip(input)
  end

  def test_mixed_states_in_document
    input = <<~MD
      # Title

      {% comment %}
      Hidden note
      {% endcomment %}

      Regular {{ var }} content

      ```ruby
      {% for item in items %}
        {{ item }}
      {% endfor %}
      ```

      More {% if true %}visible{% endif %} text
    MD

    result = strip(input, "strip_block_tags" => true)

    assert_includes result, "# Title"
    refute_includes result, "Hidden note"
    assert_includes result, "Regular  content"
    assert_includes result, "{% for item in items %}"
    assert_includes result, "{{ item }}"
    assert_includes result, "More visible text"
  end
end
