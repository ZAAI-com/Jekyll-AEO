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
4. Inject `<link rel="alternate" type="text/markdown">` tags into every HTML page

Run `bundle exec jekyll build` and check your output directory.

## Configuration

All settings are optional. Add to `_config.yml`. Configuration uses a strict schema — only keys defined in the plugin are accepted; typos or unknown keys are silently dropped.

```yaml
jekyll_aeo:
  enabled: true                    # master switch; when false, all generation stops (default: true)
  exclude:                         # URL prefixes to skip
    - /privacy/
    - /error/
  dotmd:
    link_tag: "auto"               # "auto", "data", or omit to disable (default: "auto")
    include_last_modified: true    # add "Last updated" date to .md files (default: true)
    dotmd_metadata: false          # add YAML front matter block to .md files (default: false)
    md2dotmd:                      # source markdown → .md settings
      strip_block_tags: true       # strip comment/capture block content (default: true)
      protect_indented_code: false # protect 4-space indented code blocks (default: false)
    html2dotmd:                    # rendered HTML → .md settings (for plugin-generated pages)
      enabled: false               # convert rendered HTML to markdown (default: false)
      selector: null               # CSS selector (default: null — auto-detects main > article > body)
  llms_txt:
    enabled: true                  # generate llms.txt (default: true)
    description: ""                # override site description in llms.txt
    include_descriptions: true     # include page descriptions in llms.txt entries (default: true)
    front_matter_keys: []          # (reserved, not implemented)
    show_lastmod: false            # (reserved, not implemented)
    sections:                      # custom sections (auto-generated if omitted)
      - title: "Pages"
        collection: "pages"
      - title: "Products"
        collection: "products"
      - title: "Blog Posts"
        collection: "posts"
      - title: "Optional"
        collection: "profiles"
  llms_full_txt:
    enabled: true                  # generate llms-full.txt (default: true)
    description: ""                # override description in llms-full.txt header
    full_txt_mode: "all"           # "all" or "linked" (default: "all")
  url_map:
    enabled: false                 # generate URL map markdown table (default: false)
    output_filepath: "docs/Url-Map.md"  # output path relative to project root (default: "docs/Url-Map.md")
    show_created_at: true          # show generation timestamp in document header (default: true)
    columns:                       # columns to include in the table
      - page_id
      - url
      - lang
      - layout
      - path
      - redirects
      - markdown_copy
      - skipped
  robots_txt:
    enabled: false                 # generate robots.txt with crawler policy (default: false)
    allow:                         # search/retrieval bots to allow
      - Googlebot
      - Bingbot
      - OAI-SearchBot
      - ChatGPT-User
      - Claude-SearchBot
      - Claude-User
      - PerplexityBot
      - Applebot-Extended
    disallow:                      # training bots to block
      - GPTBot
      - ClaudeBot
      - Google-Extended
      - Meta-ExternalAgent
      - Amazonbot
    include_sitemap: true          # add Sitemap: directive (default: true)
    include_llms_txt: true         # add Llms-txt: directive (default: true)
    custom_rules: []               # additional bot-specific rules
  domain_profile:
    enabled: false                 # generate /.well-known/domain-profile.json (default: false)
    name: null                     # falls back to site.title or site.name
    description: null              # falls back to site.description
    website: null                  # falls back to site.url
    contact: null                  # REQUIRED — email or URL, no fallback
    logo: null                     # URL to logo image
    entity_type: null              # Organization, Person, Blog, NGO, Community, Project, etc.
    jsonld: null                   # custom JSON-LD hash to include
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
3. Strips Liquid tags (`{% %}` and `{{ }}`) outside fenced code blocks; content inside `{% raw %}…{% endraw %}` is preserved (tags stripped, inner content kept)
4. Strips kramdown attribute annotations (`{: .class}`, `{:width="300"}`)
5. Prepends the page title as an H1 header (if not already present)
6. Adds the page description as a blockquote (if present)
7. Writes the result as a `.md` file alongside the HTML output (for the root index, also writes `index.html.md` with the same content)

### html2dotmd (HTML to Markdown)

Pages generated by Jekyll plugins (e.g., jekyll-paginate, jekyll-archives) have no source file on disk and are normally skipped. With `html2dotmd.enabled: true`, the plugin converts their rendered HTML output to markdown instead:

```yaml
jekyll_aeo:
  dotmd:
    html2dotmd:
      enabled: true
      selector: null               # optional CSS selector
