import re, html
def find_template(text, name):
    """Return (fields dict, end index) for first {{name ...}} with nested-brace awareness."""
    m = re.search(r"\{\{\s*"+re.escape(name)+r"\s*[\n|}]", text)
    if not m: return {}, 0
    i = m.start(); depth = 0; j = i
    while j < len(text):
        if text.startswith("{{", j): depth += 1; j += 2; continue
        if text.startswith("}}", j):
            depth -= 1; j += 2
            if depth == 0: break
            continue
        j += 1
    body = text[m.end()-1:j-2] if text[m.end()-1] in "|\n" else ""
    # split on top-level pipes
    parts, depth, cur, k = [], 0, "", 0
    while k < len(body):
        two = body[k:k+2]
        if two in ("{{","[["): depth += 1; cur += two; k += 2; continue
        if two in ("}}","]]"): depth -= 1; cur += two; k += 2; continue
        if body[k] == "|" and depth == 0: parts.append(cur); cur = ""; k += 1; continue
        cur += body[k]; k += 1
    parts.append(cur)
    fields = {}
    for p in parts:
        if "=" in p:
            key, val = p.split("=", 1)
            fields[re.sub(r"\s+", "", key.strip().lower())] = val.strip()
    return fields, j

def clean(s):
    """Strip wiki markup to plain text."""
    if not s: return ""
    s = re.sub(r"<ref[^>]*/>|<ref[^>]*>.*?</ref>", "", s, flags=re.S)
    s = re.sub(r"\{\{\s*itemlink\s*\|\s*([^|}]+)\|\s*(\d+)\s*\}\}", r"\1 x\2", s, flags=re.I)
    s = re.sub(r"\{\{\s*(?:Boldorange|itemlink|bold\w*|color\|[^|]*)\s*\|\s*([^|}]+)[^}]*\}\}", r"\1", s, flags=re.I)
    s = re.sub(r"\{\{[^{}]*\}\}", "", s)
    s = re.sub(r"\[\[(?:File|Image):[^\]]*\]\]", "", s, flags=re.I)
    s = re.sub(r"\[\[:?Category:[^|\]]*\|([^\]]*)\]\]", r"\1", s)
    s = re.sub(r"\[\[[^|\]]*\|([^\]]*)\]\]", r"\1", s)
    s = re.sub(r"\[\[([^\]]*)\]\]", r"\1", s)
    s = re.sub(r"\[https?://\S+ ([^\]]+)\]", r"\1", s)
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"'''?", "", s)
    s = html.unescape(s.replace("&nbsp;", " "))
    return re.sub(r"[ \t]+", " ", s).strip()

def links(s):
    return [m.split("|")[0].split("#")[0].strip() for m in re.findall(r"\[\[([^\]]+)\]\]", s or "") if not m.lower().startswith(("file:","category:","image:"))]

def bolds(s):
    return [b.strip() for b in re.findall(r"\{\{\s*Boldorange\s*\|\s*([^|}]+)", s or "", flags=re.I)]

def sections(text):
    """Split body into {heading: content}."""
    out = {"_intro": ""}; cur = "_intro"
    for line in text.split("\n"):
        m = re.match(r"^(=+)\s*(.*?)\s*\1\s*$", line)
        if m: cur = clean(m.group(2)); out.setdefault(cur, ""); continue
        out[cur] += line + "\n"
    return out

def listitems(s):
    items = []
    for line in (s or "").split("\n"):
        m = re.match(r"^\s*([#*:]+)\s*(.*)", line)
        if m and clean(m.group(2)): items.append({"depth": len(m.group(1)), "raw": m.group(2), "text": clean(m.group(2))})
    return items

def coords(s):
    m = re.search(r"(-?\d+)\s*,\s*(-?\d+)", s or "")
    return [int(m.group(1)), int(m.group(2))] if m else None
