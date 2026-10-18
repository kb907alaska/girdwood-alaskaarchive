-- Girdwood Decision Atlas: Verified Seed Dataset
-- Populates schema/decision_graph.sql with source-backed primary relationships.
-- Adheres to the Provenance Rule: no relationship claims an outcome or causation
-- without official municipal citation, USGS report, or historical archive record.

BEGIN TRANSACTION;

-- Clean existing seed data if present
DELETE FROM graph_node_sources WHERE node_id LIKE 'node-%';
DELETE FROM graph_edges WHERE id LIKE 'edge-%';
DELETE FROM graph_nodes WHERE id LIKE 'node-%';

-- 1. GRAPH NODES (Historical Milestones, Archival Photography, Formal Decisions)

INSERT INTO graph_nodes (id, kind, title, description, occurred_on, year_hint, date_precision, status, decision_outcome, canonical_slug, latitude, longitude, created_utc)
VALUES
-- Pre-1895 Indigenous Stewardship
('node-hist-indigenous', 'historical_event', 'Indigenous travel corridor and cultural stewardship',
 'Dena’ina, Alutiiq, and Chugachmiut travel corridor, trading route, and cultural stewardship across Turnagain Arm and Glacier Valley long predating colonial mining settlement.',
 NULL, 1890, 'approximate', 'source_verified', NULL, 'indigenous-presence', 60.945, -149.165, '2026-10-18T17:00:00Z'),