```

The converter automatically extracts the main content area (`<main>`, then `<article>`, then `<body>`) and strips layout chrome (`<script>`, `<style>`, `<nav>`, `<header>`, `<footer>`). Set `selector` to a CSS selector (e.g., `".content"`, `"#main"`) to target a specific element.

### Baseurl Support

If your Jekyll site runs under a subpath (e.g., `baseurl: /docs`), all links in `llms.txt` will include the prefix automatically: `/docs/about.md` instead of `/about.md`. No additional configuration needed.

### Link Tag

By default, jekyll-aeo injects a `<link>` tag into the `<head>` of every HTML page pointing to its markdown copy:

```html
<link rel="alternate" type="text/markdown" href="/about.md">
```

This helps AI crawlers discover the machine-readable version of each page.

The `link_tag` setting controls this behavior:

| Value | Behavior |
|---|---|
| `"auto"` (default) | Injects the `<link>` tag before `</head>` automatically |
| `"data"` | Sets `page.md_url` and `page.md_link_tag` in page data for use in templates |
| omitted / falsy | Disabled |

With `link_tag: "data"`, you can place the tag manually in your layout:

```liquid
{{ page.md_link_tag }}
```

Or use the URL directly:

```liquid
<link rel="alternate" type="text/markdown" href="{{ page.md_url }}">
```

### llms.txt

Generated at the site root with:
- H1: site title
- Blockquote: site description
- Link to `llms-full.txt` for complete content
- H2 sections grouping pages by collection, with links to `.md` files

### llms-full.txt

All individual `.md` file contents concatenated, separated by `---`.

- `full_txt_mode: "all"` (default): includes every eligible page
- `full_txt_mode: "linked"`: only includes pages that appear in llms.txt sections

## URL Map

Generate a markdown table of all HTML pages with metadata. Disabled by default.

```yaml
jekyll_aeo:
  url_map:
    enabled: true
```

This writes a `docs/Url-Map.md` file (configurable via `output_filepath`) relative to your **project root** (the directory containing `_config.yml` when running Jekyll, or the source directory otherwise) — useful as a development reference that can be committed to version control.

The table is grouped by collection (Pages first, then alphabetically) with configurable columns:

| Column | Description |
|---|---|
| `page_id` | Value of `page_id` from front matter |
| `url` | Page URL |
| `lang` | Value of `lang` from front matter |
| `layout` | Layout name |
| `path` | Relative source file path |
| `redirects` | Values from `redirect_from` front matter |
| `markdown_copy` | Path to the generated `.md` file |
| `skipped` | Reason the page was skipped (if any) |

## Domain Profile

Generate a `/.well-known/domain-profile.json` file following the [AI Domain Data spec (v0.1)](https://ai-domain-data.org). This provides AI assistants with authoritative identity metadata about your site. Disabled by default.

```yaml
jekyll_aeo:
  domain_profile:
    enabled: true
    contact: "hello@example.com"   # required
    entity_type: "Organization"    # optional
```

The `contact` field is required — generation is skipped with a warning if not set. The `name`, `description`, and `website` fields fall back to `site.title`/`site.name`, `site.description`, and `site.url` respectively.

Valid `entity_type` values: `Organization`, `Person`, `Blog`, `NGO`, `Community`, `Project`, `CreativeWork`, `SoftwareApplication`, `Thing`.

You can include a custom JSON-LD object via the `jsonld` key:

```yaml
jekyll_aeo:
  domain_profile:
    enabled: true
    contact: "hello@example.com"
    jsonld:
      "@type": "Organization"
      name: "Example Corp"
```

## robots.txt

Generate a `robots.txt` that separates search bots (allowed) from training bots (blocked). Disabled by default.

```yaml
jekyll_aeo:
  robots_txt:
    enabled: true
