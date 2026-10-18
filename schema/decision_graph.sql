-- Girdwood Decision Atlas source-backed event and decision graph
-- Additive to schema/d1_civic_rag.sql. No relationship may claim an outcome
-- without a citation to an official document or qualified primary source.

CREATE TABLE IF NOT EXISTS graph_nodes (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK(kind IN (
    'era','historical_event','meeting','agenda_item','proposal','motion',
    'decision','resolution','project','committee','organization','place','parcel','person'
  )),
  title TEXT NOT NULL,
  description TEXT,
  occurred_on TEXT,
  year_hint INTEGER,
  date_precision TEXT NOT NULL DEFAULT 'unknown'
    CHECK(date_precision IN ('day','month','year','approximate','unknown')),
  status TEXT NOT NULL DEFAULT 'unverified'
    CHECK(status IN ('source_verified','reviewed','unverified','disputed')),
  decision_outcome TEXT CHECK(decision_outcome IN (
    'approved','rejected','amended','postponed','withdrawn','pending','unknown'
  )),
  canonical_slug TEXT UNIQUE,
  latitude REAL,
  longitude REAL,
  created_utc TEXT NOT NULL,
  reviewed_utc TEXT
);
CREATE INDEX IF NOT EXISTS idx_graph_nodes_kind_date
  ON graph_nodes(kind, occurred_on);
CREATE TABLE IF NOT EXISTS graph_edges (
  id TEXT PRIMARY KEY,
  from_node_id TEXT NOT NULL REFERENCES graph_nodes(id),
  to_node_id TEXT NOT NULL REFERENCES graph_nodes(id),
  relation TEXT NOT NULL CHECK(relation IN (
    'occurred_before','proposed_at','considered_by','presented_at','voted_on',
    'amended_by','adopted_by','rejected_by','superseded_by','implemented_by',
    'referenced_by','mentions','appears_in','located_at','contributed_to'
  )),
  evidence_status TEXT NOT NULL DEFAULT 'provisional'
    CHECK(evidence_status IN ('verified','provisional','disputed')),
  extraction_method TEXT NOT NULL DEFAULT 'human'
    CHECK(extraction_method IN ('human','rule','model')),
  reviewer_note TEXT,
  created_utc TEXT NOT NULL,
  CHECK(from_node_id != to_node_id)
);
CREATE INDEX IF NOT EXISTS idx_graph_edges_source ON graph_edges(from_node_id,relation);
CREATE INDEX IF NOT EXISTS idx_graph_edges_target ON graph_edges(to_node_id,relation);
CREATE TABLE IF NOT EXISTS graph_evidence (
  edge_id TEXT NOT NULL REFERENCES graph_edges(id) ON DELETE CASCADE,
  document_id TEXT NOT NULL REFERENCES documents(id),
  page_number INTEGER CHECK(page_number > 0),
  source_excerpt TEXT,
  excerpt_sha256 TEXT,
  evidence_url TEXT NOT NULL,
  PRIMARY KEY (edge_id,document_id,page_number)
);
CREATE TABLE IF NOT EXISTS graph_node_sources (
  node_id TEXT NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
  source_url TEXT NOT NULL,
  source_organization TEXT NOT NULL,
  document_id TEXT REFERENCES documents(id),
  page_number INTEGER CHECK(page_number > 0),
  PRIMARY KEY(node_id,source_url,page_number)
);
CREATE TABLE IF NOT EXISTS graph_review_queue (
  id TEXT PRIMARY KEY,
  candidate_from_id TEXT NOT NULL,
  candidate_to_id TEXT NOT NULL,
  suggested_relation TEXT NOT NULL,
  candidate_citation_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK(status IN ('pending','approved','rejected','needs_more_evidence')),
  reviewer_note TEXT,
  created_utc TEXT NOT NULL
);
-- "mentions", "appears_in" and title/topic associations do NOT assert causation.
-- "contributed_to" always requires human-reviewed causal evidence.
-- "adopted_by", "amended_by", "rejected_by" require verified formal-action citation.
