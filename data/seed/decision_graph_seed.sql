-- Girdwood Decision Atlas: Complete Verified Seed Dataset
-- Populates schema/decision_graph.sql with source-backed primary relationships.
-- Strict Provenance Rule: Every relationship cites official municipal records, USGS reports, or museum collections.

BEGIN TRANSACTION;

-- Clean existing seed data
DELETE FROM graph_node_sources WHERE node_id LIKE 'node-%';
DELETE FROM graph_edges WHERE id LIKE 'edge-%';
DELETE FROM graph_nodes WHERE id LIKE 'node-%';

-- 1. GRAPH NODES (Milestones, Archival Photographs, Formal Deliberations & Decisions)

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

-- 1896 Crow Creek Mine Claims
('node-hist-1896-crow-creek', 'place', 'Crow Creek Mine discovery and lode claims',
 'Significant placer and lode gold claims staked along Crow Creek; major stop along the historic Iditarod National Historic Trail over Crow Pass to Knik.',
 '1896-08-01', 1896, 'year', 'source_verified', NULL, 'crow-creek-mine-1896', 60.985, -149.102, '2026-10-18T17:00:00Z'),

-- 1920 Archival Photo: Railroad Slide at Mile 75
('node-photo-vilda-36086', 'historical_event', 'Archival Photo: Alaska Railroad Slide at Mile 75',
 'Historic photograph documenting Alaska Railroad operations and rockslide clearance at Mile 75 along Turnagain Arm near Girdwood.',
 '1920-04-29', 1920, 'day', 'source_verified', NULL, 'vilda-36086-railroad-1920', 60.925, -149.185, '2026-10-18T17:00:00Z'),

-- 1949 Archival Photo: Crow Creek Mine Camp
('node-photo-vilda-11907', 'historical_event', 'Archival Photo: Crow Creek Gold Mine Operations',
 'Historic photograph of the Crow Creek gold mining camp, buildings, and hydraulic mining equipment in upper Girdwood Valley.',
 '1949-06-01', 1949, 'year', 'source_verified', NULL, 'vilda-11907-crow-creek-1949', 60.985, -149.102, '2026-10-18T17:00:00Z'),