```

Default behavior: allows search bots (Googlebot, Bingbot, OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, PerplexityBot, Applebot-Extended) and blocks training bots (GPTBot, ClaudeBot, Google-Extended, Meta-ExternalAgent, Amazonbot). Includes `Sitemap:` and `Llms-txt:` directives automatically.

If you already have a `robots.txt` file in your source directory, the generator skips and uses yours instead. Integrates with jekyll-sitemap — no conflicts.

Add custom rules for specific bots:

```yaml
jekyll_aeo:
  robots_txt:
    enabled: true
    custom_rules:
      - user_agent: "SpecialBot"
        allow: "/public/"
        disallow: "/private/"
```

## JSON-LD Schema (`{% aeo_json_ld %}`)

Add the `{% aeo_json_ld %}` Liquid tag to your layout to output structured data as `<script type="application/ld+json">` blocks:

```liquid
<head>
  ...
  {% aeo_json_ld %}
</head>
```

The tag automatically renders JSON-LD for 6 schema types based on your page's front matter and site config:

| Schema | Trigger | Auto? |
|---|---|---|
| BreadcrumbList | URL path (every page except homepage) | Yes |
| Organization | Homepage, when `site.title` or `site.name` is set | Yes |
| FAQPage | `faq:` array in front matter | No (front matter) |
| HowTo | `howto:` object in front matter | No (front matter) |
| Speakable | `speakable: true` in front matter | No (front matter) |
| Article | Page has `date` and jekyll-seo-tag is NOT installed | Auto (skips when seo-tag present) |

### FAQPage

Add a `faq:` array with `q:` and `a:` pairs to your front matter:

```yaml
---
title: FAQ
faq:
  - q: "What is Jekyll-AEO?"
    a: "A Ruby gem for Answer Engine Optimization."
  - q: "Does it work with jekyll-seo-tag?"
    a: "Yes, they cover different layers and don't conflict."
---
```

### HowTo

Add a `howto:` object with `steps:` to your front matter:

```yaml
---
title: How to Install
howto:
  name: "Install Jekyll-AEO"
  description: "Steps to add Jekyll-AEO to your site"
  totalTime: "PT5M"
  steps:
    - name: "Add to Gemfile"
      text: "Add gem 'jekyll-aeo' to your Gemfile"
    - name: "Install"
      text: "Run bundle install"
    - name: "Build"
      text: "Run bundle exec jekyll build"
---
```

### Speakable

Add `speakable: true` to mark a page's title and first paragraph as voice-assistant-friendly:

```yaml
---
title: About Us
speakable: true
---
```

### jekyll-seo-tag Compatibility

The Article schema automatically skips when jekyll-seo-tag is installed, since seo-tag already outputs BlogPosting (a subtype of Article). All other schema types (FAQPage, HowTo, BreadcrumbList, Organization, Speakable) are always safe — they output different types that don't conflict. Multiple `<script type="application/ld+json">` blocks per page are valid per the JSON-LD spec.

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

## Validation

After building your site, verify AEO output with:

```bash
bundle exec jekyll aeo:validate
```

This checks:
- `llms.txt` exists and starts with an H1 heading
- `llms-full.txt` (if present) is non-empty
- All `.md` files referenced in `llms.txt` exist in the destination directory
- `domain-profile.json` (if present): valid JSON, required fields (`spec`, `name`, `description`, `website`, `contact`), and valid `entity_type` (invalid values emit a warning, not an error)

Respects `baseurl` when resolving file paths.

## Skipped Content

The following are automatically skipped (in order):

- Plugin disabled (`enabled: false`)
- Non-HTML outputs (CSS, JS, etc.)
- Pages with `markdown_copy: false` in front matter
- Redirect pages (`redirect_to` in front matter)
- Documents in the `assets` collection
- `llms.txt` and `llms-full.txt` files
- Paths matching `exclude` prefixes
- Pages with no source file on disk (unless html2dotmd is enabled)

## Development

```bash
bundle install
```

Run unit tests:

```bash
rake test
```

Run all tests (unit + integration — builds the example site):

```bash
rake
```

Build the example site standalone:

```bash
rake site:build
```

Serve the example site locally:

```bash
rake site:serve
```

The integration tests build a full Jekyll site from `demo/example.com/` and verify all generated outputs (llms.txt, robots.txt, domain-profile.json, markdown copies, JSON-LD schemas, link tags).

## License

MIT. Copyright (c) 2026 ZAAI.
