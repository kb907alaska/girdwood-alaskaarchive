#!/usr/bin/env python3
"""Index publicly linked Girdwood municipal records with page-level text.

Run: pip install requests beautifulsoup4 pymupdf
     python scripts/ingest_moa.py --max-new 150

This is discovery plus searchable-text extraction, NOT an AI answer generator.
A missing link on a source page is not proof that a historical record does not exist.
"""
import argparse
import hashlib
import io
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit, urlunsplit
from zipfile import ZipFile
import xml.etree.ElementTree as ET

import fitz
import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "municipal"
DOCS = OUT / "documents"
MANIFEST = OUT / "manifest.json"

BASE = "https://www.muni.org/Departments/operations/streets/Service/"
SOURCES = {
    "GBOS": BASE + "Pages/girdwoodboardofsupervisors.aspx",
    "LUC": BASE + "Pages/gluc.aspx",
    "TRAILS": BASE + "Pages/gtc.aspx",
    "GHEC": BASE + "Pages/gbos-ghec.aspx",
    "PSAC": BASE + "Pages/gpsac.aspx",
    "CEMETERY": BASE + "Pages/gc.aspx",
    "RESOLUTIONS": BASE + "Pages/GBOSResolutions.aspx",
    "COMMUNITY_LUC": "https://communitycouncils.org/girdwood/land-use-committee/",
}
EXTENSIONS = {".pdf", ".doc", ".docx", ".txt", ".csv", ".xls", ".xlsx", ".ppt", ".pptx"}
HEADERS = {"User-Agent": "GirdwoodCivicArchive/0.1 (public record research; https://girdwood.city/archive)",
           "Accept": "text/html,application/pdf,application/octet-stream,*/*"}
SESSION = requests.Session()
SESSION.headers.update(HEADERS)

def utcnow():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

def canonical(raw_url, base_url):
    url = urljoin(base_url, raw_url.strip())
    parts = urlsplit(url)
    if parts.scheme.lower() not in ("https", "http"):
        return None
    domain = parts.hostname.lower() if parts.hostname else ""
    if domain not in {"muni.org", "www.muni.org", "communitycouncils.org", "www.communitycouncils.org"}:
        return None
    # Retain query parameters when source uses them for real download URLs.
    return urlunsplit(("https", parts.netloc.lower(), parts.path, parts.query, ""))

def ext_of(url):
    return Path(unquote(urlsplit(url).path).lower()).suffix

def kind_of(label):
    s = label.lower()
    for term, kind in (
        ("minutes", "minutes"), ("meeting packet", "packet"), ("packet", "packet"),
        ("agenda", "agenda"), ("resolution", "resolution"), ("budget", "budget"),
        ("plan", "plan"), ("report", "report"), ("letter", "letter"),
        ("map", "map"), ("study", "study"), ("policy", "policy"),
    ):
        if term in s:
            return kind
    return "other"

def year_hint(label, url):
    match = re.search(r"(?<!\d)(?:19\d{2}|20\d{2})(?!\d)", label + " " + unquote(url))
    return int(match.group(0)) if match else None

def discover(html, page_url, board):
    soup = BeautifulSoup(html, "html.parser")
    found = {}
    for link in soup.find_all("a", href=True):
        url = canonical(link["href"], page_url)
        if not url or ext_of(url) not in EXTENSIONS:
            continue
        label = " ".join(link.stripped_strings) or unquote(Path(urlsplit(url).path).name)
        label = re.sub(r"\s+", " ", label).strip()
        key = hashlib.sha256(url.encode("utf-8")).hexdigest()[:20]
        found[key] = {
            "id": key, "title": label, "original_url": url,
            "file_type": ext_of(url)[1:], "document_type": kind_of(label),
            "year_hint": year_hint(label, url), "board": [board],
            "source_pages": [page_url]
        }
    return found

def fetch(url, limit_mb=160):
    with SESSION.get(url, timeout=(15, 120), stream=True, allow_redirects=True) as response:
        response.raise_for_status()
        length = int(response.headers.get("content-length", "0"))
        if length > limit_mb * 1024 * 1024:
            raise ValueError("file over size limit")
        chunks, total = [], 0
        for part in response.iter_content(chunk_size=65536):
            total += len(part)
            if total > limit_mb * 1024 * 1024:
                raise ValueError("file over size limit")
            chunks.append(part)
        return b"".join(chunks)

