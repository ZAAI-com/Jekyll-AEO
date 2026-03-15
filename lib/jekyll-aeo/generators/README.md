# Generators

## DotMd Writer (`dot_md_writer.rb`)

Generates `.md` companion files for Jekyll pages and documents.

### `dotmd_mode` Front Matter

Controls how the `.md` file is generated per page. Set in YAML front matter:

```yaml
---
dotmd_mode: html2dotmd
---
```

**Values:**

| Value | Description |
|---|---|
| `auto` (default) | Auto-detect: if source contains Liquid, use html2dotmd; otherwise md2dotmd |
| `md2dotmd` | Force source markdown stripping (strips Liquid tags from raw `.md` file) |
| `html2dotmd` | Force HTML-to-markdown conversion (converts rendered HTML output) |
| `disabled` | Skip `.md` generation entirely for this page |

Not setting `dotmd_mode` is equivalent to `auto`.

### Decision Logic

| `dotmd_mode` | Markdown available? | Source has Liquid? | HTML available? | Result |
|---|---|---|---|---|
| `auto` / not set | yes | yes | yes | **html2dotmd** (auto) |
| `auto` / not set | yes | yes | no | **md2dotmd** (fallback) |
| `auto` / not set | yes | no | — | **md2dotmd** |
| `auto` / not set | no | — | yes | **html2dotmd** |
| `auto` / not set | no | — | no | **skipped** |
| `html2dotmd` | — | — | yes | **html2dotmd** |
| `html2dotmd` | — | — | no | **skip + warn** |
| `md2dotmd` | yes | — | — | **md2dotmd** |
| `md2dotmd` | no | — | — | **skip + warn** |
| `disabled` | — | — | — | **skipped** |

- **Markdown available?** — Does the source `.md` file exist on disk?
- **Source has Liquid?** — Does the source body contain `{{` or `{%` patterns?
- **HTML available?** — Does the page object have rendered HTML output (`obj.output`)?

### When to use `html2dotmd`

Use `dotmd_mode: html2dotmd` for pages where the source markdown is mostly Liquid template code (e.g., blog listing pages with `{% for post in site.posts %}`). The md2dotmd path strips all Liquid tags, leaving empty HTML shells. The html2dotmd path converts the fully rendered HTML — preserving dynamic content like post listings.

### URL Map Integration

The `dotmd_mode` column can be added to the URL Map to show which converter was used:

```yaml
jekyll_aeo:
  url_map:
    enabled: true
    columns: [layout, url, url_dotmd, dotmd_mode, skipped, path, page_id, lang, redirects]
```
