# Independent Girdwood Civic RAG

The project is a **source-backed civic archive**, not a replacement for the Municipality's official records.

## Current state

- Source registry: sources/registry.json (verified starting webpages; not exhaustive)
- Cross-organization metadata discovery: scripts/discover_sources.py
- Existing municipal PDF downloader and page extractor: scripts/ingest_moa.py
- Local SQLite and production D1 schema: schema/d1_civic_rag.sql
- Build local standalone full-text DB: scripts/build_sqlite_index.py
- Read API with cited passages and optional Workers AI answer: workers/civic-rag/src/index.ts
- Strategy and 100 ideas: _docs/GIRDWOOD_100_MORE_IDEAS.md

Not yet complete: first verified crawl, old-doc conversion/OCR, D1 populated remotely, Vectorize indexing, R2 document copies, live Cloudflare Worker, and Girdwood.city UI integration. Do not show fake counts or imply 1999 records have been imported.

## Test without Cloudflare

1. Python 3.12+: pip install requests beautifulsoup4 pymupdf
2. Run: python scripts/discover_sources.py --max-pages 5
3. Run: python scripts/ingest_moa.py --max-new 15
4. Run: python scripts/build_sqlite_index.py --q "Holtan Hills"
5. Inspect data/sources/catalog.json, data/municipal/manifest.json and data/local/girdwood-civic.db.

Use robots.txt and copyright/terms review for each source organization. Never follow arbitrary external links, bypass permissions or infer missing files. The initial scripts discover direct PDF files and older CC detail pages, but Google Drive attachments and legacy Word DOC need dedicated converters.

## Cloudflare deployment (not performed)

1. Create resources under a project-scoped Cloudflare account: D1 database (girdwood-civic-rag), R2 bucket (girdwood-records), Vectorize index (girdwood-civic-vectors).
2. From workers/civic-rag copy wrangler.jsonc.example to wrangler.jsonc and supply the D1 ID from wrangler d1 create girdwood-civic-rag. Never commit secrets.
3. In that directory: npx wrangler d1 execute girdwood-civic-rag --remote --file=../../schema/d1_civic_rag.sql
4. Import verified local records using an audited, paginated migration importer. The Python build currently creates a local SQLite index, not a D1 upload. Implement and test the migration before turning on production search.
5. Deploy from the worker directory with npx wrangler deploy after configuring a dedicated archive subdomain. Verify /api/health and /api/search?q=Holtan; document count will remain 0 until data is imported.
6. Add authenticated ingestion through deployment credentials, R2 copies with rights review, OCR queue and hybrid Vectorize indexing.
7. Add /api/search and /api/ask to girdwood.city/archive; render clickable source-page URLs, original PDF links and exact PDF page locators.

The public API has fixed allowed browser origins, but CORS is *not authorization*. Apply rate limits to /api/ask, do not embed ingestion secrets in frontend code, and treat source PDF text as untrusted when prompting an LLM. The AI model and resource IDs are configurable during deployment.

## Corpus retention and provenance

Each document: document_id, original_url, source_page URL(s), source organization(s), SHA-256 of downloaded bytes, retrieved_utc, last checked, official meeting date if verified, inferred year if not, draft/final status, page_number, text_status, rights/reuse review, and optional R2 copy key. If the same file URL appears from different organizations, keep all source links. Distinguish *indexing* from *republishing*. Publicly available does not necessarily mean unrestricted copyright.

## Historical backfill

GBOS current landing page links recent meetings and a separate resolution list; the Community Council holds older Word documents and paginated collections; the Municipality invites archived-minutes requests. Covering 1999+ requires source-by-source verification and separate archival records requests. Publish known gaps by committee/year.
