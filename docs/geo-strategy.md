# GEO Strategy: Ranking Better in LLM Chat Apps

## Context

This document provides a comprehensive Generative Engine Optimization (GEO) strategy for increasing visibility and citation frequency in LLM-powered chat applications (ChatGPT, Perplexity, Claude, Gemini, Google AI Overviews). The Jekyll-AEO gem already implements several foundational GEO techniques (llms.txt, markdown copies, content stripping). This research identifies all known levers for improving AI visibility — both what the gem covers and what lies beyond it.

**Key market signal:** Gartner projects traditional search traffic will decline 25% by 2026. 35% of US consumers now use AI for product discovery. AI-referred sessions grew 527% in early 2025.

---

## 1. Technical Foundation (Machine-Readable Content)

### 1.1 llms.txt & llms-full.txt
- **What:** Markdown-formatted site index (llms.txt) and full-content file (llms-full.txt) per the llmstxt.org spec by Jeremy Howard (Answer.AI)
- **Status:** Jekyll-AEO already implements this
- **Impact:** Only ~10% of sites have adopted this. No AI engine officially crawls it yet, but adoption is accelerating (Mintlify rolled it out across thousands of docs sites including Anthropic and Cursor). Early-mover advantage is high.
- **Optimization:** llms-full.txt achieves 90%+ token reduction vs. HTML, making it the most efficient format for AI consumption

### 1.2 Clean Markdown Copies of Every Page
- **What:** Per-page `.md` files stripped of Liquid, kramdown, and developer syntax
- **Status:** Jekyll-AEO already implements this
- **Impact:** Markdown reduces token consumption 20-30% vs. HTML. AI crawlers (except Google) do not render JavaScript, so clean server-rendered content is essential.

### 1.3 URL Map / Site Structure
- **What:** Machine-readable map of all pages with metadata (URL, language, layout, redirects)
- **Status:** Jekyll-AEO has this as optional feature (url-map.md)
- **Impact:** Helps AI systems understand site structure and page relationships

### 1.4 Schema.org / JSON-LD Structured Data
- **What:** Structured data markup (FAQPage, Article, Organization, HowTo, Product)
- **Status:** NOT in Jekyll-AEO — separate concern (theme/plugin level)
- **Impact:** 2.5x higher citation chance overall. FAQPage schema gives 3.2x higher chance of appearing in AI Overviews. Article schema provides 47% more context for AI extraction.
- **Caveat:** AI systems extract JSON-LD through search indexes, NOT during direct page fetch. This means it works indirectly by improving how search engines understand your content, which AI systems then leverage.
- **Key schemas:**
  - `FAQPage` — highest impact for AI Overviews
  - `Article` / `BlogPosting` — authorship, dates, topics
  - `Organization` — brand identity and authority
  - `HowTo` — step-by-step processes
  - `Product` / `Review` — e-commerce visibility
  - `BreadcrumbList` — site hierarchy

### 1.5 Robots.txt Configuration for AI Crawlers
- **What:** Allow AI search/retrieval bots while optionally blocking training bots
- **Recommended 2026 strategy:** Block training bots, allow search/retrieval bots
- **Known AI crawlers:**

| Company | Search/Retrieval Bot | Training Bot | Notes |
|---------|---------------------|--------------|-------|
| OpenAI | OAI-SearchBot, ChatGPT-User | GPTBot | ChatGPT-User no longer respects robots.txt |
| Anthropic | Claude-SearchBot, Claude-User | ClaudeBot | Respects robots.txt + Crawl-delay |
| Perplexity | PerplexityBot, Perplexity-User | — | Perplexity-User ignores robots.txt |
| Google | Googlebot | Google-Extended | Only platform that renders JavaScript |
| Microsoft | Bingbot | — | ChatGPT citations match Bing 87% |
| Apple | Applebot-Extended | Applebot | For Apple Intelligence |
| Meta | — | Meta-ExternalAgent | Training only |
| Amazon | — | Amazonbot | Training/Alexa |

### 1.6 Emerging Standards
- **ai.txt** (Spawning.ai): Controls AI training permissions specifically
- **IETF AI Preferences Working Group** (January 2026): Modernizing robots.txt with intent-based policies (training vs. indexing vs. inference), API endpoint discovery, and WebBotAuth cryptographic verification
- **Action:** Monitor these standards; they are not yet widely adopted but represent the future direction

---

## 2. Content Optimization for AI Citation

### 2.1 Answer-First Content Structure
- Lead every page/section with a direct, concise answer to the implied question
- AI systems extract the first 50-150 words of a topically relevant section most frequently
- Self-contained paragraphs (50-150 words) get 2.3x more citations than longer blocks
- Structure: Answer → Evidence → Detail → Related topics

