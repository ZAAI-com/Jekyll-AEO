# Jekyll-AEO

A RubyGem (`jekyll-aeo`) for Answer Engine Optimization — generates clean markdown copies of Jekyll pages and llms.txt/llms-full.txt index files for LLM consumption.

## Project Info

- **Gem name:** jekyll-aeo
- **Module:** JekyllAeo
- **Author:** Manuel Gruber (ZAAI)
- **License:** MIT
- **Ruby:** >= 3.0
- **Jekyll:** >= 4.0

## Architecture

- `lib/jekyll-aeo.rb` — entry point, requires all submodules
- `lib/jekyll-aeo/config.rb` — centralized config with defaults (`JekyllAeo::Config`)
- `lib/jekyll-aeo/generators/` — `markdown_page.rb` (per-page .md), `llms_txt.rb` (site-wide index)
- `lib/jekyll-aeo/utils/` — `content_stripper.rb` (Liquid/kramdown stripping), `skip_logic.rb`
- `lib/jekyll-aeo/hooks.rb` — 3 Jekyll hooks (documents, pages, site post_write)
- `test/` — Minitest tests mirroring lib/ structure

## Conventions

- All Ruby files start with `# frozen_string_literal: true`
- Config is always read via `JekyllAeo::Config.from_site(site)`, never directly from `site.config`
- Tests use Minitest (not RSpec), located in `test/` mirroring `lib/` structure
- Run tests: `rake test`
- Build gem: `gem build jekyll-aeo.gemspec`

## Key Design Decisions

- comment/capture Liquid blocks are fully stripped (tags + content) by default (`strip_block_tags: true`)
- if/for/unless/case blocks only have tag lines stripped — content between them is preserved
- Fenced code blocks (``` and ~~~) are protected from stripping; indented code blocks only when `protect_indented_code: true`
- llms.txt sections auto-generate from Jekyll collections when not explicitly configured
