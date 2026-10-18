-- Girdwood standalone civic RAG database, D1-compatible SQLite FTS5
-- Fresh install schema, separate from legacy schema/d1_girdwood.sql.
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS organizations (
 id TEXT PRIMARY KEY,
 name TEXT NOT NULL,
 homepage_url TEXT,
 source_type TEXT NOT NULL DEFAULT 'public_organization'
);
CREATE TABLE IF NOT EXISTS source_pages (
 id TEXT PRIMARY KEY,
 organization_id TEXT NOT NULL REFERENCES organizations(id),
 url TEXT NOT NULL UNIQUE,
 discovered_utc TEXT,
 last_checked_utc TEXT,
 robots_policy TEXT,
 rights_status TEXT NOT NULL DEFAULT 'needs_review'
);
CREATE TABLE IF NOT EXISTS documents (
 id TEXT PRIMARY KEY,
 title TEXT NOT NULL,
 original_url TEXT NOT NULL UNIQUE,
 document_type TEXT NOT NULL DEFAULT 'other',
 committee TEXT NOT NULL DEFAULT 'UNKNOWN',
 meeting_date TEXT,
 year_hint INTEGER,
 version_status TEXT NOT NULL DEFAULT 'unknown',
 content_sha256 TEXT,
 file_mime TEXT,
 retrieval_utc TEXT,
 ingestion_status TEXT NOT NULL DEFAULT 'discovered',
 original_organization_id TEXT REFERENCES organizations(id),
 r2_key TEXT
);
CREATE INDEX IF NOT EXISTS idx_docs_committee_year ON documents(committee,year_hint);
CREATE INDEX IF NOT EXISTS idx_docs_type_year ON documents(document_type,year_hint);
CREATE TABLE IF NOT EXISTS document_sources (
 document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
 source_page_id TEXT NOT NULL REFERENCES source_pages(id),
 anchor_text TEXT,
 href_as_published TEXT,
 PRIMARY KEY(document_id,source_page_id)
);
CREATE TABLE IF NOT EXISTS document_pages (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
 page_number INTEGER NOT NULL CHECK(page_number > 0),
 content TEXT NOT NULL,
 text_status TEXT NOT NULL DEFAULT 'extracted',
 UNIQUE(document_id,page_number)
);
CREATE INDEX IF NOT EXISTS idx_doc_pages ON document_pages(document_id,page_number);
CREATE VIRTUAL TABLE IF NOT EXISTS pages_fts USING fts5(
 content,content='document_pages',content_rowid='id',tokenize='unicode61'
);
CREATE TRIGGER IF NOT EXISTS pages_ai AFTER INSERT ON document_pages BEGIN
 INSERT INTO pages_fts(rowid,content) VALUES (new.id,new.content);
END;
CREATE TRIGGER IF NOT EXISTS pages_ad AFTER DELETE ON document_pages BEGIN
 INSERT INTO pages_fts(pages_fts,rowid,content) VALUES('delete',old.id,old.content);
END;
CREATE TRIGGER IF NOT EXISTS pages_au AFTER UPDATE ON document_pages BEGIN
 INSERT INTO pages_fts(pages_fts,rowid,content) VALUES('delete',old.id,old.content);
 INSERT INTO pages_fts(rowid,content) VALUES(new.id,new.content);
END;
CREATE TABLE IF NOT EXISTS document_chunks (
 chunk_id TEXT PRIMARY KEY,
 document_id TEXT NOT NULL REFERENCES documents(id),
 page_start INTEGER NOT NULL,
 page_end INTEGER NOT NULL,
 content TEXT NOT NULL,
 embedding_model TEXT,
 vector_indexed_utc TEXT,
 FOREIGN KEY (document_id) REFERENCES documents(id)
);
CREATE INDEX IF NOT EXISTS idx_chunks_document ON document_chunks(document_id,page_start);
CREATE TABLE IF NOT EXISTS ingestion_runs (
 run_id TEXT PRIMARY KEY,
 started_utc TEXT NOT NULL,
 finished_utc TEXT,
 source_id TEXT NOT NULL,
 discovered_count INTEGER DEFAULT 0,
 extracted_count INTEGER DEFAULT 0,
 errors_count INTEGER DEFAULT 0,
 status TEXT NOT NULL DEFAULT 'running',
 log_url TEXT
);
-- Search must reference document_sources and source_pages to return full
-- originating organization, source-page URL and official file URL.
-- Include hash, retrieval time, version status and exact PDF page.