### 2.2 Fact Density & Evidence
- **Statistics:** Pages with 19+ statistics get 5.4 avg citations vs. 2.8 without
- **Expert quotes:** Pages with quotes get 4.1 avg citations vs. 2.4 without
- **Cited sources:** Adding inline citations (academic papers, studies) significantly boosts credibility
- The Princeton/Georgia Tech GEO paper found the top 3 optimization methods are: **Cite Sources, Quotation Addition, Statistics Addition** — each improving visibility 30-40%

### 2.3 Content Formatting
- Clear H2/H3 hierarchy (AI systems use headings as semantic boundaries)
- 120-180 words per section (optimal chunk size for RAG retrieval)
- Tables for comparisons (AI loves structured tabular data)
- Numbered lists for processes and steps
- Bullet lists for features and options
- Neutral, encyclopedic tone (opinion-heavy content gets cited less)

### 2.4 Keyword stuffing is INEFFECTIVE
- The academic research explicitly found keyword stuffing does not work for GEO
- Focus on topical authority and comprehensiveness instead

### 2.5 Content Freshness
- Visibility drops 2-3 days after publication without updates
- 30-90 day refresh cadence recommended
- AI systems prefer recent, updated content
- Include visible "last updated" dates

### 2.6 Best Optimization Combo
- Per the GEO academic paper: **Fluency Optimization + Statistics Addition** yields +5.5% improvement over any single technique
- Fluency = clear, well-written, grammatically perfect prose
- Statistics = concrete numbers, percentages, data points

---

## 3. Authority & Brand Signals

### 3.1 Domain Authority (Strongest Predictor)
- Brand authority has a 0.334 correlation with AI citation — the single strongest predictor
- Referring domains (backlinks) are the strongest predictor for ChatGPT specifically
- Domain traffic volume correlates with citation frequency
- **This is the hardest lever to pull but the most impactful**

### 3.2 Multi-Platform Presence
- Brands present on 4+ channels get significantly more AI citations
- Critical platforms for AI visibility:
  - **Wikipedia** — ChatGPT's most-cited source (47.9% of top-10 citations, 7.8% of all citations)
  - **Reddit** — Leads overall AI citations at 40.1%; Perplexity references Reddit in 47% of responses
  - **Industry publications** — Niche authority signals
  - **GitHub** — For technical/developer audiences
  - **Stack Overflow** — For technical Q&A visibility
  - **YouTube** — Google AI Overviews reference video content
  - **LinkedIn** — Professional/B2B visibility

### 3.3 Platform-Specific Preferences
- **ChatGPT:** Heavily weights referring domains, domain traffic; favors Wikipedia; citations match Bing 87% of the time
- **Perplexity:** Prioritizes credibility, recency, semantic relevance, and clarity; favors Reddit
- **Claude:** Mentions brands in 97.3% of responses (highest rate); matches Brave Search 86.7%
- **Google AI Overviews:** Most conservative with brand mentions (48.5% of responses); favors schema markup
- **Cross-platform overlap is LOW** — only 21-25% of cited domains are shared between platforms, meaning platform-specific strategies are necessary

### 3.4 E-E-A-T Signals (Experience, Expertise, Authoritativeness, Trustworthiness)
- Author bios with credentials on content pages
- About pages with organizational expertise
- Clear sourcing and citation of claims
- Professional, well-maintained site (no broken links, fast loading)

---

## 4. Content Architecture Strategies

### 4.1 Topical Authority Clusters
- Build comprehensive content hubs around core topics
- Interlink cluster pages with a pillar page
- AI systems favor sites that demonstrate deep expertise on a topic rather than shallow coverage of many topics

### 4.2 FAQ Content
- Dedicated FAQ pages/sections aligned with actual AI queries
- Each Q&A should be self-contained (the answer should make sense without the rest of the page)
- Use FAQPage schema markup for these sections

### 4.3 Comparison & "Best of" Content
- AI frequently answers "what is the best X" or "X vs Y" queries
- Structured comparison tables are highly citable
- Include clear recommendations with reasoning

### 4.4 Definition & Explainer Content
- "What is X" content gets high AI citation rates
- Lead with a 1-2 sentence definition
- Follow with detailed explanation, examples, and context

### 4.5 How-To & Process Content
- Step-by-step guides with numbered steps
- Each step should be concise and actionable
- Use HowTo schema markup

---

## 5. Technical SEO for AI Discovery

### 5.1 Server-Side Rendering (Critical)
- No AI crawler except Google renders JavaScript
- All content must be available in the initial HTML response
- Jekyll is SSG by default, so this is inherently handled

### 5.2 Sitemap.xml
- Standard XML sitemaps help AI crawlers discover content
- Include lastmod dates (AI systems weight recency)
- Submit to Google Search Console, Bing Webmaster Tools

