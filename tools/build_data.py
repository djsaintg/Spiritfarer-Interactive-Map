"""Builds src/data/spiritfarer.json from dumped Spiritfarer Fandom wikitext (see update_data.sh).
usage: python3 -I build_data.py <pages dir> <output json>
"""
import html, json, os, re, sys, urllib.request, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wikiparse import find_template, clean, links, sections, listitems, coords

P, OUT = sys.argv[1], sys.argv[2]
IDX = json.load(open(os.path.join(P, "_index.json")))

def page(t):
    fn = os.path.join(P, t.replace("/", "_").replace(" ", "_") + ".wiki")
    return open(fn).read() if os.path.exists(fn) else ""

def slug(t):
    return re.sub(r"[^a-z0-9]+", "-", t.lower().replace("'", "").replace("’", "")).strip("-")

def strip_interwiki(s):
    return "\n".join(l for l in s.split("\n") if not re.match(r"^\s*\[\[(?:[a-z]{2}(?:-[a-z]+)?):", l) and not re.match(r"^\s*\[\[Category:", l))

def text_block(raw):
    """Wikitext section -> list of paragraphs / bullet items (plain text)."""
    raw = strip_interwiki(raw)
    raw = re.sub(r"\{\|.*?\|\}", "", raw, flags=re.S)  # drop tables
    raw = re.sub(r"<gallery.*?</gallery>", "", raw, flags=re.S | re.I)
    out = []
    for line in raw.split("\n"):
        c = clean(re.sub(r"^\s*[#*:]+\s*", "", line))
        if c and not c.startswith(("{|", "|", "!")):
            out.append(c)
    return out

ABILITIES = ["Double Jump", "Glide", "Zipline", "Bounce", "Dash", "Light Burst"]
def needs(raw):
    found = []
    for a in ABILITIES:
        if re.search(r"Abilities#" + a + r"\b", raw) or re.search(r"\bneed[s]?\b[^.\n]*\b" + a + r"\b", raw, re.I):
            found.append(a)
    for k in re.findall(r"\[\[(Key for [^\]|]+)", raw):
        found.append(k)
    return list(dict.fromkeys(found))

# ── Islands ──────────────────────────────────────────────────────────────────
REGION_FIX = {"Industrial": "Industrial District", "Greymist": "Crow's End", "Hummingberg": "Hummingberg",
              "Furogawa": "Furogawa", "Oxbury": "Oxbury", "Crow's End": "Crow's End"}
islands = []
images = set()
for t in IDX["Islands"]:
    if t == "Bus Stops":
        continue
    txt = page(t); f, end = find_template(txt, "Island")
    secs = sections(txt[end:])
    region = REGION_FIX.get(clean(f.get("region", "")), clean(f.get("region", ""))) or ("Everdoor" if t == "Everdoor" else "")
    chests = []
    for k in secs:
        if k.lower().startswith("chest"):
            for it in listitems(secs[k]):
                if it["depth"] == 1:
                    chests.append({"text": re.sub(r"^\d+\.\s*", "", it["text"]), "needs": needs(it["raw"])})
    def items(field):
        raw = f.get(field, "")
        parts = [clean(x) for x in re.split(r"\n\s*\*|<br\s*/?>|^\s*\*", raw)]
        return [p for p in (x.strip(" *") for x in parts) if p and p.lower() != "none"]
    extra = []
    for k, v in secs.items():
        if k == "_intro" or k.lower().startswith("chest") or k in ("Gallery", "Sources"):
            continue
        body = text_block(v)
        if body:
            extra.append({"heading": k, "lines": body})
    intro = [l for l in text_block(secs.get("_intro", "")) if "is an island found in" not in l and "is a location found in" not in l]
    img = html.unescape(f.get("image", "").strip())
    if img and not img.startswith("http"):
        images.add(img)
    spirits = [s.replace(" (unlisted)", "").strip() for s in re.split(r"\n|<br\s*/?>", clean(f.get("shipspirit", ""))) if s.strip()]
    islands.append({
        "id": slug(t), "name": t, "region": region,
        "x": (coords(f.get("coordinates")) or [0, 0])[0], "y": (coords(f.get("coordinates")) or [0, 0])[1],
        "bus": coords(f.get("busstop")),
        "requirements": [r for r in [clean(x) for x in re.split(r"<br\s*/?>|,|\n", f.get("requirements", ""))] if r and r.lower() != "none"],
        "spirits": spirits,
        "resources": items("resources"), "shop": items("shop"), "other": items("other"),
        "intro": intro, "chests": chests, "sections": extra,
        "image": img if img and not img.startswith("http") else "",
    })

