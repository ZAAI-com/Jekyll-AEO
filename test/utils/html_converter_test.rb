# frozen_string_literal: true

require "test_helper"

class HtmlConverterTest < Minitest::Test
  def test_converts_basic_html
    html = "<h2>Title</h2><p>Some text here.</p>"
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "## Title"
    assert_includes result, "Some text here."
  end

  def test_extracts_main_content
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Test</title></head>
      <body>
        <nav><a href="/">Home</a></nav>
        <main>
          <h1>Main Content</h1>
          <p>Important text.</p>
        </main>
        <footer>Footer stuff</footer>
      </body>
      </html>
    HTML
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Main Content"
    assert_includes result, "Important text."
    refute_includes result, "Footer stuff"
    refute_includes result, "Home"
  end

  def test_extracts_article_when_no_main
    html = <<~HTML
      <html><body>
        <nav><a href="/">Nav</a></nav>
        <article>
          <h1>Article Content</h1>
          <p>Article text.</p>
        </article>
        <footer>Footer</footer>
      </body></html>
    HTML
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Article Content"
    assert_includes result, "Article text."
    refute_includes result, "Footer"
  end

  def test_extracts_body_when_no_main_or_article
    html = "<html><body><h2>Body Content</h2><p>Body text.</p></body></html>"
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Body Content"
    assert_includes result, "Body text."
  end

  def test_custom_selector
    html = <<~HTML
      <html><body>
        <div class="sidebar">Sidebar</div>
        <div class="content">
          <h1>Custom Content</h1>
          <p>Selected text.</p>
        </div>
      </body></html>
    HTML
    config = { "html_fallback_selector" => ".content" }
    result = JekyllAeo::Utils::HtmlConverter.convert(html, config)
    assert_includes result, "Custom Content"
    assert_includes result, "Selected text."
    refute_includes result, "Sidebar"
  end

  def test_strips_script_style_nav
    html = <<~HTML
      <html><body>
        <script>alert('hi');</script>
        <style>.foo { color: red; }</style>
        <nav><a href="/">Nav link</a></nav>
        <h1>Content</h1>
        <p>Visible text.</p>
      </body></html>
    HTML
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Visible text."
    refute_includes result, "alert"
    refute_includes result, "color: red"
    refute_includes result, "Nav link"
  end

  def test_strips_header_and_footer
    html = <<~HTML
      <html><body>
        <header><h1>Site Header</h1></header>
        <main><p>Main content.</p></main>
        <footer><p>Copyright</p></footer>
      </body></html>
    HTML
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Main content."
    refute_includes result, "Site Header"
    refute_includes result, "Copyright"
  end

  def test_returns_empty_for_nil_html
    assert_equal "", JekyllAeo::Utils::HtmlConverter.convert(nil)
  end

  def test_returns_empty_for_empty_html
    assert_equal "", JekyllAeo::Utils::HtmlConverter.convert("")
    assert_equal "", JekyllAeo::Utils::HtmlConverter.convert("   ")
  end

  def test_handles_links
    html = '<p>Visit <a href="https://example.com">Example</a> for more.</p>'
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "[Example](https://example.com)"
  end

  def test_handles_images
    html = '<p><img src="/photo.jpg" alt="A photo"></p>'
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "![A photo](/photo.jpg)"
  end

  def test_handles_code_blocks
    html = '<pre><code>def hello\n  puts "hi"\nend</code></pre>'
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "def hello"
  end

  def test_handles_lists
    html = "<ul><li>Item one</li><li>Item two</li></ul>"
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "Item one"
    assert_includes result, "Item two"
  end

  def test_handles_ordered_lists
    html = "<ol><li>First</li><li>Second</li></ol>"
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "First"
    assert_includes result, "Second"
  end

  def test_handles_emphasis
    html = "<p><strong>Bold</strong> and <em>italic</em> text.</p>"
    result = JekyllAeo::Utils::HtmlConverter.convert(html)
    assert_includes result, "**Bold**"
    assert_includes result, "_italic_"
  end

  def test_custom_selector_returns_empty_when_not_found
    html = "<html><body><p>Content</p></body></html>"
    config = { "html_fallback_selector" => ".nonexistent" }
    result = JekyllAeo::Utils::HtmlConverter.convert(html, config)
    assert_equal "", result
  end
end