### 5.3 Page Speed & Availability
- AI crawlers have timeouts; slow pages may not be fully indexed
- Ensure high uptime — crawl failures mean missed indexing windows

### 5.4 Canonical URLs
- Prevent duplicate content confusion for AI systems
- Ensure canonical tags point to the preferred version

### 5.5 Internal Linking
- Strong internal linking helps AI crawlers discover and understand content relationships
- Use descriptive anchor text (not "click here")

---

## 6. Monitoring & Measurement

### 6.1 Key Metrics
| Metric | Description |
|--------|-------------|
| Citation Frequency | How often your brand/content is cited in AI responses |
| Share of Voice | (Your mentions / Total AI responses for topic) × 100 |
| Mention Sentiment | Positive, neutral, or negative brand mentions |
| Citation Position | Where in the AI response your brand appears |
| Platform Coverage | Which AI platforms cite you |
| Query Coverage | Which queries trigger citations of your content |
| Citation Velocity | Rate of change in citation frequency |

**Benchmarks:** 10-15% share of voice is good; 25-40% is market-leader territory.

### 6.2 Monitoring Tools

**Enterprise:**
| Tool | Price | Platforms | Key Feature |
|------|-------|-----------|-------------|
| Profound | $499/mo | 10+ AI platforms | Sequoia-backed, most platforms |
| Goodie AI | $495/mo | Multiple | Most complete GEO platform |
| Conductor AI | Enterprise | Multiple | Full enterprise GEO suite |
| AthenaHQ | Enterprise | Multiple | AI brand monitoring |
| Peec AI | €89/mo | Multiple | Daily metrics, European |

**Budget-Friendly:**
| Tool | Price | Key Feature |
|------|-------|-------------|
| Otterly.AI | $29/mo | 40+ countries, 6 platforms |
| HubSpot AEO Grader | Free | Scores visibility across GPT-4o, Perplexity, Gemini |
| Hall | Free tier | Tracks page citations across AI conversations |
| LLMRefs | Free | Checks if AI engines reference your site |

**Technical:**
| Tool | Purpose |
|------|---------|
| SerpAPI | Programmatic Google AI Mode citation tracking |
| Cloudflare AI Audit / Robotcop | AI crawler monitoring and enforcement |
| Am I Cited | Crawler activity tracking |
| Server log analysis | Monitor AI bot user agents directly |

### 6.3 Measurement Challenges
- **"Visibility without traffic"** — content can be cited thousands of times without generating website visits (the AI provides the answer directly)
- Traditional analytics (GA4, etc.) don't capture AI citation visibility
- Different platforms have wildly different source preferences (only 21-25% overlap)
- No AI company provides a public API to query "is my URL in your index/training data"

---

## 7. Proven Results & Benchmarks

| Company | Result | Method |
|---------|--------|--------|
| LS Building Products | 540% boost in AI Overviews mentions | Content restructuring + schema |
| Go Fish Digital | AI traffic converts at 25x traditional search | GEO optimization |
| Smart Rent | 40% faster sales pipeline | AI-sourced prospects |
| Ramp | Citation share 8.1% → 12.2% in one month | Profound monitoring + optimization |
| Runpod | 4x customer growth in 90 days | Content architecture redesign |
| AirOps | 5x faster content refreshes, 20x traffic growth | AI-assisted content ops |

**B2B SaaS companies report 6-27x higher conversion rates from AI traffic vs. traditional search.**

---

## 8. Complete Strategy Checklist

### Technical (Machine-Readable)
- [ ] Generate llms.txt and llms-full.txt (Jekyll-AEO ✅)
- [ ] Generate clean markdown copies of all pages (Jekyll-AEO ✅)
- [ ] Generate URL map with page metadata (Jekyll-AEO ✅)
- [ ] Implement Schema.org JSON-LD (FAQPage, Article, Organization, HowTo)
- [ ] Configure robots.txt to allow AI search bots, block training bots
- [ ] Ensure all content is server-side rendered (Jekyll SSG ✅)
- [ ] Maintain XML sitemap with lastmod dates
- [ ] Set up canonical URLs
- [ ] Monitor and adopt emerging standards (ai.txt, IETF AI Preferences)

### Content Optimization
- [ ] Restructure content to answer-first format
- [ ] Add statistics and data points to key pages (target 19+ per page)
- [ ] Add expert quotes and citations to authoritative sources
- [ ] Keep paragraphs self-contained at 50-150 words
- [ ] Use H2/H3 hierarchy with 120-180 words per section
- [ ] Add comparison tables for "vs." and "best of" content
- [ ] Create FAQ sections with FAQPage schema
- [ ] Remove opinion-heavy language; adopt neutral, encyclopedic tone
- [ ] Implement 30-90 day content refresh cycle
- [ ] Add visible "last updated" dates

