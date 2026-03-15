# Jekyll-AEO — Setup Prompt

> Copy this entire document and paste it into your AI coding agent to install and configure [Jekyll-AEO](https://zaai.com/jekyll-aeo) in your Jekyll site.

---

You are helping the user install and configure **Jekyll-AEO**, a RubyGem for Answer Engine Optimization that generates clean markdown copies of Jekyll pages, `llms.txt`/`llms-full.txt` index files, `robots.txt`, `domain-profile.json`, and JSON-LD structured data for LLM consumption.

- Docs: <https://zaai.com/jekyll-aeo>
- Source: <https://github.com/ZAAI-com/Jekyll-AEO>
- Requires: Ruby >= 3.0, Jekyll >= 4.0

Follow the steps below. Ask the user questions where indicated — do not assume preferences.

This prompt works for both **fresh installs** and **updates** to existing sites. During pre-flight checks, detect whether `jekyll-aeo` is already installed. If it is, skip installation/configuration steps and proceed directly to the migration and optimization steps.

---

## Pre-flight Checks

Before starting, verify:

1. A `_config.yml` file exists in the working directory (this is a Jekyll site).
2. A `Gemfile` exists.
3. Ruby version is >= 3.0 (`ruby --version`).
4. Jekyll version is >= 4.0 (check `Gemfile` or run `bundle exec jekyll --version`).
5. **Detect existing installation**: Check if `Gemfile` already contains `jekyll-aeo` and if `_config.yml` already has a `jekyll_aeo:` key. If both are present, this is an **update** — inform the user that Jekyll-AEO is already installed and skip to Step 3. If only one is present, note the partial installation and proceed normally.

If checks 1–4 fail, inform the user and stop.

---

## Step 1 — Install the Gem

If the `Gemfile` already contains `jekyll-aeo`, inform the user and skip this step.

1. Read the `Gemfile`. If it contains a `group :jekyll_plugins` block, add the gem inside that group. Otherwise, add it as a standalone line after other gem declarations.

```ruby
gem "jekyll-aeo"
```

2. Run `bundle install` and confirm it succeeds.

---

## Step 2 — Configure `_config.yml`

If `_config.yml` already contains a `jekyll_aeo:` key, show the user their current configuration and ask if they'd like to review or update it. Do not overwrite existing settings — only add or modify settings the user explicitly requests. Then skip to Step 3.

Jekyll-AEO works with zero configuration. The defaults below are already active — you only need to add settings the user explicitly opts into.

### Configuration Reference

For a fully commented example showing every available setting, read the example config:
<https://github.com/ZAAI-com/Jekyll-AEO/blob/main/demo/example.com/_config.yml>

In that file, settings marked `(default)` are active without any config — you can omit them. Settings marked `(override)` show opt-in features that differ from defaults.

### What's already enabled with zero config

- `.md` companion file for every HTML page (via `dotmd` / `md2dotmd`)
- `llms.txt` + `llms-full.txt` generation
- `<link rel="alternate" type="text/markdown">` tag injection into every HTML page

### Ask the user these questions, then build a minimal config

**Q1 — Exclusions**
"Are there URL prefixes to exclude from markdown generation? Common examples:
- `/admin/`, `/private/` — internal pages
- `/blog/page/` — pagination pages (page 2, 3, etc.)
- `/404` — error pages

Enter prefixes separated by commas, or skip."

**Q2 — robots.txt**
First check if a `robots.txt` file already exists in the source directory. Then ask:
"Would you like Jekyll-AEO to generate a `robots.txt`? It allows search/retrieval bots (Googlebot, ChatGPT-User, Claude-SearchBot, etc.) and blocks training bots (GPTBot, ClaudeBot, Google-Extended, etc.). If you already have a `robots.txt`, the generator will not overwrite it. (yes/no)"

**Q3 — Domain Profile**
"Would you like to generate a `/.well-known/domain-profile.json`? This provides AI assistants with identity metadata about your site per the AI Domain Data spec. (yes/no)"
- If yes: "What is the contact email for the domain profile? (required)"
- If yes: "What entity type describes your site? Options: Organization, Person, Blog, NGO, Community, Project, CreativeWork, SoftwareApplication, Thing. (or skip)"

**Q4 — URL Map**
"Would you like to generate a URL map table at `docs/Url-Map.md` (relative to your project root)? Useful as a development reference. (yes/no)"

**Q5 — Dotmd metadata**
"Should generated `.md` files include a YAML front matter block with title, url, and description? (yes/no)"

**Q6 — html2dotmd (HTML fallback)**
"Do you use Jekyll plugins that generate pages without source files (e.g., jekyll-paginate, jekyll-archives)? Enabling html2dotmd converts their rendered HTML to markdown. (yes/no)"

**Q7 — Include layouts (content allowlist)**
Scan all pages and documents in the site. Collect the distinct `layout` values from front matter across all files. Present the list:
"These layouts are used in your site: `default`, `post`, `page`, ... (list all found)
Which layouts contain content that should be available to LLMs? By default, ALL layouts are included. Setting an allowlist filters out non-content layouts like `redirect` or `archive`. (select all content layouts, or skip to include all)"
- If the user selects specific layouts, add `include_layouts` to config.
- If they skip, omit the key (`null` = include all).

**Q8 — Include collections (content allowlist)**
Read the `collections` key from `_config.yml`. Present the list:
"These collections are defined in your site: `posts`, `docs`, ... (list all found)
Which collections should be part of your AEO output? By default, ALL collections are included. (select all that apply, or skip to include all)"
- If the user selects specific collections, add `include_collections` to config.
- If they skip, omit the key (`null` = include all).

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

First check if `{% aeo_json_ld %}` already exists in the site's layout files — search `_layouts/` and `_includes/` for the string `aeo_json_ld`. If found, inform the user it's already in place and skip to Step 3.5.

The `{% aeo_json_ld %}` tag renders structured data (BreadcrumbList, Organization, FAQPage, HowTo, Speakable, Article) as `<script type="application/ld+json">` blocks.

1. Find the site's base layout — typically `_layouts/default.html` or `_layouts/base.html`. If the layout delegates to an include (e.g., `{% include head.html %}`), edit the include file instead.
2. Add `{% aeo_json_ld %}` inside `<head>`, before `</head>`.
3. If jekyll-seo-tag is installed (check `Gemfile` or `_config.yml` plugins), note that the Article schema auto-skips to avoid conflicts with BlogPosting — no action needed.

If you cannot find a `<head>` section, ask the user which layout file to edit.

---

## Step 3.5 — Migrate Existing JSON-LD Schemas

Search the site's `_layouts/` and `_includes/` directories for existing `<script type="application/ld+json">` blocks. For each schema type detected, offer the appropriate migration:

### FAQPage Migration

Search all layout and include files for `"@type"` occurrences containing `"FAQPage"`. Also search for inline JSON-LD containing `"Question"` and `"acceptedAnswer"`.

If found:
1. Show the user the existing Q&A pairs extracted from the JSON-LD.
2. Identify which page(s) use the layout/include that contains this schema (check for conditionals like `if page.url == "/about/"` or similar).
3. Offer to move each Q&A pair into `faq:` front matter in the relevant page files. The format is:
   ```yaml
   faq:
     - q: "The question text"
       a: "The answer text"
   ```
4. After adding front matter, offer to remove the hardcoded JSON-LD block from the layout/include. The `{% aeo_json_ld %}` tag will now generate the FAQPage schema automatically from the front matter.

### BreadcrumbList Migration

Search for `"@type"` occurrences containing `"BreadcrumbList"` in layout and include files.

If found:
1. Inform the user that `{% aeo_json_ld %}` automatically generates BreadcrumbList from URL path structure — no configuration needed.
2. Offer to remove the manual BreadcrumbList JSON-LD block.
3. Note: AEO auto-generates breadcrumbs for all pages except the homepage.

### Article / BlogPosting Migration

Search for `"@type"` occurrences containing `"Article"` or `"BlogPosting"` in layout and include files.

If found:
1. Check if `jekyll-seo-tag` is installed (look in `Gemfile` for `jekyll-seo-tag`).
2. **If jekyll-seo-tag IS installed**: Inform the user that AEO automatically skips Article schema generation when jekyll-seo-tag is detected, to avoid duplicate/conflicting BlogPosting schemas. The manual implementation can be removed — jekyll-seo-tag handles BlogPosting, and AEO defers to it.
3. **If jekyll-seo-tag is NOT installed**: Offer to remove the manual Article/BlogPosting JSON-LD and let AEO generate Article schema automatically for any page with a `date` field. Note that AEO generates `"@type": "Article"` (not `"BlogPosting"`), and includes `headline`, `url`, `datePublished`, optional `description`, `author`, and `dateModified`.

If no manual JSON-LD schemas are found, skip this step and inform the user: "No manual JSON-LD schemas detected — nothing to migrate."

---

## Step 3.6 — Front Matter Optimization

Suggest adding structured data front matter to key pages:

### Speakable

Ask the user:
"Would you like to enable Speakable structured data on key pages? This marks content as suitable for text-to-speech by voice assistants. Recommended for your homepage and about page. (yes/no)"

If yes:
1. Identify the homepage (typically `index.md` or `index.html`) and an about page (commonly `about.md`, `about/index.md`, or similar).
2. Add `speakable: true` to the front matter of each identified page.

### FAQPage and HowTo

If no FAQ migration was performed in Step 3.5, offer to add `faq:` front matter to pages that would benefit from FAQ structured data — for example, about pages, service pages, or pages with Q&A content.

Similarly, offer `howto:` front matter for any tutorial or guide pages.

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

## Step 4.5 — Cleanup Recommendations

After a successful build, verify the output is clean:

1. Read `_site/llms.txt` and check that it contains only content pages.
2. If `include_layouts` or `include_collections` were configured in Q7/Q8, redirect and archive pages are already filtered automatically.
3. If the allowlists were NOT configured, scan for remaining low-value pages:

### Detect Error Pages

Flag pages whose URL contains common error patterns (`/404`, `/500`, `/error/`) or whose title contains "404", "Not Found", "Error", or "500".

### Detect Low-Value Pages

Read the `.md` files listed in `_site/llms.txt`. Flag any with very short content (under 50 characters) — these may be redirect stubs, empty search pages, or pagination listings.

### Apply Exclusions

For pages the user confirms should be excluded, offer three approaches:
- **Allowlist**: Add `include_layouts` or `include_collections` to filter by layout/collection (best for broad filtering).
- **Per-page**: Add `dotmd_mode: disabled` to the page's front matter (best for individual pages).
- **By prefix**: Add a URL prefix to the `exclude` list under `jekyll_aeo` in `_config.yml` (best when multiple pages share a prefix, e.g., `/error/`).

Recommend the approach that best fits the number and pattern of pages found.

---

## Step 5 — Summary and Next Steps

Tell the user what was installed and configured, then share these next steps:

- **FAQPage schema**: Add `faq:` front matter with `q:`/`a:` pairs to generate FAQ structured data.
- **HowTo schema**: Add `howto:` front matter with `steps:` to generate HowTo structured data.
- **Speakable schema**: Add `speakable: true` to front matter for voice-assistant-friendly pages.
- **Exclude pages**: Set `dotmd_mode: disabled` in any page's front matter to skip markdown generation.
- **Validate after builds**: Run `bundle exec jekyll aeo:validate` after future builds.
- **Re-run this prompt**: This setup prompt is safe to re-run on an already-configured site to check for optimization opportunities (schema migration, cleanup, new features).
- **Full docs**: <https://zaai.com/jekyll-aeo>

Offer to add front matter examples (`faq:`, `howto:`, `speakable: true`) to existing pages if the user wants.
