# Jekyll-AEO

A RubyGem (`jekyll-aeo`) for Answer Engine Optimization — generates clean markdown copies of Jekyll pages and llms.txt/llms-full.txt index files for LLM consumption.

## Project Info

- **Gem name:** jekyll-aeo
- **Module:** JekyllAeo
- **Author:** Manuel Gruber (ZAAI)
- **License:** MIT
- **Ruby:** >= 3.2
- **Jekyll:** >= 4.0

## Architecture

- `lib/jekyll-aeo.rb` — entry point, requires all submodules
- `lib/jekyll-aeo/version.rb` — gem version constant
- `lib/jekyll-aeo/config.rb` — centralized config with defaults (`JekyllAeo::Config`)
- `lib/jekyll-aeo/hooks.rb` — 7 Jekyll hooks (pre_render, post_render, post_write for documents + pages; site post_write)
- `lib/jekyll-aeo/link_tag.rb` — injects/sets `<link rel="alternate" type="text/markdown">` tags
- `lib/jekyll-aeo/generators/` — `dot_md_writer.rb` (per-page .md via post_write hook), `llms_txt.rb`, `llms_full_txt.rb`, `url_map.rb`, `domain_profile.rb` (all invoked from site post_write hook), `robots_txt.rb` (Jekyll::Generator — crawler policy, search vs training bots)
- `lib/jekyll-aeo/schema/` — `faq_page.rb`, `how_to.rb`, `breadcrumb_list.rb`, `organization.rb`, `speakable.rb`, `article.rb` (JSON-LD schema builders)
- `lib/jekyll-aeo/tags/` — `aeo_json_ld.rb` (`{% aeo_json_ld %}` Liquid tag, renders schema builders as `<script type="application/ld+json">`)
- `lib/jekyll-aeo/utils/` — `content_stripper.rb` (Liquid/kramdown stripping), `skip_logic.rb`, `md_url.rb` (markdown URL path logic), `html_converter.rb` (HTML-to-markdown via reverse_markdown for html2dotmd)
- `lib/jekyll-aeo/commands/` — `validate.rb` (`jekyll aeo:validate` command)
- `test/` — Minitest tests mirroring lib/ structure

## Conventions

- All Ruby files start with `# frozen_string_literal: true`
- Config is always read via `JekyllAeo::Config.from_site(site)`, never directly from `site.config`
- Tests use Minitest (not RSpec), located in `test/` mirroring `lib/` structure
- `test/integration/example_site_test.rb` — integration tests that build `demo/example.com/` and assert on output
- Run unit tests: `rake test`
- Run all tests (unit + integration): `rake` (default task runs rubocop + all tests)
- Build/serve the example site: `rake site:build` / `rake site:serve`
- Build gem: `gem build jekyll-aeo.gemspec`

## Config Structure

Top-level config (`jekyll_aeo`):
- `enabled` — master switch
- `exclude` — URL prefixes to skip (applies across all features)
- `dotmd` — nested group for .md file generation settings:
  - `link_tag`, `include_last_modified`, `dotmd_metadata` (shared settings)
  - `md2dotmd` — `strip_block_tags`, `protect_indented_code` (source markdown → .md)
  - `html2dotmd` — `enabled`, `selector` (rendered HTML → .md)
- `llms_txt` — llms.txt generation settings (sections config shared with llms_full_txt)
- `llms_full_txt` — llms-full.txt generation settings (`enabled`, `description`, `full_txt_mode`)
- `url_map` — URL map generation settings
- `robots_txt` — robots.txt generation settings
- `domain_profile` — /.well-known/domain-profile.json settings

Dotmd flags are accessed via `config["dotmd"]` (often stored in a local `dotmd_config` variable).

## Key Design Decisions

- Markdown paths always use "clean" style (`/about/index.html` → `/about.md`)
- comment/capture Liquid blocks are fully stripped (tags + content) by default (`strip_block_tags: true`)
- if/for/unless/case blocks only have tag lines stripped — content between them is preserved
- Fenced code blocks (``` and ~~~) are protected from stripping; indented code blocks only when `protect_indented_code: true`
- llms.txt sections auto-generate from Jekyll collections when not explicitly configured
- Domain profile (/.well-known/domain-profile.json) is opt-in (disabled by default), requires `contact` field
- URL map is opt-in (disabled by default), written to source directory (not dest)
- Link tag defaults to `"auto"` mode (injects into HTML `</head>`)
- robots.txt is opt-in (disabled by default), allows search bots and blocks training bots
- `{% aeo_json_ld %}` Liquid tag renders multiple JSON-LD `<script>` blocks per page from 6 schema builders
- Article schema auto-skips when jekyll-seo-tag is detected (avoids conflict with BlogPosting)
- Organization schema only renders on homepage; BreadcrumbList auto-generates from URL path
- FAQPage/HowTo/Speakable trigger from front matter (`faq:`, `howto:`, `speakable: true`)
