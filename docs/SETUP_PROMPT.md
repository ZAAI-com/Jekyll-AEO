# Jekyll-AEO — Setup Prompt

> Copy this entire document and paste it into your AI coding agent to install and configure [Jekyll-AEO](https://zaai.com/jekyll-aeo) in your Jekyll site.

---

You are helping the user install and configure **Jekyll-AEO**, a RubyGem for Answer Engine Optimization that generates clean markdown copies of Jekyll pages, `llms.txt`/`llms-full.txt` index files, `robots.txt`, `domain-profile.json`, and JSON-LD structured data for LLM consumption.

- Docs: <https://zaai.com/jekyll-aeo>
- Source: <https://github.com/ZAAI-com/Jekyll-AEO>
- Requires: Ruby >= 3.0, Jekyll >= 4.0

Follow the steps below. Ask the user questions where indicated — do not assume preferences.

---

## Pre-flight Checks

Before starting, verify:

1. A `_config.yml` file exists in the working directory (this is a Jekyll site).
2. A `Gemfile` exists.
3. Ruby version is >= 3.0 (`ruby --version`).
4. Jekyll version is >= 4.0 (check `Gemfile` or run `bundle exec jekyll --version`).

If any check fails, inform the user and stop.

---

## Step 1 — Install the Gem

1. Read the `Gemfile`. If it contains a `group :jekyll_plugins` block, add the gem inside that group. Otherwise, add it as a standalone line after other gem declarations.

```ruby
gem "jekyll-aeo"
```

2. Run `bundle install` and confirm it succeeds.

---

## Step 2 — Configure `_config.yml`

Jekyll-AEO works with zero configuration. The defaults below are already active — you only need to add settings the user explicitly opts into.

### Default Configuration (do NOT add these unless overriding)

```
enabled: true
exclude: []
dotmd:
  link_tag: "auto"
  include_last_modified: true
  dotmd_metadata: false
  md2dotmd:
    strip_block_tags: true
    protect_indented_code: false
  html2dotmd:
    enabled: false
    selector: null  # (auto-detects main > article > body)
llms_txt:
  enabled: true
  description: null
  sections: null  (auto-generated from collections)
  front_matter_keys: []
  show_lastmod: false
  include_descriptions: true
llms_full_txt:
  enabled: true
  description: null
  full_txt_mode: "all"
url_map:
  enabled: false
  output_filepath: "docs/Url-Map.md"
  columns: [page_id, url, lang, layout, path, redirects, markdown_copy, skipped]
robots_txt:
  enabled: false
  allow: [Googlebot, Bingbot, OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, PerplexityBot, Applebot-Extended]
  disallow: [GPTBot, ClaudeBot, Google-Extended, Meta-ExternalAgent, Amazonbot]
  include_sitemap: true
  include_llms_txt: true
  custom_rules: []
domain_profile:
  enabled: false
  name: null
  description: null
  website: null
  contact: null
  logo: null
  entity_type: null
  jsonld: null
```

### What's already enabled with zero config

- `.md` companion file for every HTML page (via `dotmd` / `md2dotmd`)
- `llms.txt` + `llms-full.txt` generation
- `<link rel="alternate" type="text/markdown">` tag injection into every HTML page

### Ask the user these questions, then build a minimal config

**Q1 — Exclusions**
"Are there URL prefixes to exclude from markdown generation? Common examples: `/admin/`, `/private/`, `/error/`. Enter prefixes separated by commas, or skip."

**Q2 — robots.txt**
First check if a `robots.txt` file already exists in the source directory. Then ask:
"Would you like Jekyll-AEO to generate a `robots.txt`? It allows search/retrieval bots (Googlebot, ChatGPT-User, Claude-SearchBot, etc.) and blocks training bots (GPTBot, ClaudeBot, Google-Extended, etc.). If you already have a `robots.txt`, the generator will not overwrite it. (yes/no)"

**Q3 — Domain Profile**
"Would you like to generate a `/.well-known/domain-profile.json`? This provides AI assistants with identity metadata about your site per the AI Domain Data spec. (yes/no)"
- If yes: "What is the contact email for the domain profile? (required)"
- If yes: "What entity type describes your site? Options: Organization, Person, Blog, NGO, Community, Project, CreativeWork, SoftwareApplication, Thing. (or skip)"

**Q4 — URL Map**
"Would you like to generate a URL map table at `docs/Url-Map.md` in your source directory? Useful as a development reference. (yes/no)"

**Q5 — Dotmd metadata**
"Should generated `.md` files include a YAML front matter block with title, url, and description? (yes/no)"

**Q6 — html2dotmd (HTML fallback)**
"Do you use Jekyll plugins that generate pages without source files (e.g., jekyll-paginate, jekyll-archives)? Enabling html2dotmd converts their rendered HTML to markdown. (yes/no)"

### Build and insert the config

Based on the user's answers, construct a `jekyll_aeo:` YAML block containing **only** settings that differ from the defaults above. Append it to `_config.yml` with a comment header:

```yaml
# Jekyll-AEO: Answer Engine Optimization
# Docs: https://zaai.com/jekyll-aeo
jekyll_aeo:
  # ... only non-default settings here ...
  # dotmd settings nest under: dotmd.md2dotmd / dotmd.html2dotmd
```

If the user accepted all defaults (no exclusions, no opt-in features), you can skip this step entirely — the gem works without any config entry.

---

## Step 3 — Add the JSON-LD Liquid Tag

The `{% aeo_json_ld %}` tag renders structured data (BreadcrumbList, Organization, FAQPage, HowTo, Speakable, Article) as `<script type="application/ld+json">` blocks.

1. Find the site's base layout — typically `_layouts/default.html` or `_layouts/base.html`. If the layout delegates to an include (e.g., `{% include head.html %}`), edit the include file instead.
2. Add `{% aeo_json_ld %}` inside `<head>`, before `</head>`.
3. If jekyll-seo-tag is installed (check `Gemfile` or `_config.yml` plugins), note that the Article schema auto-skips to avoid conflicts with BlogPosting — no action needed.

If you cannot find a `<head>` section, ask the user which layout file to edit.

---

## Step 4 — Build and Validate

1. Run `bundle exec jekyll build`.
2. Run `bundle exec jekyll aeo:validate`.
3. Verify generated files:
   - `_site/llms.txt` exists — show the first 10 lines.
   - `_site/llms-full.txt` exists — report file size.
   - At least one `.md` companion file exists in `_site/`.
   - If robots.txt was enabled: `_site/robots.txt` exists.
   - If domain-profile was enabled: `_site/.well-known/domain-profile.json` exists.
4. Report any warnings or errors to the user.

---

## Step 5 — Summary and Next Steps

Tell the user what was installed and configured, then share these next steps:

- **FAQPage schema**: Add `faq:` front matter with `q:`/`a:` pairs to generate FAQ structured data.
- **HowTo schema**: Add `howto:` front matter with `steps:` to generate HowTo structured data.
- **Speakable schema**: Add `speakable: true` to front matter for voice-assistant-friendly pages.
- **Exclude pages**: Set `markdown_copy: false` in any page's front matter to skip markdown generation.
- **Validate after builds**: Run `bundle exec jekyll aeo:validate` after future builds.
- **Full docs**: <https://zaai.com/jekyll-aeo>

Offer to add front matter examples (`faq:`, `howto:`, `speakable: true`) to existing pages if the user wants.