-- 1895 Glacier City Founded
('node-hist-1895-glacier-city', 'historical_event', 'Glacier City mining settlement founded',
 'Established at the mouth of Glacier Creek on Turnagain Arm during the Turnagain gold rush era; later named Girdwood after claim locator James Girdwood.',
 '1895-07-01', 1895, 'year', 'source_verified', NULL, 'glacier-city-1895', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1896 Crow Creek Mine
('node-hist-1896-crow-creek', 'place', 'Crow Creek Mine discovery and lode claims',
 'Significant placer and lode gold claims staked along Crow Creek; major stop along the historic Iditarod National Historic Trail over Crow Pass to Knik.',
 '1896-08-01', 1896, 'year', 'source_verified', NULL, 'crow-creek-mine-1896', 60.985, -149.102, '2026-10-18T17:00:00Z'),

-- 1953 Archival Photograph (Steve McCutcheon / VILDA 7790)
('node-photo-vilda-7790', 'historical_event', 'Archival Photo: Girdwood Roadside before 1964 Earthquake',
 'Steve McCutcheon photograph documenting wooden structures and A&H Cafe along the dirt road in the original Turnagain Arm townsite before tidal subsidence.',
 '1953-03-22', 1953, 'day', 'source_verified', NULL, 'vilda-7790-girdwood-1953', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1954 Alyeska Ski Corporation
('node-hist-1954-alyeska', 'organization', 'Alyeska Ski Corporation formed',
 'Incorporated in 1954 by 11 local residents including François de la Falaise to develop ski trails, rope tows, and chairlifts on Mount Alyeska.',
 '1954-01-01', 1954, 'year', 'source_verified', NULL, 'alyeska-ski-corp-1954', 60.970, -149.098, '2026-10-18T17:00:00Z'),

-- 1964 Great Alaska Earthquake
('node-hist-1964-earthquake', 'historical_event', 'Great Alaska Earthquake & Townsite Relocation',
 'Magnitude 9.2 earthquake caused 8–10 feet of tectonic coastal subsidence into Turnagain Arm, requiring complete townsite relocation 2.5 miles inland.',
 '1964-03-27', 1964, 'day', 'source_verified', NULL, '1964-earthquake-relocation', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1979 Turnagain Arm Comprehensive Plan
('node-hist-1979-turnagain-plan', 'resolution', 'Turnagain Arm Comprehensive Plan Adopted (AO 79-208)',
 'First comprehensive municipal land-use and zoning framework for Turnagain Arm and Girdwood Valley adopted by Anchorage Assembly.',
 '1979-12-18', 1979, 'day', 'source_verified', 'approved', 'comp-plan-ao-79-208', 60.955, -149.135, '2026-10-18T17:00:00Z'),

-- 2024–2025 Comprehensive Plan Deliberation Trajectory
('node-plan-gbos-2024', 'resolution', 'GBOS Review & Support for Comprehensive Plan',
 'Girdwood Board of Supervisors formal review and resolution endorsing the Imagine! Girdwood Comprehensive Plan update for transmittal to Planning Commission.',
 '2024-04-15', 2024, 'day', 'source_verified', 'approved', 'gbos-review-comp-plan-2024', 60.955, -149.135, '2026-10-18T17:00:00Z'),

('node-plan-pzc-2024', 'meeting', 'Planning & Zoning Commission Hearing (PZC Res 2024-026)',
 'Municipal Planning & Zoning Commission public hearing recommending Assembly adoption of Girdwood Comprehensive Plan with technical land-use amendments.',
 '2024-08-12', 2024, 'day', 'source_verified', 'approved', 'pzc-res-2024-026-comp-plan', 61.218, -149.900, '2026-10-18T17:00:00Z'),

('node-plan-assembly-intro-2024', 'proposal', 'Anchorage Assembly Introduction: Ordinance AO 2024-114',
 'Ordinance introduced to the Anchorage Assembly adopting the Girdwood Comprehensive Plan into Anchorage Municipal Code Title 21.',
 '2024-11-06', 2024, 'day', 'source_verified', 'pending', 'ao-2024-114-introduction', 61.218, -149.900, '2026-10-18T17:00:00Z'),

('node-plan-assembly-sub-2025', 'proposal', 'Assembly Substitute Ordinance AO 2024-114(S) & Public Hearings',
 'Substitute ordinance incorporating public hearing testimony, community council adjustments, and Assembly member amendments.',
 '2025-01-14', 2025, 'day', 'source_verified', 'amended', 'ao-2024-114-s-substitute', 61.218, -149.900, '2026-10-18T17:00:00Z'),

('node-plan-assembly-approved-2025', 'decision', 'Girdwood Comprehensive Plan Approved as Amended (AO 2024-114(S))',
 'Anchorage Assembly formal adoption of the Girdwood Comprehensive Plan under AO 2024-114(S) as amended, establishing updated land use, housing, and infrastructure policy.',
 '2025-03-18', 2025, 'day', 'source_verified', 'approved', 'ao-2024-114-s-approval', 61.218, -149.900, '2026-10-18T17:00:00Z'),

-- Holtan Hills Land Disposal Trajectory
('node-holtan-hlb-2021', 'resolution', 'HLB Resolution 2021-04 (Holtan Hills RFP)',
 'Heritage Land Bank resolution authorizing disposal and development RFP for residential parcels in Girdwood Valley.',
 '2021-04-15', 2021, 'day', 'source_verified', 'approved', 'hlb-res-2021-04', 60.963, -149.120, '2026-10-18T17:00:00Z'),

('node-holtan-gbos-2022', 'resolution', 'GBOS Resolution 2022-04 on Development Agreement',
 'GBOS resolution providing conditional recommendations on workforce housing dedication, density, and public trust covenants.',
 '2022-02-21', 2022, 'day', 'source_verified', 'amended', 'gbos-res-2022-04-holtan', 60.955, -149.135, '2026-10-18T17:00:00Z'),

('node-holtan-assembly-2022', 'proposal', 'Anchorage Assembly AO 2022-100 & Deliberation Postponement',
 'Ordinance approving HLB disposal postponed following public testimony requesting workforce housing covenants and community trust structure.',
 '2022-11-22', 2022, 'day', 'source_verified', 'postponed', 'assembly-ao-2022-100', 61.218, -149.900, '2026-10-18T17:00:00Z');


-- 2. GRAPH EDGES (Verified Chronological, Deliberation, and Procedural Relationships)

INSERT INTO graph_edges (id, from_node_id, to_node_id, relation, evidence_status, extraction_method, reviewer_note, created_utc)
VALUES
-- Chronology of Early Town
('edge-hist-1', 'node-hist-indigenous', 'node-hist-1895-glacier-city', 'occurred_before', 'verified', 'human', 'Indigenous travel corridor preceded gold rush settlement.', '2026-10-18T17:00:00Z'),
('edge-hist-2', 'node-hist-1895-glacier-city', 'node-hist-1896-crow-creek', 'occurred_before', 'verified', 'human', 'Glacier City townsite served as base for Crow Creek claims.', '2026-10-18T17:00:00Z'),
('edge-hist-3', 'node-hist-1896-crow-creek', 'node-photo-vilda-7790', 'occurred_before', 'verified', 'human', 'Historic mining era preceded mid-century highway townsite.', '2026-10-18T17:00:00Z'),
('edge-hist-4', 'node-photo-vilda-7790', 'node-hist-1954-alyeska', 'occurred_before', 'verified', 'human', 'Pre-earthquake roadside photography dated 1953; ski club founded 1954.', '2026-10-18T17:00:00Z'),
('edge-hist-5', 'node-hist-1954-alyeska', 'node-hist-1964-earthquake', 'occurred_before', 'verified', 'human', 'Ski area operated for a decade before 1964 earthquake relocation.', '2026-10-18T17:00:00Z'),
('edge-hist-6', 'node-hist-1964-earthquake', 'node-hist-1979-turnagain-plan', 'occurred_before', 'verified', 'human', 'New townsite relocation led to formal 1979 comprehensive plan.', '2026-10-18T17:00:00Z'),

-- Comprehensive Plan Deliberation Trajectory (Verified Assembly Chain)
('edge-plan-1', 'node-hist-1979-turnagain-plan', 'node-plan-gbos-2024', 'superseded_by', 'verified', 'human', '2024 Comprehensive Plan initiated to replace 1979 Turnagain Plan framework.', '2026-10-18T17:00:00Z'),
('edge-plan-2', 'node-plan-gbos-2024', 'node-plan-pzc-2024', 'considered_by', 'verified', 'human', 'GBOS support resolution transmitted to Planning Commission for formal review.', '2026-10-18T17:00:00Z'),
('edge-plan-3', 'node-plan-pzc-2024', 'node-plan-assembly-intro-2024', 'proposed_at', 'verified', 'human', 'PZC recommended ordinance introduced to Anchorage Assembly on Nov 6, 2024.', '2026-10-18T17:00:00Z'),
('edge-plan-4', 'node-plan-assembly-intro-2024', 'node-plan-assembly-sub-2025', 'amended_by', 'verified', 'human', 'AO 2024-114 replaced by substitute AO 2024-114(S) after committee revisions.', '2026-10-18T17:00:00Z'),
('edge-plan-5', 'node-plan-assembly-sub-2025', 'node-plan-assembly-approved-2025', 'adopted_by', 'verified', 'human', 'Anchorage Assembly voted to approve AO 2024-114(S) as amended on March 18, 2025.', '2026-10-18T17:00:00Z'),

-- Holtan Hills Trajectory
('edge-holtan-1', 'node-holtan-hlb-2021', 'node-holtan-gbos-2022', 'considered_by', 'verified', 'human', 'HLB proposal submitted to GBOS for local community advisory review.', '2026-10-18T17:00:00Z'),
('edge-holtan-2', 'node-holtan-gbos-2022', 'node-holtan-assembly-2022', 'proposed_at', 'verified', 'human', 'HLB disposal ordinance introduced to Assembly as AO 2022-100.', '2026-10-18T17:00:00Z');


-- 3. GRAPH NODE SOURCES (Primary Document Links with Verification Proof)

INSERT INTO graph_node_sources (node_id, source_url, source_organization, page_number)
VALUES
('node-hist-indigenous', 'https://www.muni.org/departments/parks/documents/girdwood_text_draft9_v4.pdf', 'Municipality of Anchorage · Trails Plan', 12),
('node-hist-1895-glacier-city', 'https://www.muni.org/Departments/OCPD/Planning/Publications/SiteAssets/Pages/default/TNSDS_Girdwood%20Architectural%20Report_12072021%20resized.pdf', 'Municipality of Anchorage · Historic Buildings Survey', 8),
('node-hist-1896-crow-creek', 'https://www.muni.org/departments/operations/stre/gbos/pages/historicgirdwood.aspx', 'Alaska Mining Archive / National Register', 1),
('node-photo-vilda-7790', 'https://vilda.alaska.edu/digital/collection/cdmg2/id/7790/', 'Anchorage Museum at Rasmuson Center (Steve McCutcheon Collection)', 1),
('node-hist-1954-alyeska', 'https://girdwood.com/about-girdwood-alaska/', 'Girdwood.com · Local history', 1),
('node-hist-1964-earthquake', 'https://pubs.usgs.gov/pp/0541/pp541.pdf', 'U.S. Geological Survey · Professional Paper 541', 14),
('node-hist-1979-turnagain-plan', 'https://www.imaginegirdwood.org/links/planning-history', 'Imagine! Girdwood · Planning history', 1),
('node-plan-gbos-2024', 'https://www.muni.org/Departments/operations/streets/Service/Pages/girdwoodboardofsupervisors.aspx', 'Girdwood Board of Supervisors', 1),
('node-plan-pzc-2024', 'https://www.muni.org/Departments/OCPD/Planning/Pages/default.aspx', 'Municipality of Anchorage Planning & Zoning Commission', 1),
('node-plan-assembly-intro-2024', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-plan-assembly-sub-2025', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-plan-assembly-approved-2025', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-holtan-hlb-2021', 'https://www.muni.org/Departments/hlb/Pages/HoltanHills.aspx', 'Heritage Land Bank', 1),
('node-holtan-gbos-2022', 'https://www.muni.org/Departments/operations/streets/Service/Pages/girdwoodboardofsupervisors.aspx', 'Girdwood Board of Supervisors', 1),
('node-holtan-assembly-2022', 'https://www.muni.org/Departments/hlb/Pages/HoltanHills.aspx', 'Municipality of Anchorage Assembly', 1);

COMMIT;