# Boat-upgrade access requirements stated on the Abilities page / island pages
ACCESS = {"nordweiler": "Icebreaker", "oxbury": "Rock Destroyer", "greymist-peaks": "Mist Cleaner 1000",
          "overbrook": "Mist Cleaner 1000"}
for i in islands:
    if i["id"] in ACCESS and ACCESS[i["id"]] not in i["requirements"]:
        i["requirements"].append(ACCESS[i["id"]])
island_names = {i["name"]: i["id"] for i in islands}

# ── Place matching (for quest waypoints) ─────────────────────────────────────
ALIASES = {
    "Alt Harbour": "alt-harbor", "Overbrook Hospital": "overbrook", "Crow's End": "crows-end-inc",
    "Crow’s End": "crows-end-inc", "Albert’s Shipyard": "alberts-shipyard", "Albert's Shipyard": "alberts-shipyard",
    "Bottom Line Corp": "bottom-line-corp", "Bottom Line": "bottom-line-corp", "Toroyama": "mount-toroyama",
    "Old Central District": "old-central-district", "Kaltstein": "kaltstein-mines", "Hikarishima": "hikarishima-lighthouse",
    "Susan’s Museum": "susans-museum", "the Everdoor": "everdoor", "Greymist": "greymist-peaks",
    "Iwashima": "iwashima-countryside", "Resuteno": "resuteno-meadows", "Gurenu": "gurenu-fields",
    "Barkensheim": "barkensheim-creek", "Mosstein": "mosstein-cove", "Greenhalten": "greenhalten-bay",
    "Nordsee": "nordsee-pier", "Hoseki": "hoseki-quarry", "Flotsam": "flotsam-shores", "Sunspring": "sunspring-square",
    "Ambertown": "ambertown-park", "Edgeborough": "edgeborough-lane", "Southpoint": "southpoint-docks",
}
names = {**{n: i for n, i in island_names.items()}, **ALIASES}
name_re = re.compile(r"(?<![\w'])(" + "|".join(sorted(map(re.escape, names), key=len, reverse=True)) +
                     r")(?!\s+(?:Region|Preservation|Map|Brochure))(?![\w])", re.I)
lower_names = {k.lower(): v for k, v in names.items()}
coord_re = re.compile(r"\[?\s*(-?\d{1,3})\s*,\s*(-?\d{1,3})\s*\]?")

def places(raw):
    """Ordered island ids + raw coordinate points mentioned in a wikitext fragment."""
    txt = clean(raw)
    found = []
    for m in name_re.finditer(txt):
        found.append(("island", lower_names[m.group(1).lower()], m.start()))
    for m in coord_re.finditer(txt):
        x, y = int(m.group(1)), int(m.group(2))
        if abs(x) <= 260 and abs(y) <= 260 and (abs(x) > 3 or abs(y) > 3):
            # snap to an island if within 6 units, otherwise a free point
            near = min(islands, key=lambda i: (i["x"] - x) ** 2 + (i["y"] - y) ** 2)
            if (near["x"] - x) ** 2 + (near["y"] - y) ** 2 <= 36:
                found.append(("island", near["id"], m.start()))
            else:
                found.append(("point", [x, y], m.start()))
    found.sort(key=lambda t: t[2])
    return [(k, v) for k, v, _ in found]

# ── Spirits ──────────────────────────────────────────────────────────────────
spirits = []
for t in IDX["Spirit Characters"]:
    txt = page(t); f, end = find_template(txt, "Character")
    secs = sections(txt[end:])
    origin_raw = clean(f.get("origin", ""))
    origin = next((iid for n, iid in sorted(names.items(), key=lambda kv: -len(kv[0])) if n.lower() in origin_raw.lower()), None)
    img = html.unescape(f.get("image", "").strip())
    if img: images.add(img)
    def sec(*keys):
        for k in keys:
            if k in secs and text_block(secs[k]): return text_block(secs[k])
        return []
    spirits.append({
        "id": slug(t), "name": t, "species": clean(f.get("species", "")), "origin": origin, "originText": origin_raw,
        "house": clean(f.get("house", "")), "event": clean(f.get("minigame", "")).replace("\n", ", "),
        "favouriteFood": clean(f.get("favouritefood", "")), "likes": clean(f.get("likes", "")).replace("\n", ", "),
        "dislikes": clean(f.get("dislikes", "")).replace("\n", ", "), "skills": clean(f.get("skills", "")).replace("\n", ", "),
        "flower": clean(f.get("flower", "")),
        "firstQuest": clean(f.get("firstquest", "")), "lastQuest": clean(f.get("lastquest", "")),
        "about": sec("Description", "About", "_intro")[:3],
        "life": sec("Life"),
        "everdoor": sec("At The Everdoor", "At the Everdoor", "Goodbye"),
        "image": img, "dlc": t in ("Lily", "Beverly", "Jackie", "Daria"),  # free 2021 updates
    })