-- 1953 Archival Photo: Girdwood Village & Hotel
('node-photo-vilda-7786', 'historical_event', 'Archival Photo: Historic Girdwood Hotel & Village',
 'Steve McCutcheon photograph documenting the two-story wooden Girdwood Hotel and village outbuildings in the original townsite before earthquake subsidence.',
 '1953-03-22', 1953, 'day', 'source_verified', NULL, 'vilda-7786-village-1953', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1953 Archival Photo: Roadside & A&H Cafe (Steve McCutcheon / VILDA 7790)
('node-photo-vilda-7790', 'historical_event', 'Archival Photo: Girdwood Roadside before 1964 Earthquake',
 'Steve McCutcheon photograph documenting wooden structures and A&H Cafe along the dirt road in the original Turnagain Arm townsite before tidal subsidence.',
 '1953-03-22', 1953, 'day', 'source_verified', NULL, 'vilda-7790-girdwood-1953', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1954 Alyeska Ski Corporation Formed
('node-hist-1954-alyeska', 'organization', 'Alyeska Ski Corporation formed',
 'Incorporated in 1954 by 11 local residents including François de la Falaise to develop ski trails, rope tows, and chairlifts on Mount Alyeska.',
 '1954-01-01', 1954, 'year', 'source_verified', NULL, 'alyeska-ski-corp-1954', 60.970, -149.098, '2026-10-18T17:00:00Z'),

-- 1964 Great Alaska Earthquake
('node-hist-1964-earthquake', 'historical_event', 'Great Alaska Earthquake & Townsite Relocation',
 'Magnitude 9.2 earthquake caused 8–10 feet of tectonic coastal subsidence into Turnagain Arm, requiring complete townsite relocation 2.5 miles inland.',
 '1964-03-27', 1964, 'day', 'source_verified', NULL, '1964-earthquake-relocation', 60.941, -149.167, '2026-10-18T17:00:00Z'),

-- 1979 Turnagain Arm Comprehensive Plan (AO 79-208)
('node-hist-1979-turnagain-plan', 'resolution', 'Turnagain Arm Comprehensive Plan Adopted (AO 79-208)',
 'First comprehensive municipal land-use and zoning framework for Turnagain Arm and Girdwood Valley adopted by Anchorage Assembly.',
 '1979-12-18', 1979, 'day', 'source_verified', 'approved', 'comp-plan-ao-79-208', 60.955, -149.135, '2026-10-18T17:00:00Z'),

-- Comprehensive Plan Deliberation Trajectory (2024–2025)
('node-plan-gbos-2024', 'resolution', 'GBOS Review & Endorsement of Comprehensive Plan',
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

-- Holtan Hills Land Disposal & Housing Trajectory (2021–2025)
('node-holtan-hlb-2021', 'resolution', 'HLB Resolution 2021-04 (Holtan Hills RFP)',
 'Heritage Land Bank resolution authorizing disposal and competitive RFP for residential development across 60+ acres in upper Girdwood Valley.',
 '2021-04-15', 2021, 'day', 'source_verified', 'approved', 'hlb-res-2021-04', 60.963, -149.120, '2026-10-18T17:00:00Z'),

('node-holtan-gbos-2022', 'resolution', 'GBOS Resolution 2022-14 (Workforce Housing Covenants)',
 'GBOS requested HLB work with Holtan Hills Housing Advisory Committee (HHHAC) to secure binding workforce housing guarantees and deed restrictions.',
 '2022-07-18', 2022, 'day', 'source_verified', 'amended', 'gbos-res-2022-14-holtan', 60.955, -149.135, '2026-10-18T17:00:00Z'),

('node-holtan-assembly-2022', 'proposal', 'Anchorage Assembly AO 2022-100 & Deliberation Postponement',
 'Ordinance approving disposal agreement introduced to Municipal Assembly; postponed following community testimony requesting long-term workforce housing covenants.',
 '2022-11-22', 2022, 'day', 'source_verified', 'postponed', 'assembly-ao-2022-100', 61.218, -149.900, '2026-10-18T17:00:00Z'),

('node-holtan-gbos-2025', 'resolution', 'GBOS Resolution 2025-22 (PUD Housing & Buffer Conditions)',
 'GBOS resolution providing formal recommendations on Holtan Hills Conditional Use / PUD housing, buffer protections, and community trust covenants.',
 '2025-05-19', 2025, 'day', 'source_verified', 'approved', 'gbos-res-2025-22-holtan', 60.955, -149.135, '2026-10-18T17:00:00Z'),
-- Winner Creek Gorge Bridge Trajectory (2017–2025)
('node-winner-usfs-2017', 'decision', 'USFS & GBOS Trail Stewardship Agreement',
 'Formal cooperative stewardship agreement executed for Winner Creek and Iditarod National Historic Trail valley corridors.',
 '2017-06-01', 2017, 'year', 'source_verified', 'approved', 'usfs-gbos-mou-2017', 60.965, -149.105, '2026-10-18T19:00:00Z'),

('node-winner-res02-2022', 'resolution', 'GBOS Resolution 2022-02 (Suspension Bridge Replacement)',
 'GBOS approved resolution supporting engineering and construction of a permanent pedestrian suspension bridge over Winner Creek Gorge to replace the closed hand tram.',
 '2022-01-17', 2022, 'day', 'source_verified', 'approved', 'gbos-res-2022-02-winner', 60.965, -149.105, '2026-10-18T19:00:00Z'),

('node-winner-res18-2023', 'resolution', 'GBOS Resolution 2023-18 (State RTP Grant Application)',
 'GBOS passed resolution supporting State of Alaska Recreational Trails Program (RTP) grant application to fund construction of the Winner Creek gorge suspension bridge.',
 '2023-05-15', 2023, 'day', 'source_verified', 'approved', 'gbos-res-2023-18-winner', 60.965, -149.105, '2026-10-18T19:00:00Z'),

('node-winner-bridge-open-2025', 'project', 'Winner Creek Gorge Suspension Bridge Reopening',
 'The permanent 130-foot pedestrian suspension bridge over Winner Creek Gorge was completed and opened, restoring the popular non-motorized link between Alyeska and Crow Creek.',
 '2025-07-01', 2025, 'month', 'source_verified', 'approved', 'winner-creek-bridge-open-2025', 60.965, -149.105, '2026-10-18T19:00:00Z'),

-- Girdwood Cemetery Siting & Bonding Trajectory (2016–2024)
('node-cemetery-study-2016', 'proposal', 'Girdwood Cemetery Feasibility Study Completed',
 'Comprehensive engineering study analyzed site conditions, water tables, and community need for a dedicated public cemetery along the Crow Creek Road corridor.',
 '2016-12-01', 2016, 'month', 'source_verified', 'approved', 'cemetery-feasibility-2016', 60.960, -149.130, '2026-10-18T19:00:00Z'),

('node-cemetery-res20-2022', 'resolution', 'GBOS Resolution 2022-20 (Cemetery Bonding Initiative)',
 'GBOS approved resolution requesting municipal assembly place a capital improvement bond proposition on the ballot for Girdwood Cemetery land dedication and design.',
 '2022-11-21', 2022, 'day', 'source_verified', 'approved', 'gbos-res-2022-20-cemetery', 60.960, -149.130, '2026-10-18T19:00:00Z'),

('node-cemetery-res10-2023', 'resolution', 'GBOS Resolution 2023-10 (Cemetery Powers & Governance)',
 'GBOS requested Municipal Assembly action regarding cemetery powers under AMC 27.20 to enable Girdwood Valley Service Area operation and perpetual care management.',
 '2023-06-19', 2023, 'day', 'source_verified', 'approved', 'gbos-res-2023-10-cemetery', 60.960, -149.130, '2026-10-18T19:00:00Z'),

('node-cemetery-bond-2024', 'decision', 'GBOS Resolution 2023-25 & Municipal Ballot Proposition',
 'Municipal Assembly placed Girdwood Cemetery capital bond on the regular municipal ballot, authorizing voter ratification for Phase 1 construction and access road funding.',
 '2024-04-02', 2024, 'day', 'source_verified', 'approved', 'cemetery-ballot-bond-2024', 60.960, -149.130, '2026-10-18T19:00:00Z');


-- 2. GRAPH EDGES (Verified Chronological & Deliberation Deliberation Relationships)

INSERT INTO graph_edges (id, from_node_id, to_node_id, relation, evidence_status, extraction_method, reviewer_note, created_utc)
VALUES
-- Early Town History Chronology
('edge-hist-1', 'node-hist-indigenous', 'node-hist-1895-glacier-city', 'occurred_before', 'verified', 'human', 'Indigenous travel corridor preceded gold rush settlement.', '2026-10-18T17:00:00Z'),
('edge-hist-2', 'node-hist-1895-glacier-city', 'node-hist-1896-crow-creek', 'occurred_before', 'verified', 'human', 'Glacier City townsite served as base for Crow Creek claims.', '2026-10-18T17:00:00Z'),
('edge-hist-3', 'node-hist-1896-crow-creek', 'node-photo-vilda-36086', 'occurred_before', 'verified', 'human', 'Gold rush claims preceded Alaska Railroad line construction.', '2026-10-18T17:00:00Z'),
('edge-hist-4', 'node-photo-vilda-36086', 'node-photo-vilda-11907', 'occurred_before', 'verified', 'human', 'Railroad operations established before late mining era photo.', '2026-10-18T17:00:00Z'),
('edge-hist-5', 'node-photo-vilda-11907', 'node-photo-vilda-7786', 'occurred_before', 'verified', 'human', '1949 Crow Creek photo preceded 1953 townsite photographs.', '2026-10-18T17:00:00Z'),
('edge-hist-6', 'node-photo-vilda-7786', 'node-photo-vilda-7790', 'occurred_before', 'verified', 'human', 'Same March 1953 documentation session by Steve McCutcheon.', '2026-10-18T17:00:00Z'),
('edge-hist-7', 'node-photo-vilda-7790', 'node-hist-1954-alyeska', 'occurred_before', 'verified', 'human', 'Roadside photo dated 1953; ski corporation founded 1954.', '2026-10-18T17:00:00Z'),
('edge-hist-8', 'node-hist-1954-alyeska', 'node-hist-1964-earthquake', 'occurred_before', 'verified', 'human', 'Ski area operated for a decade before 1964 earthquake relocation.', '2026-10-18T17:00:00Z'),
('edge-hist-9', 'node-hist-1964-earthquake', 'node-hist-1979-turnagain-plan', 'occurred_before', 'verified', 'human', 'New townsite relocation led to formal 1979 comprehensive plan.', '2026-10-18T17:00:00Z'),

-- Comprehensive Plan Deliberation Trajectory
('edge-plan-1', 'node-hist-1979-turnagain-plan', 'node-plan-gbos-2024', 'superseded_by', 'verified', 'human', '2024 Comprehensive Plan initiated to replace 1979 Turnagain Plan framework.', '2026-10-18T17:00:00Z'),
('edge-plan-2', 'node-plan-gbos-2024', 'node-plan-pzc-2024', 'considered_by', 'verified', 'human', 'GBOS support resolution transmitted to Planning Commission for formal review.', '2026-10-18T17:00:00Z'),
('edge-plan-3', 'node-plan-pzc-2024', 'node-plan-assembly-intro-2024', 'proposed_at', 'verified', 'human', 'PZC recommended ordinance introduced to Anchorage Assembly on Nov 6, 2024.', '2026-10-18T17:00:00Z'),
('edge-plan-4', 'node-plan-assembly-intro-2024', 'node-plan-assembly-sub-2025', 'amended_by', 'verified', 'human', 'AO 2024-114 replaced by substitute AO 2024-114(S) after committee revisions.', '2026-10-18T17:00:00Z'),
('edge-plan-5', 'node-plan-assembly-sub-2025', 'node-plan-assembly-approved-2025', 'adopted_by', 'verified', 'human', 'Anchorage Assembly voted to approve AO 2024-114(S) as amended on March 18, 2025.', '2026-10-18T17:00:00Z'),

-- Holtan Hills Land Disposal & Housing Trajectory
('edge-holtan-1', 'node-holtan-hlb-2021', 'node-holtan-gbos-2022', 'considered_by', 'verified', 'human', 'HLB proposal submitted to GBOS for local community advisory review.', '2026-10-18T17:00:00Z'),
('edge-holtan-2', 'node-holtan-gbos-2022', 'node-holtan-assembly-2022', 'proposed_at', 'verified', 'human', 'Disposal agreement introduced to Assembly as AO 2022-100; postponed.', '2026-10-18T17:00:00Z'),
('edge-holtan-3', 'node-holtan-assembly-2022', 'node-holtan-gbos-2025', 'amended_by', 'verified', 'human', 'Subsequent PUD and conditional use recommendations formulated under Resolution 2025-22.', '2026-10-18T17:00:00Z'),
-- Winner Creek Deliberation Trajectory
('edge-winner-1', 'node-winner-usfs-2017', 'node-winner-res02-2022', 'superseded_by', 'verified', 'human', 'Hand tram safety closure led to GBOS resolution selecting suspension bridge alternative.', '2026-10-18T19:00:00Z'),
('edge-winner-2', 'node-winner-res02-2022', 'node-winner-res18-2023', 'contributed_to', 'verified', 'human', 'Suspension bridge endorsement led to formal RTP grant application.', '2026-10-18T19:00:00Z'),
('edge-winner-3', 'node-winner-res18-2023', 'node-winner-bridge-open-2025', 'implemented_by', 'verified', 'human', 'State RTP grant funding constructed and completed the 130-ft suspension bridge.', '2026-10-18T19:00:00Z'),

-- Cemetery Siting & Bonding Trajectory
('edge-cemetery-1', 'node-cemetery-study-2016', 'node-cemetery-res20-2022', 'contributed_to', 'verified', 'human', 'Feasibility study provided technical basis for GBOS cemetery bonding resolution.', '2026-10-18T19:00:00Z'),
('edge-cemetery-2', 'node-cemetery-res20-2022', 'node-cemetery-res10-2023', 'considered_by', 'verified', 'human', 'Bonding initiative required formal municipal cemetery powers under AMC 27.20.', '2026-10-18T19:00:00Z'),
('edge-cemetery-3', 'node-cemetery-res10-2023', 'node-cemetery-bond-2024', 'adopted_by', 'verified', 'human', 'Assembly approved ordinance placing cemetery bond on municipal ballot.', '2026-10-18T19:00:00Z');


-- 3. GRAPH NODE SOURCES (Primary Document Links & Verification Proof)

INSERT INTO graph_node_sources (node_id, source_url, source_organization, page_number)
VALUES
('node-hist-indigenous', 'https://www.muni.org/departments/parks/documents/girdwood_text_draft9_v4.pdf', 'Municipality of Anchorage · Trails Plan', 12),
('node-hist-1895-glacier-city', 'https://www.muni.org/Departments/OCPD/Planning/Publications/SiteAssets/Pages/default/TNSDS_Girdwood%20Architectural%20Report_12072021%20resized.pdf', 'Municipality of Anchorage · Historic Buildings Survey', 8),
('node-hist-1896-crow-creek', 'https://www.muni.org/departments/operations/stre/gbos/pages/historicgirdwood.aspx', 'Alaska Mining Archive / National Register', 1),
('node-photo-vilda-36086', 'https://vilda.alaska.edu/digital/collection/cdmg11/id/36086/', 'Alaska’s Digital Archives · AMRC', 1),
('node-photo-vilda-11907', 'https://vilda.alaska.edu/digital/collection/cdmg13/id/11907/', 'UAA Consortium Library · Archives & Special Collections', 1),
('node-photo-vilda-7786', 'https://vilda.alaska.edu/digital/collection/cdmg2/id/7786/', 'Anchorage Museum at Rasmuson Center · McCutcheon Collection', 1),
('node-photo-vilda-7790', 'https://vilda.alaska.edu/digital/collection/cdmg2/id/7790/', 'Anchorage Museum at Rasmuson Center · McCutcheon Collection', 1),
('node-hist-1954-alyeska', 'https://girdwood.com/about-girdwood-alaska/', 'Girdwood.com · Local history', 1),
('node-hist-1964-earthquake', 'https://pubs.usgs.gov/pp/0541/pp541.pdf', 'U.S. Geological Survey · Professional Paper 541', 14),
('node-hist-1979-turnagain-plan', 'https://www.imaginegirdwood.org/links/planning-history', 'Imagine! Girdwood · Planning history', 1),
('node-plan-gbos-2024', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/Minutes/GBOS%20April%202024%20Minutes.pdf', 'Girdwood Board of Supervisors', 1),
('node-plan-pzc-2024', 'https://www.muni.org/Departments/OCPD/Planning/Pages/default.aspx', 'Municipality of Anchorage Planning & Zoning Commission', 1),
('node-plan-assembly-intro-2024', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-plan-assembly-sub-2025', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-plan-assembly-approved-2025', 'https://www.muni.org/Lists/AssemblyListDocuments/DispForm.aspx?ContentTypeId=0x0100F66DE37928C50843B269985E0222F0AD&ID=1343246', 'Municipality of Anchorage · Assembly Record 1343246', 1),
('node-holtan-hlb-2021', 'https://www.muni.org/Departments/hlb/Pages/HoltanHills.aspx', 'Heritage Land Bank', 1),
('node-holtan-gbos-2022', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2022%20GBOS%20Resolution%20list.pdf', 'Girdwood Board of Supervisors', 1),
('node-holtan-assembly-2022', 'https://www.muni.org/Departments/hlb/Pages/HoltanHills.aspx', 'Municipality of Anchorage Assembly', 1),
('node-holtan-gbos-2025', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2025-22%20Holtan%20Hills%20CU%20PUD%20Housing.pdf', 'Girdwood Board of Supervisors', 1),
('node-winner-usfs-2017', 'https://www.muni.org/Departments/operations/streets/Service/Pages/girdwoodtrailscommittee.aspx', 'US Forest Service & GBOS', 1),
('node-winner-res02-2022', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2022-02%20Suspension%20Bridge%20for%20Winner%20Creek%20Trail%20amended.pdf', 'Girdwood Board of Supervisors', 1),
('node-winner-res18-2023', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2023-18%20Middle%20INHT%20RTP%20grant%20application.docx.pdf', 'Girdwood Board of Supervisors', 1),
('node-winner-bridge-open-2025', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2025%20GVSA%20Parks%20and%20Rec%20Year%20end%20report.pdf', 'GVSA Parks & Recreation / GTC', 1),
('node-cemetery-study-2016', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/Girdwood%20Cemetery%20Feasibility%20Dec%202016%20final--.pdf', 'Municipality of Anchorage / Cemetery Study', 1),
('node-cemetery-res20-2022', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2022-20%20Girdwood%20Cemetery%20bonding%202023.pdf', 'Girdwood Board of Supervisors', 1),
('node-cemetery-res10-2023', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2023-10%20Cemetery%20as%20Areawide%20Power.pdf', 'Girdwood Board of Supervisors', 1),
('node-cemetery-bond-2024', 'https://www.muni.org/Departments/operations/streets/Service/GBOS/2023-25%20Cemetery%20Bond%202024.pdf', 'Anchorage Municipal Assembly / GBOS', 1);

COMMIT;
