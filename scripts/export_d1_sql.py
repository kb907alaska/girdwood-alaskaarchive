#!/usr/bin/env python3
"""Export local SQLite civic database into Cloudflare D1-compatible SQL seed statements.

Generates chunked or single SQL files ready for execution via:
npx wrangler d1 execute girdwood-civic-rag --file=data/local/d1_civic_seed.sql
"""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data/local/girdwood-civic.db"
OUTPUT_SQL = ROOT / "data/local/d1_civic_seed.sql"

def escape_sql(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    # Escape single quotes for SQL string literal
    val_str = str(val).replace("'", "''")
    return f"'{val_str}'"

def main():
    if not DB_PATH.exists():
        print(f"Error: {DB_PATH} not found. Run scripts/build_sqlite_index.py first.")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    OUTPUT_SQL.parent.mkdir(parents=True, exist_ok=True)
    
    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("-- Girdwood Civic RAG D1 Seed File\n")
        f.write("-- Generated from local verified municipal index\n")
        f.write("PRAGMA foreign_keys = ON;\n\n")

        # 1. Organizations
        cursor.execute("SELECT id, name, homepage_url, source_type FROM organizations")
        orgs = cursor.fetchall()
        f.write(f"-- Organizations ({len(orgs)})\n")
        for o in orgs:
            f.write(
                f"INSERT OR IGNORE INTO organizations (id, name, homepage_url, source_type) "
                f"VALUES ({escape_sql(o['id'])}, {escape_sql(o['name'])}, {escape_sql(o['homepage_url'])}, {escape_sql(o['source_type'])});\n"
            )
        f.write("\n")

        # 2. Source Pages
        cursor.execute("SELECT id, organization_id, url, discovered_utc, last_checked_utc, robots_policy, rights_status FROM source_pages")
        pages = cursor.fetchall()
        f.write(f"-- Source Pages ({len(pages)})\n")
        for sp in pages:
            f.write(
                f"INSERT OR IGNORE INTO source_pages (id, organization_id, url, discovered_utc, last_checked_utc, robots_policy, rights_status) "
                f"VALUES ({escape_sql(sp['id'])}, {escape_sql(sp['organization_id'])}, {escape_sql(sp['url'])}, "
                f"{escape_sql(sp['discovered_utc'])}, {escape_sql(sp['last_checked_utc'])}, {escape_sql(sp['robots_policy'])}, {escape_sql(sp['rights_status'])});\n"
            )
        f.write("\n")

        # 3. Documents
        cursor.execute(
            """SELECT id, title, original_url, document_type, committee, meeting_date, 
                      year_hint, version_status, content_sha256, file_mime, retrieval_utc, 
                      ingestion_status, original_organization_id, r2_key 
               FROM documents"""
        )
        docs = cursor.fetchall()
        f.write(f"-- Documents ({len(docs)})\n")
        for d in docs:
            f.write(
                f"INSERT OR IGNORE INTO documents (id, title, original_url, document_type, committee, meeting_date, "
                f"year_hint, version_status, content_sha256, file_mime, retrieval_utc, ingestion_status, original_organization_id, r2_key) "
                f"VALUES ({escape_sql(d['id'])}, {escape_sql(d['title'])}, {escape_sql(d['original_url'])}, {escape_sql(d['document_type'])}, "
                f"{escape_sql(d['committee'])}, {escape_sql(d['meeting_date'])}, {escape_sql(d['year_hint'])}, {escape_sql(d['version_status'])}, "
                f"{escape_sql(d['content_sha256'])}, {escape_sql(d['file_mime'])}, {escape_sql(d['retrieval_utc'])}, {escape_sql(d['ingestion_status'])}, "
                f"{escape_sql(d['original_organization_id'])}, {escape_sql(d['r2_key'])});\n"
            )
        f.write("\n")

        # 4. Document Sources
        cursor.execute("SELECT document_id, source_page_id, anchor_text, href_as_published FROM document_sources")
        ds_list = cursor.fetchall()
        f.write(f"-- Document Sources ({len(ds_list)})\n")
        for ds in ds_list:
            f.write(
                f"INSERT OR IGNORE INTO document_sources (document_id, source_page_id, anchor_text, href_as_published) "
                f"VALUES ({escape_sql(ds['document_id'])}, {escape_sql(ds['source_page_id'])}, {escape_sql(ds['anchor_text'])}, {escape_sql(ds['href_as_published'])});\n"
            )
        f.write("\n")

        # 5. Document Pages
        cursor.execute("SELECT id, document_id, page_number, content, text_status FROM document_pages")
        dpages = cursor.fetchall()
        f.write(f"-- Document Pages ({len(dpages)})\n")
        for dp in dpages:
            f.write(
                f"INSERT OR IGNORE INTO document_pages (id, document_id, page_number, content, text_status) "
                f"VALUES ({escape_sql(dp['id'])}, {escape_sql(dp['document_id'])}, {escape_sql(dp['page_number'])}, {escape_sql(dp['content'])}, {escape_sql(dp['text_status'])});\n"
            )
        f.write("\n")

    conn.close()
    print(f"Exported D1 seed SQL to {OUTPUT_SQL}")
    print(f"Stats: {len(orgs)} orgs, {len(pages)} source pages, {len(docs)} documents, {len(ds_list)} linkages, {len(dpages)} pages")

if __name__ == "__main__":
    main()