spirit_ids = {s["name"]: s["id"] for s in spirits}
# Giovanni & Daria first/last quests aren't in their infobox; filled from chains below.

# ── Quests ───────────────────────────────────────────────────────────────────
REPORT_RE = re.compile(r"\b(report back|return to|go back|talk to .* again|bring (?:it|them|.*) back|come back)\b", re.I)
quests = []
for t in IDX["Quests"]:
    txt = page(t); f, end = find_template(txt, "Quest")
    if not f:
        continue
    secs = sections(txt[end:])
    obj_raw = next((v for k, v in secs.items() if k.lower().startswith("objective")), "")
    notes_raw = "\n".join(v for k, v in secs.items() if k.lower().startswith(("note", "walkthrough", "tips", "guide")))
    objectives = []
    for it in listitems(obj_raw) or [{"depth": 1, "raw": l, "text": clean(l)} for l in obj_raw.split("\n") if clean(l)]:
        objectives.append({"text": it["text"], "depth": it["depth"], "places": places(it["raw"])})
    giver_raw = f.get("giver", "")
    giver_links = links(giver_raw)
    giver_spirit = next((spirit_ids[l] for l in giver_links if l in spirit_ids), None)
    if not giver_spirit and clean(giver_raw) in spirit_ids:
        giver_spirit = spirit_ids[clean(giver_raw)]
    loc_places = places(f.get("location", ""))
    boat = "Stella's Boat" in f.get("location", "")

    # Waypoints: start = location field (if an island), then objective mentions in order.
    wps = []
    def add(kind, val, step, why):
        key = (kind, json.dumps(val))
        if wps and (wps[-1]["kind"], json.dumps(wps[-1]["ref"])) == key:
            return
        wps.append({"kind": kind, "ref": val, "step": step, "why": why})
    for kind, val in loc_places:
        add(kind, val, 0, "Quest location")
    for n, o in enumerate(objectives, 1):
        for kind, val in o["places"]:
            add(kind, val, n, o["text"])
        if not o["places"] and REPORT_RE.search(o["text"]) and wps:
            add(wps[0]["kind"], wps[0]["ref"], n, o["text"])
    if not wps:
        for kind, val in places(f.get("description", "")) + places(f.get("prereq", "")):
            add(kind, val, 0, "Mentioned in quest description")
    for i, w in enumerate(wps):
        w["role"] = "start" if i == 0 else ("end" if i == len(wps) - 1 else "mid")
    if len(wps) == 1:
        wps[0]["role"] = "single"

    qtype = clean(f.get("type", "")) or "Requests"
    rewards = [r for r in (clean(x) for x in re.split(r"<br\s*/?>|\n", f.get("rewards", ""))) if r]
    prev_l, next_l = links(f.get("prev", "")), links(f.get("next", ""))
    img = html.unescape(f.get("image", "").strip())
    quests.append({
        "id": slug(t), "title": t.replace(" (Quest)", ""), "number": clean(f.get("number", "")), "type": qtype,
        "giver": clean(giver_raw), "spirit": giver_spirit,
        "description": clean(f.get("description", "")), "prereq": clean(f.get("prereq", "")),
        "location": clean(f.get("location", "")), "onBoat": boat,
        "rewards": rewards, "repeatable": bool(f.get("repeatable", "").strip()) and f.get("repeatable", "").strip().lower() not in ("no", "none"),
        "prev": [slug(x) for x in prev_l], "next": [slug(x) for x in next_l],
        "objectives": [{"text": o["text"], "depth": o["depth"]} for o in objectives],
        "notes": text_block(notes_raw),
        "waypoints": wps, "image": img,
    })
qids = {q["id"] for q in quests}
for q in quests:
    q["prev"] = [p for p in q["prev"] if p in qids]
    q["next"] = [n for n in q["next"] if n in qids]

