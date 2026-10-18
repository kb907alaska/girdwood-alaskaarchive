#!/usr/bin/env python3
"""Build local SQLite FTS5 database from Girdwood municipal manifest & extracted docs.

Can be queried locally or imported into Cloudflare D1.
Usage: python3 scripts/build_sqlite_fts.py
"""
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data" / "municipal"
MANIFEST_FILE = DATA_DIR / "manifest.json"
DOCS_DIR = DATA_DIR / "documents"
DB_FILE = DATA_DIR / "girdwood_records.sqlite"
SCHEMA_FILE = ROOT / "schema" / "d1_girdwood.sql"
SQL_EXPORT = DATA_DIR / "d1_seed.sql"

def main():
    if not MANIFEST_FILE.exists():
        print(f"Error: {MANIFEST_FILE} not found. Run ingest_moa.py first.")
        return

    with open(MANIFEST_FILE, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    documents = manifest.get("documents", [])
    print(f"Loaded manifest with {len(documents)} documents.")

    # Initialize SQLite database
    if DB_FILE.exists():
        DB_FILE.unlink()

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Read and apply schema
    with open(SCHEMA_FILE, "r", encoding="utf-8") as f:
        schema_sql = f.read()

    # Execute schema (handling triggers and virtual tables)
    cursor.executescript(schema_sql)
    conn.commit()

    # Insert documents
    doc_count = 0
    page_count = 0

    for doc in documents:
        doc_id = doc.get("id")
        title = doc.get("title", "")
        source_url = doc.get("original_url", "")
        source_page = doc.get("source_pages", [""])[0] if doc.get("source_pages") else ""
        boards = doc.get("board", [])
        board_str = ",".join(boards) if isinstance(boards, list) else str(boards)
        doc_type = doc.get("document_type", "other")
        year_hint = doc.get("year_hint")
        fetched_utc = doc.get("fetched_utc", "")
        sha256 = doc.get("sha256", "")
        status = doc.get("text_status", "pending")

        # Check if individual document JSON exists
        doc_json_path = DOCS_DIR / f"{doc_id}.json"
        pages_data = []
        if doc_json_path.exists():
            try:
                with open(doc_json_path, "r", encoding="utf-8") as df:
                    doc_details = json.load(df)
                    pages_data = doc_details.get("pages", [])
                    sha256 = doc_details.get("sha256", sha256)
                    status = doc_details.get("text_status", "extracted")
            except Exception as e:
                print(f"Warning reading {doc_json_path}: {e}")

        cursor.execute(
            """INSERT OR REPLACE INTO documents 
            (id, title, source_url, source_page, board, document_type, year_hint, fetched_utc, sha256, page_count, extraction_status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (doc_id, title, source_url, source_page, board_str, doc_type, year_hint, fetched_utc, sha256, len(pages_data), status)
        )
        doc_count += 1

        for p in pages_data:
            page_num = p.get("page", 1)
            text = p.get("text", "")
            ocr_req = 1 if p.get("ocr_required") else 0
            cursor.execute(
                """INSERT OR REPLACE INTO document_pages (document_id, page_number, text_content, ocr_required)
                VALUES (?, ?, ?, ?)""",
                (doc_id, page_num, text, ocr_req)
            )
            page_count += 1

    conn.commit()
    print(f"Successfully inserted {doc_count} documents and {page_count} pages into {DB_FILE}")

    # Test FTS query
    cursor.execute("SELECT count(*) FROM documents")
    print(f"Verified total documents in DB: {cursor.fetchone()[0]}")

    cursor.execute("SELECT count(*) FROM document_pages_fts")
    print(f"Indexed pages in FTS5: {cursor.fetchone()[0]}")

    conn.close()

if __name__ == "__main__":
    main()