### Authority Building
- [ ] Build backlink profile (strongest predictor for ChatGPT)
- [ ] Create/maintain Wikipedia presence
- [ ] Build active Reddit presence in relevant subreddits
- [ ] Publish on 4+ channels (GitHub, LinkedIn, YouTube, industry pubs)
- [ ] Add author bios with credentials
- [ ] Create comprehensive About/Organization pages

### Content Architecture
- [ ] Build topical authority clusters with pillar pages
- [ ] Create "What is X" definition pages for core terms
- [ ] Create comparison/review content with structured tables
- [ ] Create step-by-step guides with HowTo schema
- [ ] Ensure strong internal linking with descriptive anchors

### Monitoring
- [ ] Set up AI visibility monitoring tool (Otterly.AI for budget, Profound for enterprise)
- [ ] Run HubSpot AEO Grader as baseline assessment (free)
- [ ] Monitor server logs for AI crawler user agents
- [ ] Track citation frequency and share of voice monthly
- [ ] Monitor cross-platform coverage (ChatGPT, Perplexity, Claude, Gemini)

---

## 9. What Jekyll-AEO Already Covers vs. Gaps

### Already Implemented
- ✅ llms.txt generation (site index for AI)
- ✅ llms-full.txt generation (full content in one file)
- ✅ Per-page markdown copies (clean, token-efficient)
- ✅ Content stripping (Liquid, kramdown, developer syntax)
- ✅ Code block protection during stripping
- ✅ URL map generation (optional)
- ✅ Server-side rendered output (Jekyll SSG)
- ✅ Configurable exclusion patterns
- ✅ Collection-aware section generation

### Implementation Plan (V1 Full Scope)

#### Integration Strategy

**robots.txt vs. jekyll-sitemap:**
- jekyll-sitemap uses `Jekyll::Generator` with `priority :lowest` and calls `file_exists?("/robots.txt")` before generating
- Jekyll-AEO uses a Generator with `priority :low` (higher than `:lowest`) → jekyll-sitemap detects ours and skips its own
- Jekyll-AEO also checks if user has their own robots.txt and skips if so
- Jekyll-AEO includes `Sitemap:` directive so nothing from jekyll-sitemap is lost
- **Result: No conflict. jekyll-sitemap yields automatically.**

