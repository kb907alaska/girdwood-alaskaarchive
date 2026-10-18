#!/usr/bin/env python3
"""Review and optionally mirror publicly accessible municipal source PDFs.

Dry-run by default. Save originals under gitignored data/raw/mirrors/ and retain
canonical original_url, parent source_pages, organization, retrieval UTC,
sha256, MIME type, byte count and original filename in local JSON metadata.

Usage: python scripts/mirror_public_docs.py --limit 20
       python scripts/mirror_public_docs.py --download --limit 20
Before public redistribution: verify rights/reuse and personal-information handling.
"""
import argparse, hashlib, json, mimetypes, time
from datetime import datetime,timezone
from pathlib import Path
from urllib.parse import urlsplit,unquote
from urllib.robotparser import RobotFileParser
import requests
ROOT=Path(__file__).resolve().parents[1]
CAT=ROOT/"data/sources/catalog.json"
MAN=ROOT/"data/municipal/manifest.json"
OUT=ROOT/"data/raw/mirrors"
ALLOWED_HOSTS={"muni.org","www.muni.org"}
AGENT="GirdwoodCivicArchive/0.2 (+https://girdwood.city/archive)"
SESSION=requests.Session()
SESSION.headers["User-Agent"]=AGENT
ROBOTS={}

def can_fetch(url):
    u=urlsplit(url)
    base=u.scheme+"://"+u.netloc
    if base not in ROBOTS:
        rp=RobotFileParser(base+"/robots.txt")
        try:rp.read();ROBOTS[base]=rp
        except Exception:ROBOTS[base]=None
    return ROBOTS[base] is not None and ROBOTS[base].can_fetch(AGENT,url)

def candidates():
    found={}
    if MAN.exists():
        for doc in json.loads(MAN.read_text(encoding="utf-8")).get("documents",[]):
            if str(doc.get("file_type","")).lower()!="pdf":continue
            url=doc.get("original_url")
            if url:found[url]={"original_url":url,"title":doc.get("title",""),
                "source_pages":doc.get("source_pages",[]),"organization":"Municipality of Anchorage"}
    if CAT.exists():
        for doc in json.loads(CAT.read_text(encoding="utf-8")).get("records",[]):
            url=doc.get("original_url")
            if not url or not urlsplit(url).path.lower().endswith(".pdf"):continue
            if not any(s.get("rights_review")=="public_government" for s in doc.get("source_links",[])):continue
            found[url]={"original_url":url,"title":doc.get("title",""),
                "source_pages":sorted(set(s["source_page"] for s in doc["source_links"])),
                "organization":doc.get("organization")}
    return list(found.values())

def download(url,max_bytes):
    if not can_fetch(url):raise ValueError("robots policy not accessible/allowed")
    with SESSION.get(url,stream=True,timeout=(15,60),allow_redirects=True) as r:
        r.raise_for_status()
        if urlsplit(r.url).hostname not in ALLOWED_HOSTS:raise ValueError("unapproved redirect")
        if int(r.headers.get("Content-Length","0"))>max_bytes:raise ValueError("file exceeds size limit")
        chunks,total=[],0
        for chunk in r.iter_content(65536):
            total+=len(chunk)
            if total>max_bytes:raise ValueError("file exceeds size limit")
            chunks.append(chunk)
        data=b"".join(chunks)
        if not data.startswith(b"%PDF-"):raise ValueError("expected PDF data")
        return data,r.url,r.headers.get("Content-Type","application/pdf")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--download",action="store_true",help="Opt in after source/rights review")
    p.add_argument("--limit",type=int,default=20)
    p.add_argument("--max-mb",type=int,default=25)
    a=p.parse_args()
    docs=[d for d in candidates() if urlsplit(d["original_url"]).hostname in ALLOWED_HOSTS]
    print("Eligible candidate PDFs:",len(docs),"Mode:","download" if a.download else "DRY RUN")
    OUT.mkdir(parents=True,exist_ok=True)
    results=[]
    for d in docs[:max(0,min(a.limit,500))]:
        if not a.download:
            print("Candidate:",d["original_url"])
            continue
        try:
            b,final,mime=download(d["original_url"],a.max_mb*1024*1024)
            digest=hashlib.sha256(b).hexdigest()
            path=OUT/(digest+".pdf")
            if not path.exists():path.write_bytes(b)
            record={**d,"sha256":digest,"original_filename":unquote(urlsplit(d["original_url"]).path.rsplit("/",1)[-1]),
                "retrieved_utc":datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "final_response_url":final,"mime":mime,"bytes":len(b),"local_path":path.name,
                "redistribution_review":"required"}
            results.append(record)
            print("Mirrored",path.name,"from",d["original_url"])
        except Exception as exc:print("Skipped:",d["original_url"],str(exc)[:180])
        time.sleep(0.65)
    if a.download:
        (OUT/"mirror-manifest.json").write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        print("Locally mirrored:",len(results),"(not automatically uploaded or republished)")
if __name__=="__main__":
    main()
