#!/usr/bin/env python3
"""Build a public source-link catalog without claiming to have downloaded the files.

Uses sources/registry.json. Preserves BOTH the source webpage URL and the full
original link target. CC historical collection pagination and document detail
pages are supported. Third-party external files remain metadata-only until
rights and download pathways are reviewed.

Install: pip install requests beautifulsoup4
Run: python scripts/discover_sources.py --max-pages 8

This tool does not bypass access controls or follow arbitrary external URLs.
"""
import argparse
import hashlib
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin, urlsplit
from urllib.robotparser import RobotFileParser

import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "sources" / "registry.json"
OUTPUT = ROOT / "data" / "sources" / "catalog.json"
ALLOWED_DOCUMENT_EXT = (".pdf", ".doc", ".docx", ".xlsx", ".xls", ".csv", ".ppt", ".pptx", ".txt")
AGENT = "GirdwoodCivicArchive/0.2 (+https://girdwood.city/archive)"
SESSION = requests.Session()
SESSION.headers.update({"User-Agent": AGENT})
ROBOTS = {}

def safe_url(href, base):
    absolute = urljoin(base, href.strip())
    parsed = urlsplit(absolute)
    if parsed.scheme not in ("https", "http") or not parsed.hostname:
        return None
    if parsed.username or parsed.password:
        return None
    return absolute

def robots_allowed(url):
    parsed = urlsplit(url)
    host = parsed.scheme + "://" + parsed.netloc
    if host not in ROBOTS:
        rp = RobotFileParser()
        rp.set_url(host + "/robots.txt")
        try:
            rp.read()
            ROBOTS[host] = rp
        except Exception:
            ROBOTS[host] = None
    checker = ROBOTS[host]
    return checker is not None and checker.can_fetch(AGENT, url)

def download_html(url):
    if not robots_allowed(url):
        raise RuntimeError("robots.txt unavailable or disallows fetch; manual review required")
    response = SESSION.get(url, timeout=(12, 40))
    response.raise_for_status()
    if "html" not in response.headers.get("Content-Type", "").lower():
        raise RuntimeError("not HTML")
    if len(response.content) > 6_000_000:
        raise RuntimeError("HTML exceeds 6MB")
    return response.text, response.url

def page_urls(source, max_pages):
    urls = [source["url"]]
    if source["mode"] == "paged_detail":
        urls.extend(source["url"] + "?cp=" + str(i) for i in range(2, max_pages + 1))
    return urls

def is_file(url):
    path = urlsplit(url).path.lower()
    return path.endswith(ALLOWED_DOCUMENT_EXT)

def links_for_page(html, page_url, source):
    soup = BeautifulSoup(html, "html.parser")
    links = []
    for el in soup.select("a[href]"):
        href = el.get("href") or ""
        url = safe_url(href, page_url)
        if not url:
            continue
        label = re.sub(r"\s+", " ", el.get_text(" ", strip=True)).strip()
        label = label[:300] or urlsplit(url).path.split("/")[-1]
        host = (urlsplit(url).hostname or "").lower()
        if is_file(url):
            kind = "direct_file"
        elif source["mode"] == "paged_detail" and host.endswith("communitycouncils.org") and (
            "/download/" in urlsplit(url).path or "/document/" in urlsplit(url).path or
            "/land-use-committee/" in urlsplit(url).path and url != source["url"]):
            kind = "detail_page"
        elif source["mode"] == "external_links_metadata" and host in (
            "drive.google.com", "docs.google.com"):
            kind = "external_file_link"
        else:
            continue
        links.append({"url": url, "href_as_published": href, "title": label,
                      "link_kind": kind, "source_page": page_url})
    return links

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-pages", type=int, default=8)
    parser.add_argument("--max-details", type=int, default=150)
    args = parser.parse_args()
    sources = json.loads(REGISTRY.read_text(encoding="utf-8"))["sources"]
    records = {}
    status = []
    previous = {}
    if OUTPUT.exists():
        previous = {r["id"]:r for r in json.loads(OUTPUT.read_text(encoding="utf-8")).get("records", [])}
    for source in sources:
        if source["mode"] == "metadata_only":
            status.append({"source_id":source["id"],"status":"manual_filter_needed","pages_fetched":0})
            continue
        fetched = 0
        source_errors = []
        detail_queue = []
        for page_url in page_urls(source, max(1, min(args.max_pages, 30))):
            try:
                html, resolved = download_html(page_url)
                fetched += 1
                for link in links_for_page(html,resolved,source):
                    if link["link_kind"] == "detail_page":
                        detail_queue.append(link)
                    else:
                        add_record(records, source, link)
            except Exception as ex:
                source_errors.append({"url":page_url,"error":str(ex)[:160]})
            time.sleep(0.3)
        if source["mode"] == "paged_detail":
            for page in detail_queue[:max(0,args.max_details)]:
                try:
                    html, resolved = download_html(page["url"])
                    fetched += 1
                    files = links_for_page(html,resolved,source)
                    for link in files:
                        if link["link_kind"] == "direct_file":
                            # The source collection page is the attribution origin;
                            # the detail page is the immediate file-link referrer.
                            link["collection_page"] = page["source_page"]
                            add_record(records,source,link)
                except Exception as ex:
                    source_errors.append({"url":page["url"],"error":str(ex)[:160]})
                time.sleep(0.3)
        status.append({"source_id":source["id"],"status":"partial" if source_errors else "ok",
                       "pages_fetched":fetched,"errors":source_errors[:30]})
    # Never delete a discovered link because of one failed fetch.
    for key, prior in previous.items():
        if key not in records:
            prior["not_seen_in_latest_scan"] = True
            records[key]=prior
    output={"schema_version":1,
        "generated_utc":datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "disclaimer":"Discovered public URLs, not a verified complete archive or downloaded corpus.",
        "sources":status,"record_count":len(records),
        "records":sorted(records.values(),key=lambda r:(r["organization"],r["title"],r["id"]))}
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    OUTPUT.write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("Source pages:",sum(s["pages_fetched"] for s in status),
          "| link records:",len(records),
          "| sources with errors:",sum(bool(s.get("errors")) for s in status))
    if sum(s["pages_fetched"] for s in status)==0:
        raise SystemExit("No source pages were crawled. Check robots policies/network and review errors.")

def add_record(records,source,link):
    rid=hashlib.sha256(link["url"].encode("utf-8")).hexdigest()[:24]
    found = records.get(rid)
    if found is None:
        found={"id":rid,"title":link["title"],"original_url":link["url"],
               "kind":link["link_kind"],"organization":source["organization"],
               "source_links":[]}
        records[rid]=found
    provenance={"source_id":source["id"],"organization":source["organization"],
                "committee":source["committee"],"source_page":link["source_page"],
                "href_as_published":link["href_as_published"],
                "rights_review":source["rights_review"]}
    if link.get("collection_page"):
        provenance["collection_page"]=link["collection_page"]
    if provenance not in found["source_links"]:
        found["source_links"].append(provenance)

if __name__=="__main__":
    main()