# Spirit storylines: walk prev/next chains from each spirit's quests.
by_id = {q["id"]: q for q in quests}
for s in spirits:
    own = [q for q in quests if q["spirit"] == s["id"]]
    first = by_id.get(slug(s["firstQuest"])) if s["firstQuest"] else None
    if not first and own:
        roots = [q for q in own if not any(p in by_id and by_id[p]["spirit"] == s["id"] for p in q["prev"])]
        first = roots[0] if roots else own[0]
    order, seen, cur = [], set(), first
    while cur and cur["id"] not in seen:
        seen.add(cur["id"]); order.append(cur["id"])
        cur = next((by_id[n] for n in cur["next"] if n in by_id), None)
    order += [q["id"] for q in own if q["id"] not in seen]
    s["quests"] = order
    if not s["firstQuest"] and order: s["firstQuest"] = by_id[order[0]]["title"]
    if not s["lastQuest"] and order: s["lastQuest"] = by_id[order[-1]]["title"]

# Spoilers: each spirit's final quest(s), Lily/Stella endgame, anything mentioning the Everdoor farewell.
spoil_last = {slug(s["lastQuest"]) for s in spirits if s["lastQuest"]}
for q in quests:
    blob = " ".join([q["description"]] + [o["text"] for o in q["objectives"]])
    q["spoiler"] = (q["id"] in spoil_last or q["spirit"] == "lily" or q["giver"] == "Stella"
                    or bool(re.search(r"Everdoor", blob)))
for i in islands:
    i["spoiler"] = i["region"] == "Crow's End" or i["id"] in ("everdoor",)

# ── Events ───────────────────────────────────────────────────────────────────
def to_game(px, py):  # 1600px-wide community map -> game coordinates
    return [round((px - 660) / 2.9), round((705 - py) / 2.85)]
REGIONAL = {
    "Thunderstorm": [to_game(*p) for p in [(545, 462), (735, 400), (572, 690), (740, 668), (1025, 592), (1148, 592), (910, 845), (1170, 1130), (1460, 945)]],
    "Meteor Shower": [to_game(*p) for p in [(1310, 670), (1150, 860), (1300, 1040)]],
}
events = []
for t in IDX["Events"]:
    if t in ("Events", "Jacob"):
        continue
    txt = page(t); f, end = find_template(txt, "Event")
    secs = sections(txt[end:])
    raw = f.get("coordinates", "")
    pts, approx, at_island = [], False, None
    for line in re.split(r"<br\s*/?>|\n", raw):
        c = coords(line)
        if c:
            label = clean(re.sub(r"-?\d+\s*,\s*-?\d+", "", line)).strip()
            pts.append({"x": c[0], "y": c[1], "label": label})
    if not pts and t in REGIONAL:
        pts = [{"x": x, "y": y, "label": ""} for x, y in REGIONAL[t]]; approx = True
    if not pts:
        for l in links(raw):
            if l in island_names:
                at_island = island_names[l]
                i = next(i for i in islands if i["id"] == at_island)
                pts = [{"x": i["x"], "y": i["y"], "label": l}]
    spirit = next((spirit_ids[l] for l in links(f.get("spirit", "")) if l in spirit_ids), None)
    details = text_block(secs.get("Details", "") or secs.get("_intro", ""))
    details = [d for d in details if " is an event found in" not in d and d != "TBA"]
    house = clean(f.get("house", ""))
    manual = t in ("Dust Shades", "Shadow Steel Orcs")
    events.append({
        "id": slug(t), "name": clean(f.get("title", "")) or t, "spirit": spirit,
        "resource": clean(f.get("resource", "")).replace("\n", ", "), "duration": clean(f.get("duration", "")),
        "requires": clean(f.get("requires", "")), "house": house,
        "trigger": "manual" if manual else ("island" if at_island else "sea"),
        "island": at_island, "points": pts, "approx": approx, "regionText": "" if pts and not approx else clean(raw).replace("\n", ", "),
        "details": details, "image": html.unescape(f.get("image", "").strip()),
    })
    res = clean(f.get("resource", "")).split("\n")[0].split(" x")[0].strip()
    events[-1]["fallbackImage"] = res + ".png" if res and res[0].isupper() and "Whatever" not in res else ""
    if events[-1]["fallbackImage"]: images.add(events[-1]["fallbackImage"])
    if events[-1]["image"]: images.add(events[-1]["image"])
