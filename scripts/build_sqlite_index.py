#!/usr/bin/env python3
"""Build local SQLite civic index from discovered links + extracted source-page JSON.

The exact same schema runs in Cloudflare D1. Local DB is intentionally untracked.
python scripts/build_sqlite_index.py
python scripts/build_sqlite_index.py --q "Holtan Hills"
"""
import argparse, hashlib, json, sqlite3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SCHEMA=ROOT/"schema/d1_civic_rag.sql"
DB=ROOT/"data/local/girdwood-civic.db"
MUNI=ROOT/"data/municipal/manifest.json"
CATALOG=ROOT/"data/sources/catalog.json"
FILES=ROOT/"data/municipal/documents"

def ident(url):
    return hashlib.sha256(url.encode("utf-8")).hexdigest()[:24]

def org_id(name):
    return "org-"+hashlib.sha256(name.encode("utf-8")).hexdigest()[:16]

def insert_org(conn,name):
    name=name or "Unknown organization"
    oid=org_id(name)
    conn.execute("INSERT OR IGNORE INTO organizations(id,name) VALUES (?,?)",(oid,name))
    return oid

def add_source(conn,source_url,name,rights="needs_review"):
    oid=insert_org(conn,name)
    sid=ident(source_url)
    conn.execute("""INSERT OR IGNORE INTO source_pages(id,organization_id,url,rights_status)
        VALUES(?,?,?,?)""",(sid,oid,source_url,rights))
    return sid

def add_doc(conn,doc,legacy=False):
    url=doc.get("original_url")
    if not url: return None
    did=ident(url)
    name=doc.get("organization") or ("Municipality of Anchorage" if not legacy or "COMMUNITY" not in str(doc.get("board")) else "Federation of Community Councils")
    oid=insert_org(conn,name)
    committee=doc.get("committee") or ",".join(doc.get("board") or ["UNKNOWN"])
    title=doc.get("title") or url.split("/")[-1]
    dtype=doc.get("document_type") or "other"
    year=doc.get("year_hint")
    if not isinstance(year,int) or not (1800<=year<=2200):year=None
    conn.execute("""INSERT INTO documents(id,title,original_url,document_type,committee,
      year_hint,original_organization_id,ingestion_status)
      VALUES(?,?,?,?,?,?,?,?)
      ON CONFLICT(original_url) DO UPDATE SET
      title=CASE WHEN excluded.title!='' THEN excluded.title ELSE documents.title END,
      document_type=CASE WHEN excluded.document_type!='other' THEN excluded.document_type ELSE documents.document_type END
    """,(did,title,url,dtype,committee,year,oid,"discovered"))
    return did

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--db",type=Path,default=DB)
    p.add_argument("--q",type=str,default=None)
    a=p.parse_args()
    a.db.parent.mkdir(parents=True,exist_ok=True)
    conn=sqlite3.connect(a.db)
    conn.row_factory=sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    conn.executescript(SCHEMA.read_text(encoding="utf-8"))
    total=0
    pages=0
    if CATALOG.exists():
        for row in json.loads(CATALOG.read_text(encoding="utf-8")).get("records",[]):
            did=add_doc(conn,row)
            if not did:continue
            total+=1
            for s in row.get("source_links",[]):
                sid=add_source(conn,s["source_page"],s.get("organization") or row.get("organization"),s.get("rights_review","needs_review"))
                conn.execute("""INSERT OR IGNORE INTO document_sources
                    (document_id,source_page_id,anchor_text,href_as_published)
                    VALUES(?,?,?,?)""",(did,sid,row.get("title",""),s.get("href_as_published","")))
    if MUNI.exists():
        for row in json.loads(MUNI.read_text(encoding="utf-8")).get("documents",[]):
            did=add_doc(conn,row,legacy=True)
            if not did:continue
            total+=1
            for source_url in row.get("source_pages",[]):
                name="Federation of Community Councils" if "communitycouncils.org" in source_url else "Municipality of Anchorage"
                sid=add_source(conn,source_url,name)
                conn.execute("INSERT OR IGNORE INTO document_sources(document_id,source_page_id) VALUES (?,?)",(did,sid))
            file_path=FILES/(row["id"]+".json")
            if not file_path.exists():continue
            content=json.loads(file_path.read_text(encoding="utf-8"))
            if content.get("sha256"):
                conn.execute("""UPDATE documents SET content_sha256=?,retrieval_utc=?,ingestion_status=?
                    WHERE id=?""",(content["sha256"],content.get("fetched_utc"),content.get("text_status","unknown"),did))
            for page in content.get("pages",[]):
                if not page.get("text"):continue
                conn.execute("""INSERT INTO document_pages(document_id,page_number,content,text_status)
                  VALUES(?,?,?,?)
                  ON CONFLICT(document_id,page_number) DO UPDATE SET
                    content=excluded.content,text_status=excluded.text_status""",
                  (did,page["page"],page["text"],"ocr_required" if page.get("ocr_required") else "extracted"))
                pages+=1
    conn.commit()
    print("Database:",a.db)
    print("Document links processed:",total,"| extracted pages processed:",pages)
    print("Unique documents:",conn.execute("SELECT COUNT(*) FROM documents").fetchone()[0])
    if a.q:
        q=" AND ".join('"'+t+'"' for t in a.q.split()[:12])
        rows=conn.execute("""SELECT d.title,d.original_url,p.page_number,
         substr(p.content,1,280) AS excerpt
         FROM pages_fts JOIN document_pages p ON p.id=pages_fts.rowid
         JOIN documents d ON d.id=p.document_id
         WHERE pages_fts MATCH ? ORDER BY bm25(pages_fts) LIMIT 10""",(q,)).fetchall()
        for row in rows: print(dict(row))
        if not rows: print("No indexed text matches; completeness is not guaranteed.")
    conn.close()
if __name__=="__main__":
    main()
