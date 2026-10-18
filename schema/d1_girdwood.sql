-- Girdwood municipal records: Cloudflare D1, schema v1
-- Store PDFs in R2 (or use official URL). Public GitHub JSON is source of truth for ingestion.
CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  source_url TEXT NOT NULL UNIQUE,
  source_page TEXT NOT NULL,
  board TEXT NOT NULL,
  document_type TEXT NOT NULL,
  year_hint INTEGER,
  meeting_date TEXT,
  fetched_utc TEXT,
  sha256 TEXT,
  page_count INTEGER NOT NULL DEFAULT 0,
  extraction_status TEXT NOT NULL DEFAULT 'pending',
  r2_key TEXT,
  last_seen_utc TEXT
);
CREATE INDEX IF NOT EXISTS idx_documents_board_year ON documents(board, year_hint);
CREATE INDEX IF NOT EXISTS idx_documents_type_year ON documents(document_type, year_hint);
CREATE TABLE IF NOT EXISTS document_pages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id TEXT NOT NULL REFERENCES documents(id),
  page_number INTEGER NOT NULL,
  text_content TEXT NOT NULL,
  ocr_required INTEGER NOT NULL DEFAULT 0,
  UNIQUE(document_id, page_number)
);
CREATE INDEX IF NOT EXISTS idx_pages_document ON document_pages(document_id, page_number);
CREATE VIRTUAL TABLE IF NOT EXISTS document_pages_fts USING fts5(
  text_content, content='document_pages', content_rowid='id', tokenize='unicode61'
);
CREATE TRIGGER IF NOT EXISTS document_pages_ai AFTER INSERT ON document_pages BEGIN
  INSERT INTO document_pages_fts(rowid, text_content) VALUES (new.id, new.text_content);
END;
CREATE TRIGGER IF NOT EXISTS document_pages_ad AFTER DELETE ON document_pages BEGIN
  INSERT INTO document_pages_fts(document_pages_fts, rowid, text_content)
  VALUES ('delete', old.id, old.text_content);
END;
CREATE TRIGGER IF NOT EXISTS document_pages_au AFTER UPDATE ON document_pages BEGIN
  INSERT INTO document_pages_fts(document_pages_fts, rowid, text_content)
  VALUES ('delete', old.id, old.text_content);
  INSERT INTO document_pages_fts(rowid, text_content) VALUES (new.id, new.text_content);
END;
CREATE TABLE IF NOT EXISTS record_entities (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  UNIQUE(normalized_name, entity_type)
);
CREATE TABLE IF NOT EXISTS page_entity_mentions (
  page_id INTEGER NOT NULL REFERENCES document_pages(id),
  entity_id TEXT NOT NULL REFERENCES record_entities(id),
  mention_count INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY(page_id, entity_id)
);
-- Future: add vector embedding chunks to Vectorize keyed by document_id+page_number+chunk.
-- ALWAYS return source_url and page_number. Never treat year_hint as verified meeting_date.
