# Girdwood.city — 100 additional civic-archive and RAG ideas

Independent source-linked public record search, using the Girdwood AlaskaArchive public dataset and Cloudflare services. These ideas extend the existing 100 tourism and community pages rather than repeating them.

## SOURCE DISCOVERY
101. GBOS complete document-link inventory
102. LUC meeting packet collection
103. Trails committee minutes collection
104. Housing & Economic Committee collection
105. Public Safety Committee record collection
106. Cemetery planning and feasibility records
107. GBOS resolutions historical backfill
108. Heritage Land Bank Girdwood-only collection
109. Community Council 2005-onward pagination
110. Imagine Girdwood plan and revision history

## HISTORICAL RECONSTRUCTION
111. Year-by-year record coverage dashboard
112. 1999–2004 municipal archive request queue
113. 2005–2014 committee backfill program
114. 2015–present resolution completeness audit
115. Cancelled-meeting and no-record ledger
116. Draft versus final records pairing
117. Cross-agency duplicate detection
118. Broken-original-link recovery index
119. Historical meeting calendar rebuild
120. Annual archives download bundle

## DATA INTEGRITY AND PROVENANCE
121. Exact source URL preservation
122. Independent source-page URL preservation
123. Original file SHA-256 fingerprints
124. HTTP ETag and Last-Modified tracking
125. Download and retrieval timestamp ledger
126. Content supersession and version history
127. Document rights and reuse metadata
128. Organization-of-origin authoritative registry
129. Original-language unmodified text storage
130. Public correction and discrepancy log

## BETTER EXTRACTION AND DOCUMENT AI
131. Scanned PDF page OCR queue
132. Legacy DOC to text conversion
133. Spreadsheet table extraction
134. Slide deck notes and text extraction
135. Attachments within meeting packets separation
136. Vote motion and outcome recognition
137. Resolution number extraction
138. Parcel identifier and georeference extraction
139. Budget amount and year recognition
140. Human validation screen for questionable facts

## POWER SEARCH
141. Cross-organization universal search
142. Exact phrase with page highlights
143. Filter by committee or organization
144. Filter by year and meeting date
145. Filter by record type and status
146. Filter by parcel and development project
147. Filter by involved person or organization
148. Search within one meeting packet
149. Hybrid keyword and semantic reranking
150. Copy citation with precise PDF page

## AI ANSWER FEATURES
151. Ask why a decision changed over time
152. Proposed versus adopted decision comparison
153. Chronological topic summaries with sources
154. What changed from prior meeting answers
155. Multi-board cross-reference answers
156. Show contradictory source accounts
157. Follow-up questions retaining search filters
158. Evidence-only response mode
159. Research answer export with bibliography
160. Explicit insufficient-evidence answers

## CIVIC ISSUES AND TOPIC TRACKERS
161. Holtan Hills project timeline
162. Workforce housing policy history
163. Short-term rentals proposal tracker
164. Industrial Park parcel and lease tracker
165. Road maintenance budget timelines
166. Fire and EMS funding history
167. Seward Highway and access proposals
168. Trails maintenance and project approvals
169. Comprehensive Plan amendment tracker
170. Local grants and nonprofit funding tracker

## MAPS AND GRAPH EXPLORERS
171. Map records to known parcel geometries
172. Historical parcel decision timeline map
173. Trail project map with source links
174. Municipal service-area boundaries explorer
175. Document-to-organization relationship graph
176. Resolution-to-project relationship graph
177. Chronology visualization for each issue
178. People mentioned in public records index
179. Compare historical and current land-use maps
180. Geographic evidence layer confidence badges

## CITIZEN EXPERIENCE AND ACCESS
181. Mobile five-tab civic archive navigation
182. Accessible PDF-to-HTML reading mode
183. Public meeting upcoming agenda hub
184. Email alerts by topic or committee
185. RSS feeds for newly indexed documents
186. Community-submitted missing record tips
187. Report misattribution or OCR errors
188. Shareable research collections
189. Printable fact sheets with source footnotes
190. Plain-language public meeting explainer

## INDEPENDENCE, OPERATIONS AND REUSE
191. Public read-only JSON index export
192. OpenAPI specification for civic search
193. Daily incremental crawler with failure alerts
194. Weekly source-specific coverage reports
195. Self-hostable search and ingestion docs
196. Cloudflare costs and request usage dashboard
197. Privacy minimization and PII review
198. Source policy and takedown review process
199. Disaster recovery and R2 versioned backup
200. Future Alaska communities federation model

## Delivery sequence

Phase A: 101-130 source discovery, historical backfill, integrity and provenance. Phase B: 131-150 extraction and search. Phase C: 151-170 verified AI answers and civic issue timelines. Phase D: 171-200 maps, citizen workflows and reuse. Build with no invented records, keep official source URLs, make missing coverage transparent, and separate proposed from adopted decisions.

## Source of truth

The archive repository owns source manifests and ingestion definitions; Girdwood.city and AlaskaArchive clients share a read-only search API. Store large files in R2 as permissions permit, not in the Git repository. Every record must carry source organization, official source page URL, exact original file URL, cryptographic hash, retrieval date and page locator. A copied file is not a replacement for the original.