**JSON-LD vs. jekyll-seo-tag:**
- jekyll-seo-tag outputs ONE `<script type="application/ld+json">` block per page via `{% seo %}` Liquid tag
- It ONLY outputs: WebSite (homepage), BlogPosting (dated pages), WebPage (default)
- There is NO way to disable its JSON-LD separately (issue #135, filed 2016, never implemented)
- Jekyll-AEO outputs DIFFERENT types: FAQPage, HowTo, BreadcrumbList, Organization, Speakable
- Multiple JSON-LD blocks per page are valid per JSON-LD spec; Google processes all
- Jekyll-AEO detects seo-tag via `Liquid::Template.tags.key?("seo")` and skips Article when present
- **Result: No conflict. Different schema types in separate `<script>` blocks.**

#### P1 — Quick Wins
1. **AI-aware robots.txt generator** (`lib/jekyll-aeo/generators/robots_txt.rb`)
   - New `Jekyll::Generator` with `priority :low` (not `:lowest`)
   - Checks `site.pages` for existing `/robots.txt` → skips if user has their own
   - jekyll-sitemap checks after us and skips its own when ours exists
   - Defaults: allow search/retrieval bots, block training bots
   - Include `Sitemap:` and `Llms-txt:` directives
   - Fully configurable via `jekyll_aeo.robots_txt` in `_config.yml`
   - Disabled by default (opt-in) to avoid surprises

2. **Last-modified metadata in .md files** (modify `lib/jekyll-aeo/generators/markdown_page.rb`)
   - Prepend `> Last updated: YYYY-MM-DD` after title/description header
   - Source: `last_modified_at` front matter → `date` front matter → filesystem mtime
   - Config: `jekyll_aeo.include_last_modified: true` (default: true)

3. **llms.txt description enrichment** (modify `lib/jekyll-aeo/generators/llms_txt.rb`)
   - Change link format from `- [Title](url)` to `- [Title](url): Description`
   - Source: page `description` from front matter
   - Falls back to current format when no description available

#### P2 — Metadata & Schema
4. **Structured metadata header in .md files** (modify `lib/jekyll-aeo/generators/markdown_page.rb`)
   - Add YAML-style metadata block at top of each .md file:
     ```
     ---
     title: Page Title
     url: /page/
     canonical: https://example.com/page/
     description: Page description
     author: Author Name
     date: 2026-03-10
     last_modified: 2026-03-12
     lang: en
     ---
     ```
   - Config: `jekyll_aeo.md_metadata: true` (default: false, to avoid breaking existing output)

5. **`{% aeo_json_ld %}` Liquid tag** (new files)
   - `lib/jekyll-aeo/tags/json_ld_tag.rb` — Liquid tag registration
   - `lib/jekyll-aeo/schema/` directory with one builder per type:
     - `faq_page.rb` — detects `faq:` array in front matter
     - `how_to.rb` — detects `howto:` object in front matter
     - `breadcrumb_list.rb` — auto-generated from URL path
     - `organization.rb` — from `_config.yml`, homepage only by default
     - `speakable.rb` — detects `speakable: true` in front matter
     - `article.rb` — dated pages, only when jekyll-seo-tag is NOT installed
   - Each builder returns a Hash; tag renders all as `<script type="application/ld+json">`
   - Multiple blocks per page (one `<script>` per schema type)

   **Detection logic:**
   | Schema | Trigger | Auto? |
   |--------|---------|-------|
   | BreadcrumbList | URL path (every page except homepage) | Yes |
   | Organization | `_config.yml` organization config present | Yes (homepage only by default) |
   | FAQPage | `faq:` array in front matter with `q:` + `a:` | No (front matter) |
   | HowTo | `howto:` object in front matter with `steps:` | No (front matter) |
   | Speakable | `speakable: true` in front matter | No (front matter) |
   | Article | Page has `date` AND `Liquid::Template.tags.key?("seo")` is false | Auto (skips when seo-tag present) |

   **jekyll-seo-tag conflict avoidance:**
   ```ruby
   # In json_ld_tag.rb
   def seo_tag_present?(context)
     Liquid::Template.tags.key?("seo") ||
       context.registers[:site].config.dig("plugins")&.include?("jekyll-seo-tag")
   end
   ```
   - When seo-tag detected: skip Article (it already outputs BlogPosting, a subtype)
   - All other types (FAQPage, HowTo, BreadcrumbList, Organization, Speakable) are always safe

#### Complete Config Reference
```yaml
jekyll_aeo:
  # ── Existing (unchanged) ──
  enabled: true                      # Master switch
  md_path_style: "clean"             # "clean" or "spec"
  strip_block_tags: true             # Strip comment/capture blocks
  protect_indented_code: false       # Protect 4-space indented code
  exclude: []                        # URL prefixes to skip

  # ── Existing: llms.txt ──
  llms_txt:
    enabled: true
    description: ""
    full_txt_mode: "all"             # "all" or "linked"
    include_descriptions: true       # NEW: add page descriptions to links
    sections: null

  # ── Existing: URL Map ──
  url_map:
    enabled: false
    output_path: "url-map.md"
    columns: [...]

  # ── NEW: Markdown enhancements ──
  include_last_modified: true        # Add "Last updated" to .md files
  md_metadata: false                 # Add YAML front matter to .md files

  # ── NEW: robots.txt ──
  robots_txt:
    enabled: false                   # Disabled by default (opt-in)
    allow:                           # Search/retrieval bots
      - Googlebot
      - Bingbot
      - OAI-SearchBot
      - ChatGPT-User
      - Claude-SearchBot
      - Claude-User
      - PerplexityBot
      - Applebot-Extended
    disallow:                        # Training bots to block
      - GPTBot
      - ClaudeBot
      - Google-Extended
      - Meta-ExternalAgent
      - Amazonbot
    include_sitemap: true            # Add Sitemap: directive
    include_llms_txt: true           # Add Llms-txt: directive
    custom_rules: []                 # Additional raw lines

  # ── NEW: JSON-LD ──
  json_ld:
    enabled: true                    # Master switch for {% aeo_json_ld %}
    faq: true                        # Detect faq: in front matter
    howto: true                      # Detect howto: in front matter
    breadcrumbs: true                # Auto BreadcrumbList from URL path
    speakable: true                  # Detect speakable: in front matter
    article: true                    # Article schema (auto-skips if seo-tag)
    organization:                    # null = disabled
      name: null
      url: null
      logo: null
      sameAs: []
      output_on: "homepage"          # "homepage", "all", or "none"
```

#### Files to Create
- `lib/jekyll-aeo/generators/robots_txt.rb`
- `lib/jekyll-aeo/tags/json_ld_tag.rb`
- `lib/jekyll-aeo/schema/faq_page.rb`
- `lib/jekyll-aeo/schema/how_to.rb`
- `lib/jekyll-aeo/schema/breadcrumb_list.rb`
- `lib/jekyll-aeo/schema/organization.rb`
- `lib/jekyll-aeo/schema/speakable.rb`
- `lib/jekyll-aeo/schema/article.rb`
- `test/generators/robots_txt_test.rb`
- `test/tags/json_ld_tag_test.rb`
- `test/schema/` (one test per schema type)

#### Files to Modify
- `lib/jekyll-aeo.rb` — require new files
- `lib/jekyll-aeo/config.rb` — add defaults for robots_txt, json_ld, include_last_modified, md_metadata
- `lib/jekyll-aeo/hooks.rb` — add robots.txt generation call
- `lib/jekyll-aeo/generators/markdown_page.rb` — add last_modified + metadata header
- `lib/jekyll-aeo/generators/llms_txt.rb` — add descriptions to links
- `test/config_test.rb` — test new defaults

#### Verification
1. `rake test` — all existing + new tests pass
2. Build a test Jekyll site with the gem and verify:
   - `robots.txt` output with correct bot rules
   - `.md` files have last-modified dates and optional metadata headers
   - `llms.txt` links include descriptions
   - `{% aeo_json_ld %}` outputs correct JSON-LD for each schema type
   - JSON-LD validates at https://validator.schema.org/
   - No conflicts when jekyll-seo-tag is also installed

---

## 10. Academic Foundation

**Primary paper:** "GEO: Generative Engine Optimization" (arXiv:2311.09735, ACM SIGKDD 2024) — Princeton, Georgia Tech, Allen AI, IIT Delhi
- Tested 9 optimization methods on 10,000-query benchmark
- Top 3 methods: Cite Sources, Quotation Addition, Statistics Addition (each +30-40% visibility)
- Best combination: Fluency Optimization + Statistics Addition (+5.5% over any single technique)
- Keyword stuffing found INEFFECTIVE for GEO
- The paper coined the term "Generative Engine Optimization"

---

## 11. Additional GEO Strategies

### 11.1 Knowledge Graph & Entity SEO
- Ensure your brand exists in **Wikidata** (Q-ID) and **Google Knowledge Graph**
- Add `sameAs` properties in JSON-LD pointing to your Wikidata URL
- Topical authority (r=0.4) is the strongest predictor of AI citations — stronger than Domain Authority (r=0.18)
- Only 17-38% of pages cited in Google AI Overviews ranked in top 10 by early 2026 (down from 76% in mid-2025), meaning entity authority is overtaking traditional ranking signals

### 11.2 Conversational Content Optimization
- AI prompts are 60% longer than Google queries; 75% of ChatGPT search prompts are 5+ words
- Use question-style H2 headings matching real conversational queries
- Provide direct 75-120 word answers in first sentences of each section
- Authoritative tone makes content 30% more likely to appear in AI answers

### 11.3 AI Shopping Optimization
- **Google Universal Commerce Protocol (UCP)** and **OpenAI/Stripe Agentic Commerce Protocol (ACP)** — open standards for AI agents to discover and purchase products
- Product attribute completion of 99.9% ("Golden Record") yields 3-4x higher AI visibility
- AI-guided shopping sessions show 100% surge in purchase sessions vs. non-AI
- ChatGPT users can already buy from Etsy and soon 1M+ Shopify merchants in chat

### 11.4 Video SEO for AI
- YouTube is cited 200x more than any other video platform in AI answers
- Google AI Overviews favor video for up to 29.5% of summaries
- Provide full transcripts, chapter timestamps, and named entities
- Structure videos around "what," "how," and "why" questions

### 11.5 Social Proof & Reviews
- Sites with recent positive reviews get 40% more AI mentions
- LLMs cite Reddit and editorial content for 60%+ of brand information, not corporate websites
- Reddit leads all sources at 40.1% citation frequency (though declining ~50% between Oct 2025-Jan 2026)
- Review scores should be above 3.5/5 on third-party sites (G2, Capterra, Trustpilot)

### 11.6 Digital PR for AI Visibility
- Press release citations grew 5x in 2025
- 94% of AI citations come from earned (not paid) media sources
- ChatGPT and Gemini show highest press release citation rates
- New PR metric: "machine citations" instead of impressions/backlinks

### 11.7 LLM Seeding (Content Syndication)
- Strategically plant structured brand information across trusted sources (Reddit, Quora, Medium, LinkedIn, review sites)
- Increases brand mention frequency ~45% across LLMs within 60-90 days
- Must be high-quality and authentic — AI detects artificial content

### 11.8 API & Data Feed Strategies
- **MCP (Model Context Protocol)** servers expose data directly to AI agents — 97M monthly SDK downloads, adopted by all major AI providers
- **Cloudflare AI Index** auto-creates AI-optimized search indexes with zero config
- Structured data improves GPT-4 accuracy from 16% to 54% (Data World study)

### 11.9 Voice Search AI Optimization
- 8.4 billion voice-enabled devices globally; 60% of mobile voice queries are "near me"
- Voice commerce projected to exceed $100B globally by 2026
- Optimize for featured snippets (Google Assistant relies on them)
- Use `speakable` schema markup

### 11.10 Local SEO for AI
- ChatGPT triggers web search for 59% of local-intent prompts
- Local businesses using AI-driven SEO see 4.4x higher conversion rates
- Complete Google Business Profile, Yelp, Apple Business Connect
- Use LocalBusiness and GeoCoordinates schema

### 11.11 Negative AI SEO / Hallucination Management
- LLMs can hallucinate false brand information with confidence
- "AI poisoning" attack: 250 malicious documents can influence LLM outputs
- Monitor with tools like Waikay.io (hallucination detection)
- Correct inaccurate Wikipedia/Wikidata entries, respond to Reddit threads, create authoritative "source of truth" content

### 11.12 International / Multilingual AI SEO
- AI models collapse multilingual content into shared semantic representations — the most confident version (often English) wins
- Simple translations are penalized; genuine localization ("transcreation") required
- Multilingual SEO with AI optimization delivers up to 327% more visibility
- Proper hreflang, Wikidata multilingual labels, region-specific schema

### 11.13 Open Graph & Meta Tags for AI
- OG tags provide labeled signals AI crawlers use to interpret content
- Meta's LLaMA 3 confirmed trained on publicly shared Facebook/Instagram posts — OG tags on social-shared content enter training data
- Combine OG tags with JSON-LD for maximum discoverability

### 11.14 Prompt Research (New Discipline)
- Study multi-turn conversational sequences users employ on AI platforms
- Four-stage framework: prompt discovery → intent clustering → content mapping → structural optimization
- Distinct from keyword research — focuses on conversational patterns, not single keywords

### 11.15 AI Chatbot Integrations
- Build MCP servers to expose data/tools directly to AI agents
- Implement ACP endpoints for commerce
- Perplexity offers data-source enrichment integrations (Tripadvisor, Crunchbase)
- Enterprise knowledge base integrations for B2B visibility

---

## 12. Jekyll Plugin Ecosystem Coverage

### 12.1 jekyll-seo-tag (v2.8.0, ~1.4M projects)
**What it covers:**
- HTML meta tags: title, description, author, canonical, prev/next
- Open Graph: og:title, og:description, og:url, og:site_name, og:locale, og:image, og:type
- Twitter Cards: summary/summary_large_image, title, description, image
- Webmaster verification: Google, Bing, Yandex, Baidu, Alexa, Facebook
- JSON-LD: WebSite (homepage), BlogPosting (dated pages), WebPage (default)
- Author as Person/Organization, publisher with logo, sameAs links

**What it does NOT cover (gaps for GEO):**
- No FAQPage, HowTo, Speakable, BreadcrumbList, Product, Review schema
- No standalone Organization schema
- Cannot output multiple JSON-LD blocks per page
- No robots meta tag control (noindex, nofollow)
- No AI-specific metadata
- Last updated Feb 2022 — frozen for 4+ years

### 12.2 jekyll-sitemap
- Generates sitemaps.org-compliant sitemap.xml with lastmod support
- Generates minimal robots.txt (just a Sitemap directive — no AI bot rules)
- No AI-specific features

### 12.3 jekyll-feed
- Generates Atom feed at /feed.xml
- Supports per-category/tag/collection feeds
- Full post content with metadata — machine-readable for AI crawlers
- Content is HTML inside XML, not clean markdown

### 12.4 jekyll-redirect-from
- Generates static HTML redirects
- Prevents broken links (helps AI crawl quality)
- No direct AI/GEO features

### 12.5 jekyll-llmstxt (v0.1.1, ~750 downloads)
- Generates basic llms.txt only
- Links to GitHub raw files rather than serving clean markdown
- No llms-full.txt, no content processing, no Liquid stripping
- Minimal compared to Jekyll-AEO

### 12.6 jekyll-ai-domain-data (new, 2025)
- Generates `.well-known/domain-profile.json`
- Provides AI assistants with authoritative domain identity data
- Complementary to llms.txt (identity vs. content)

### 12.7 Ecosystem Gap Analysis

| Feature | GEO Importance | Jekyll Plugin Coverage |
|---------|---------------|----------------------|
| llms.txt + llms-full.txt | High | **Jekyll-AEO** (comprehensive) |
| Per-page clean markdown | High | **Jekyll-AEO** only |
| Basic meta tags + OG | Medium | jekyll-seo-tag ✅ |
| BlogPosting JSON-LD | Medium | jekyll-seo-tag ✅ |
| XML Sitemap w/ lastmod | Medium | jekyll-sitemap ✅ |
| Atom/RSS feeds | Medium | jekyll-feed ✅ |
| Canonical URLs | Medium | jekyll-seo-tag ✅ |
| FAQPage schema | High | **None** |
| HowTo schema | High | **None** |
| BreadcrumbList schema | Medium | **None** |
| Speakable markup | Medium | **None** |
| AI-aware robots.txt | Medium | **None** (jekyll-sitemap is minimal) |
| Product/Review schema | Medium | **None** |
| Organization schema | Medium | **None** (only as publisher in seo-tag) |
| Multiple JSON-LD blocks | Medium | **None** |
| Domain identity for AI | Low-Medium | jekyll-ai-domain-data |

**Key takeaway:** Jekyll-AEO is complementary to jekyll-seo-tag, not a replacement. They cover different layers. The biggest uncovered gaps in the entire Jekyll ecosystem are FAQPage/HowTo schema, BreadcrumbList, AI-aware robots.txt, and richer Organization/Author schema.

---

## 13. Key Blog Posts & Reading List

### Tier 1 — Must-Read (Data-Driven Research)

| Post | Author | Key Insight |
|------|--------|-------------|
| [2025 State of AI Discovery Report](https://previsible.io/seo-strategy/ai-seo-study-2025/) | David Bell / Previsible | 1.96M LLM sessions analyzed; brand search volume (not backlinks) is strongest AI citation predictor |
| [State of AI Search Optimization 2026](https://www.growth-memo.com/p/state-of-ai-search-optimization-2026) | Kevin Indig / Growth Memo | Classic SEO metrics have weak relationships with citations; predicts agentic SEO |
| [A Reflection on SEO, GEO & AI Search](https://lilyraynyc.substack.com/p/a-reflection-on-seo-and-ai-search) | Lily Ray / Substack | 95% of Query Fan Out queries have zero monthly search volume; authenticity wins |
| [GEO, AEO, LLMO: Fact vs. Fiction](https://www.amsive.com/insights/seo/geo-aeo-llmo-separating-fact-from-fiction-how-to-win-in-ai-search/) | Lily Ray / Amsive | Debunks hype; AI search expands traditional search, doesn't replace it |
| [AIs Are Highly Inconsistent](https://sparktoro.com/blog/new-research-ais-are-highly-inconsistent-when-recommending-brands-or-products-marketers-should-take-care-when-tracking-ai-visibility/) | Rand Fishkin / SparkToro | AI brand recommendations are essentially random (1 in 1,000 chance of identical lists) |

### Tier 2 — Comprehensive Guides

| Post | Source | Key Insight |
|------|--------|-------------|
| [How to Optimize for AI Search Results](https://www.semrush.com/blog/ai-search-optimization/) | Semrush | Listicle-format drives 74.2% of all AI citations |
| [Mastering GEO in 2026](https://searchengineland.com/mastering-generative-engine-optimization-in-2026-full-guide-469142) | Search Engine Land | Citation gap analysis framework |
| [Prompt Research: Next Layer of SEO](https://searchengineland.com/prompt-research-seo-geo-strategy-471399) | Search Engine Land | Introduces prompt research as new discipline |
| [The GEO Playbook](https://www.shopify.com/enterprise/blog/generative-engine-optimization) | Shopify Enterprise | AI-driven orders grew 15x on Shopify; "Agentic Storefronts" concept |
| [AEO Comprehensive Guide](https://cxl.com/blog/answer-engine-optimization-aeo-the-comprehensive-guide/) | CXL | NerdWallet: 35% revenue growth despite 20% traffic decrease |
| [GEO Best Practices](https://firstpagesage.com/seo-blog/generative-engine-optimization-best-practices/) | First Page Sage | Appearing in list articles is the single biggest GEO factor |

### Tier 3 — Platform-Specific

| Post | Source | Key Insight |
|------|--------|-------------|
| [How to Rank on ChatGPT](https://www.omnius.so/blog/how-to-rank-on-chatgpt) | Omnius | 32,000+ referring domains nearly doubles citation count |
| [Perplexity SEO](https://otterly.ai/blog/perplexity-seo/) | Otterly.AI | Perplexity cites sources in 97% of responses; 70% include visuals |
| [What is llms.txt](https://www.gitbook.com/blog/what-is-llms-txt) | GitBook | Practical llms.txt implementation guide |
| [Measuring GEO](https://searchengineland.com/measuring-geo-whats-trackable-now-and-whats-still-missing-461759) | Search Engine Land | Only post focused specifically on GEO measurement gaps |
| [LLM Seeding Strategy](https://www.semrush.com/blog/llm-seeding/) | Semrush | Brand information planting across trusted sources |

### Key People to Follow
- **Kevin Indig** (Growth Memo) — Most rigorous analytical framework
- **Lily Ray** (Amsive) — Best at separating fact from fiction
- **Rand Fishkin** (SparkToro) — Essential contrarian voice backed by data
- **David Bell** (Previsible) — Largest empirical AI discovery dataset

---

## Verification

This is a research document. Verification steps:
1. Cross-reference specific claims with the cited sources (search for paper titles, tool names, company names)
2. Run HubSpot AEO Grader on target site to establish baseline
3. Check server logs for AI crawler activity
4. Test llms.txt/llms-full.txt output from Jekyll-AEO against the llmstxt.org specification