# Manually triggered events happen aboard the boat: explain the trigger.
for e in events:
    if e["id"] == "dust-shades":
        e["details"] = e["details"] or ["Interact with Jacob, Stanley's pet beetle, in the aquarium inside Stanley's Playroom to start the event. Collect Bottled Ectoplasm from the dust shades."]
    if e["id"] == "shadow-steel-orcs":
        e["details"] = e["details"] or ["Interact with the tabletop RPG in Buck's Lair of Wonders to start the event and earn XP Potions."]

# ── Images: resolve wiki filenames to CDN URLs ───────────────────────────────
for q in quests:
    if q["image"]: images.add(q["image"])
for i in islands:
    if i["image"]: images.add(i["image"])
urls = {}
names_list = sorted(images)
for k in range(0, len(names_list), 50):
    batch = names_list[k:k + 50]
    qs = urllib.parse.urlencode({"action": "query", "titles": "|".join("File:" + n for n in batch), "prop": "imageinfo",
                                 "iiprop": "url", "format": "json"})
    r = json.load(urllib.request.urlopen(urllib.request.Request("https://spiritfarer.fandom.com/api.php?" + qs,
                                                                headers={"User-Agent": "SpiritfarerMapFanTool/0.1"})))
    norm = {n["to"]: n["from"] for n in r["query"].get("normalized", [])}
    for p in r["query"]["pages"].values():
        if "imageinfo" in p:
            u = p["imageinfo"][0]["url"].split("?")[0]
            urls[norm.get(p["title"], p["title"])[5:]] = u.replace("https://static.wikia.nocookie.net/spiritfarer/images/", "")
for coll in (islands, spirits, events, quests):
    for o in coll:
        o["image"] = urls.get(o.get("image", ""), "") or urls.get(o.pop("fallbackImage", "") or "", "")
        o.pop("fallbackImage", None)

# ── Shrines / abilities (Abilities page) ─────────────────────────────────────
abilities = []
asecs = sections(page("Abilities"))
for k, v in asecs.items():
    if k == "_intro": continue
    body = text_block(v)
    unlock = next((l[len("Unlock at:"):].strip() for l in body if l.startswith("Unlock at:")), "")
    where = next((iid for n, iid in sorted(names.items(), key=lambda kv: -len(kv[0])) if n.lower() in unlock.lower()), None)
    desc = [l for l in body if not l.startswith(("Unlock at:", "Description:", "Nota:"))]
    how = next((l[len("Description:"):].strip() for l in body if l.startswith("Description:")), "")
    abilities.append({"name": k.split("/")[0].strip(), "island": where, "unlock": unlock, "controls": how, "details": desc[:3]})

# ── Treasure map coordinates ─────────────────────────────────────────────────
treasures = []
tm = page("Treasure Maps and Co-ordinates")
for row in re.split(r"\n\|-\n", tm)[1:]:
    cells = [c.strip() for c in re.split(r"\n\|\s*\n?", "\n" + row) if c.strip()]
    if len(cells) >= 3 and coords(cells[1]):
        x, y = coords(cells[1])
        treasures.append({"x": x, "y": y, "source": clean(cells[0]), "reward": clean(cells[2].split("|}")[0])})

# ── Bus stops (deduped from island infoboxes) ────────────────────────────────
bus = {}
for i in islands:
    if i["bus"]:
        bus.setdefault(tuple(i["bus"]), []).append(i["id"])
bus_stops = [{"x": k[0], "y": k[1], "near": v} for k, v in bus.items()]

data = {
    "source": "Spiritfarer Fandom Wiki (spiritfarer.fandom.com), CC-BY-SA",
    "imageBase": "https://static.wikia.nocookie.net/spiritfarer/images/",
    "worldMap": {"url": "e/ed/MAP-OF-LOCATIONS.jpg/revision/latest",
                 "bounds": {"x0": round(-660 / 2.9, 2), "x1": round(940 / 2.9, 2), "yTop": round(705 / 2.85, 2), "yBottom": round((705 - 1201.9) / 2.85, 2)}},
    "regions": ["Everdoor", "Hummingberg", "Furogawa", "Industrial District", "Oxbury", "Crow's End"],
    "islands": islands, "spirits": spirits, "abilities": abilities, "treasures": treasures, "busStops": bus_stops, "events": events, "quests": quests,
}
json.dump(data, open(OUT, "w"), indent=1, ensure_ascii=False)
print(f"islands={len(islands)} spirits={len(spirits)} events={len(events)} quests={len(quests)} images={len(urls)}/{len(images)}")
print("quests with map pins:", sum(1 for q in quests if q["waypoints"]), "boat-only:", sum(1 for q in quests if not q["waypoints"]))
