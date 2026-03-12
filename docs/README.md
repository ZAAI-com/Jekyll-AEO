# Jekyll-AEO

Answer Engine Optimization for Jekyll. Generates clean markdown copies of every page and produces `llms.txt` / `llms-full.txt` index files, following the [llms.txt spec](https://llmstxt.org/).

## Installation

Add to your Jekyll site's `Gemfile`:

```ruby
gem "jekyll-aeo"
```

Then run:

```bash
bundle install
```

## Quick Start

That's it. With zero configuration, `jekyll-aeo` will:

1. Generate a `.md` companion for every HTML page (e.g., `/about/index.html` → `/about.md`)
2. Generate `/llms.txt` with an index of all pages
3. Generate `/llms-full.txt` with all page content concatenated

Run `bundle exec jekyll build` and check your output directory.

## Configuration

All settings are optional. Add to `_config.yml`:

```yaml
jekyll_aeo:
  enabled: true                    # master switch (default: true)
  md_path_style: "clean"           # "clean" or "spec" (default: "clean")
  strip_block_tags: true           # strip comment/capture block content (default: true)
  protect_indented_code: false     # protect 4-space indented code blocks (default: false)
  exclude:                         # URL prefixes to skip
    - /privacy/
    - /error/
  llms_txt:
    enabled: true                  # generate llms.txt + llms-full.txt (default: true)
    description: ""                # override site description in llms.txt
    full_txt_mode: "all"           # "all" or "linked" (default: "all")
    sections:                      # custom sections (auto-generated if omitted)
      - title: "Pages"
        collection: "pages"
      - title: "Products"
        collection: "products"
      - title: "Blog Posts"
        collection: "posts"
      - title: "Optional"
        collection: "profiles"
```

### Per-Page Options

Disable markdown generation for a specific page via front matter:

```yaml
---
title: Secret Page
markdown_copy: false
---
```

Pages with `redirect_to` in front matter are automatically skipped.

## How It Works

### Per-Page Markdown Generation

For every HTML page Jekyll renders, the plugin:

1. Re-reads the original source file from disk
2. Strips YAML front matter
3. Strips Liquid tags (`{% %}` and `{{ }}`) outside fenced code blocks
4. Strips kramdown attribute annotations (`{: .class}`, `{:width="300"}`)
5. Prepends the page title as an H1 header (if not already present)
6. Adds the page description as a blockquote (if present)
7. Writes the result as a `.md` file (path depends on `md_path_style`)

### Markdown Path Styles

The `md_path_style` setting controls where `.md` files are written and how llms.txt links to them.

| Style | HTML path | Markdown path | llms.txt link |
|---|---|---|---|
| `"clean"` (default) | `/about/index.html` | `/about.md` | `/about.md` |
| `"clean"` | `/index.html` | `/index.md` | `/index.md` |
| `"spec"` | `/about/index.html` | `/about/index.html.md` | `/about/index.html.md` |

The `"clean"` style follows the [llms.txt spec](https://llmstxt.org/) recommendation that markdown should be available at the "same URL as the original page, but with `.md` appended after removing any trailing slash." The `"spec"` style appends `.md` directly to the HTML file path.

### llms.txt

Generated at the site root with:
- H1: site title
- Blockquote: site description
- H2 sections grouping pages by collection, with links to `.md` files

### llms-full.txt

All individual `.md` file contents concatenated, separated by `---`.

- `full_txt_mode: "all"` (default): includes every eligible page
- `full_txt_mode: "linked"`: only includes pages that appear in llms.txt sections

## `strip_block_tags`

Controls how Liquid comment and capture blocks are handled.

**With `strip_block_tags: true` (default):**

Source:
```markdown
{% comment %}
Internal note for editors.
{% endcomment %}

Welcome to the page.
```

Output `.md`:
```markdown
Welcome to the page.
```

Comment and capture blocks are fully removed (tags + content), since they contain developer metadata, not page content.

**With `strip_block_tags: false`:**

The same source would produce:
```markdown
Internal note for editors.

Welcome to the page.
```

Note: `{% if %}`, `{% for %}`, `{% unless %}`, and `{% case %}` blocks always preserve their content regardless of this setting, since the content between them is real page content.

## `protect_indented_code`

By default, only fenced code blocks (` ``` ` and `~~~`) are protected from Liquid/kramdown stripping. Enable `protect_indented_code: true` to also protect indented code blocks (4+ spaces after a blank line).

Recommendation: use fenced code blocks for code examples that contain Liquid syntax.

## Custom Sections

By default, llms.txt auto-generates sections by grouping pages by their Jekyll collection. To customize:

```yaml
jekyll_aeo:
  llms_txt:
    sections:
      - title: "Documentation"
        collection: "pages"
      - title: "Products"
        collection: "products"
      - title: "Optional"          # LLMs can skip this section per spec
        collection: "profiles"
```

Use `collection: null` to match standalone pages (those not in any collection).

## Skipped Content

The following are automatically skipped:

- Non-HTML outputs (CSS, JS, etc.)
- Pages with `markdown_copy: false` in front matter
- Redirect pages (`redirect_to` in front matter)
- Documents in the `assets` collection
- `llms.txt` and `llms-full.txt` files
- Paths matching `exclude` prefixes
- Pages with no source file on disk (plugin-generated)

## License

MIT. Copyright (c) 2026 ZAAI.
