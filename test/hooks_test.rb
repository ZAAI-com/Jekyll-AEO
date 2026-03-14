# frozen_string_literal: true

require "test_helper"

class HooksTest < Minitest::Test
  def test_documents_post_write_hook_registered
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)

    assert_predicate hooks.dig(:documents, :post_write), :any?,
                     "Expected :documents :post_write hook to be registered"
  end

  def test_pages_post_write_hook_registered
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)

    assert_predicate hooks.dig(:pages, :post_write), :any?,
                     "Expected :pages :post_write hook to be registered"
  end

  def test_site_post_write_hook_registered
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)

    assert_predicate hooks.dig(:site, :post_write), :any?,
                     "Expected :site :post_write hook to be registered"
  end
end
