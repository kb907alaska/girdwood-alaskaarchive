# Girdwood public records: source-backed search and RAG

Status (2026-10-18): Discovery and PDF extraction code committed to main. No verified corpus run, Cloudflare D1 import, Vectorize index, or deployed RAG endpoint has been confirmed.

## Purpose

- girdwood.city remains the fast Astro resident/visitor site and branded civic search gateway.
- girdwood-alaskaarchive is the public versioned dataset containing source URLs, link metadata, and extracted text by exact PDF page.
- girdwood.alaskaarchive.com is the planned historical civic explorer. archive.girdwood.city may act as a branded gateway to the same records; do not fork or duplicate the source of truth.

## Official municipal collections

GBOS: https://www.muni.org/Departments/operations/streets/Service/Pages/girdwoodboardofsupervisors.aspx
Land Use: https://www.muni.org/Departments/operations/streets/Service/Pages/gluc.aspx
Trails: https://www.muni.org/Departments/operations/streets/Service/Pages/gtc.aspx
Housing and Economic: https://www.muni.org/Departments/operations/streets/Service/Pages/gbos-ghec.aspx
Public Safety: https://www.muni.org/Departments/operations/streets/Service/Pages/gpsac.aspx
Cemetery: https://www.muni.org/Departments/operations/streets/Service/Pages/gc.aspx
GBOS resolutions (at least 2015-2026): https://www.muni.org/Departments/operations/streets/Service/Pages/GBOSResolutions.aspx
Older Community Council Land Use records: https://communitycouncils.org/girdwood/land-use-committee/
Assembly: https://www.muni.org/departments/Assembly/Pages/default.aspx
Imagine Girdwood meetings: https://www.imaginegirdwood.org/committee-meetings

The first scraper indexes direct public PDF/Office/TXT/CSV links from the first eight sources only. It does not yet handle all historic years, pagination, indirect SharePoint downloads, Assembly links or recordings.

## Current pipeline

1. GitHub Actions runs scripts/ingest_moa.py daily or by workflow_dispatch, discovering official file URLs and recording source labels, committee, file extension, document type, and uncertain year hints.
2. PDF content is extracted with exact one-based PDF page numbers; DOCX and text supported. Scanned image pages are marked OCR-required; old binary Office formats are flagged as needing conversion. All failures are visible.
3. Data appears in data/municipal/manifest.json and data/municipal/documents/ID.json only after a successful workflow run.
4. A later job imports parsed records into Cloudflare D1 using schema/d1_girdwood.sql (including FTS5); indexes chunks in Vectorize; optionally mirrors permitted original PDFs in R2.

## Search fields to implement

Universal search, exact quote, semantic search, committee, document type, date range, year-unknown toggle, topic/project, parcel, person or organization mentioned, meeting, document version (draft/final/revised), and results by PDF page.

API routes: GET /api/records?q=&board=&kind=&from=&to=&page= and POST /api/ask.

Responses must include source organization, original source URL, exact page, quoted excerpt, verification status, and date indexed. When evidence is absent say 'Not found in indexed records', not 'No record exists'. The AI must distinguish proposed changes from adopted decisions and public comments from official votes.

## Historical coverage backfill

The current GBOS landing page has recent records, while the resolutions portal exposes some older years. Older Girdwood documents must be retrieved from Community Council collections and municipal archival requests. The goal of 1999 onward is a target, NOT a verified complete collection. Maintain public per-year/per-board coverage and missing-record logs; use the MOA archive contact listed on the official GBOS page.

## Quality

Respect source robots/terms and rate limits; no login bypasses. No AI invented data. Record hashes, retrieval dates, original URLs, revisions, and page-accurate citation checks. Avoid building unnecessary personal profiles from meeting records. No WordPress; static Astro site, WCAG 2.2 AA, target 100 PageSpeed.
