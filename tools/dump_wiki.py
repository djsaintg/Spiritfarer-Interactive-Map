import json, sys, os, time, urllib.request, urllib.parse
out = sys.argv[1]; cats = sys.argv[2:]
API = "https://spiritfarer.fandom.com/api.php"
def get(params):
    params["format"]="json"
    req = urllib.request.Request(API+"?"+urllib.parse.urlencode(params), headers={"User-Agent":"SpiritfarerMapFanTool/0.1"})
    return json.load(urllib.request.urlopen(req))
index = {}
for cat in cats:
    cont = {}
    while True:
        r = get({"action":"query","generator":"categorymembers","gcmtitle":"Category:"+cat,"gcmlimit":"50","gcmnamespace":"0",
                 "prop":"revisions","rvprop":"content","rvslots":"main", **cont})
        for p in r.get("query",{}).get("pages",{}).values():
            t = p["title"]; txt = p["revisions"][0]["slots"]["main"]["*"] if "revisions" in p else ""
            fn = t.replace("/","_").replace(" ","_")+".wiki"
            open(os.path.join(out,fn),"w").write(txt)
            index.setdefault(cat,[]).append(t)
        if "continue" in r: cont = {k:v for k,v in r["continue"].items()}
        else: break
        time.sleep(0.3)
json.dump(index, open(os.path.join(out,"_index.json"),"w"), indent=1)
print({k:len(v) for k,v in index.items()})