def extract_pdf(binary):
    pdf = fitz.open(stream=binary, filetype="pdf")
    pages = []
    for i, page in enumerate(pdf):
        text = page.get_text("text", sort=True).strip()
        pages.append({"page": i + 1, "text": text, "ocr_required": len(text) < 20})
    return pages

def extract_docx(binary):
    with ZipFile(io.BytesIO(binary)) as archive:
        xml = archive.read("word/document.xml")
    root = ET.fromstring(xml)
    texts = [e.text for e in root.iter() if e.tag.endswith("}t") and e.text]
    return [{"page": 1, "text": " ".join(texts), "ocr_required": False}]

def extract_document(binary, file_type):
    if file_type == "pdf":
        return extract_pdf(binary), "extracted"
    if file_type == "docx":
        return extract_docx(binary), "extracted"
    if file_type in {"txt", "csv"}:
        return [{"page": 1, "text": binary.decode("utf-8", errors="replace"), "ocr_required": False}], "extracted"
    return [], "needs_conversion"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-new", type=int, default=150,
                        help="Max new files to process per run; uncached documents remain discovered.")
    parser.add_argument("--refresh", action="store_true",
                        help="Re-download all previously extracted documents within max-new.")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)
    previous = {}
    if MANIFEST.exists():
        previous = {row["id"]: row for row in json.loads(MANIFEST.read_text()).get("documents", [])}
    found = {}
    source_results = []
    for board, url in SOURCES.items():
        try:
            response = SESSION.get(url, timeout=35)
            response.raise_for_status()
            links = discover(response.text, response.url, board)
            for ident, record in links.items():
                if ident not in found:
                    found[ident] = record
                else:
                    for field in ("board", "source_pages"):
                        found[ident][field] = sorted(set(found[ident][field] + record[field]))
            source_results.append({"board": board, "url": url, "status": "ok",
                                   "links_found": len(links)})
        except Exception as exc:
            source_results.append({"board": board, "url": url, "status": "error",
                                   "error": str(exc)[:240]})
        time.sleep(0.35)
    # Do not purge previously found records if upstream removed the link or was unavailable.
    for ident, old in previous.items():
        if ident not in found:
            found[ident] = {k: v for k, v in old.items() if k not in {"text_status", "page_count"}}
            found[ident]["not_seen_this_run"] = True
    attempted = 0
    failures = []
    for ident, record in sorted(found.items()):
        path = DOCS / (ident + ".json")
        if path.exists() and not args.refresh:
            cached = json.loads(path.read_text(encoding="utf-8"))
            record["text_status"] = cached.get("text_status", "unknown")
            record["page_count"] = len(cached.get("pages", []))
            continue
        if attempted >= args.max_new:
            record["text_status"] = "pending_download"
            continue
        attempted += 1
        try:
            binary = fetch(record["original_url"])
            pages, status = extract_document(binary, record["file_type"])
            payload = {
                "id": ident, "source_url": record["original_url"],
                "fetched_utc": utcnow(), "sha256": hashlib.sha256(binary).hexdigest(),
                "text_status": status, "pages": pages
            }
            path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8")
            record["text_status"] = status
            record["page_count"] = len(pages)
        except Exception as exc:
            record["text_status"] = "download_error"
            failures.append({"id": ident, "url": record["original_url"], "error": str(exc)[:240]})
        time.sleep(0.5)
    # Keep metadata deterministically sorted so changes are reviewable in Git.
    document_rows = sorted(found.values(), key=lambda r: (r.get("year_hint") or 0, r["title"].lower(), r["id"]), reverse=True)
    manifest = {
        "schema_version": 1, "generated_utc": utcnow(), "project": "Girdwood public records",
        "disclaimer": "Independent index, not official MOA record. Dates inferred from titles are hints only.",
        "sources": source_results, "total_discovered": len(document_rows),
        "pending_text": sum(r.get("text_status") != "extracted" for r in document_rows),
        "documents": document_rows,
        "download_errors": failures
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Source pages:", len(source_results), "| documents discovered:", len(document_rows),
          "| PDFs/docs attempted:", attempted, "| errors:", len(failures),
          "| remaining unextracted:", manifest["pending_text"])
    if not any(s["status"] == "ok" for s in source_results):
        raise SystemExit("No source page could be fetched; check MOA access and retry.")

if __name__ == "__main__":
    main()
