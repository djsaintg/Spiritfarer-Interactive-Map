# 🚀 Getting Started

This guide covers running the Spiritfarer Everlight Atlas on your computer or phone, what works with and
without an internet connection, and how to use the map and quest log.

---

## Requirements

| Requirement | Details |
|---|---|
| Operating System | Any modern Linux distro (or any OS with Node.js for the manual build). Phones and tablets: any modern browser, see below |
| Node.js | ≥ 18. **Installed automatically** by the script if missing |
| Internet | Required on first run (downloads Node.js + npm packages). Optional after that. |
| Disk space | ~250 MB (Node.js + node_modules + build output) |

---

## First Run

```bash
chmod +x spiritfarer_map.sh   # once
./spiritfarer_map.sh
```

```
📁  Project directory: /home/YourName/spiritfarer-map
✅  Node v24.x.x  /  npm 11.x.x
📝  Writing project files...
📦  Installing project dependencies...
🔨  Building...
🖥️   Launching standalone GUI window...
✅  Done!
```

The **first run** takes 2–5 minutes; **later runs** take 15–30 seconds.

A standalone window opens in Chromium `--app` mode, a GTK WebKit2 window, or Firefox, depending on what's installed.
You can also open `~/spiritfarer-map/dist/index.html` directly in any browser at any time.

---

## Phones & Tablets

No download or build needed: open the [live demo](https://djsaintg.github.io/Spiritfarer-Interactive-Map/) and install it.

| Device | How to install |
|---|---|
| Android (Chrome, Edge, Samsung Internet) | Tap **Install** in the header, or browser menu → *Install app* / *Add to Home screen* |
| iPhone / iPad (Safari) | Share button → *Add to Home Screen* |

The installed app opens full-screen with its own icon and works offline once it has been opened online.
Use **Bigger map / Smaller map** (between the map and the panel) to change how much of the screen the map takes up.

---

## Internet Connection: What Works Where

| Feature | Online | Offline |
|---|---|---|
| Sea chart map, islands, events, pins | ✅ | ✅ |
| Quest log, objectives, progress tracking | ✅ | ✅ |
| Island details, chests, shops, shrines | ✅ | ✅ |
| Export / import progress | ✅ | ✅ |
| **Wiki world-map background** | ✅ | ❌ (falls back to the sea chart) ¹ |
| **Spirit portraits & island artwork** | ✅ | ❌ (hidden) ¹ |
| Display fonts (Fraunces, Caveat) | ✅ | ❌ (system fonts used) ¹ |

¹ In the installed phone/web app, anything you've already viewed online is cached and keeps working offline.

---

## Using the Atlas

### Map
- **Scroll** to zoom around the cursor, **drag** to pan, or use the **+ / − / ⌖** buttons (bottom right)
- On touch screens: **pinch** to zoom, drag with one or two fingers to pan, **double-tap** to zoom in
- **Hover** any pin for a summary; **click** (or tap) to open its details in the sidebar
- **Sea chart / Wiki map** (top bar) switches the background. Both use the same coordinates as the in-game map.
- **Layers** (top bar) toggles islands, names, events, shrines, active quest pins, bus stops, treasure spots and the grid
- **Legend** (bottom left) explains region colours and pin shapes

### Tracking quests
1. Open **Quest Log** and expand a spirit's storyline (or search for a quest or a place name)
2. Click the circle next to a quest to cycle **Not started → In progress → Completed**
3. Open a quest to see its **route on the map**: numbered pins go from green (start) through amber (waypoints) to red (finish)
4. Tick **objectives** as you go. A quest marks itself in progress or complete as steps are checked.
5. Every **in-progress** quest keeps faint pins on the map (toggle with *Layers → Active quest pins*)

Quests with a ⛴ icon happen aboard Stella's boat (building, cooking, hugs...) or can be done anywhere, so they don't have island pins.

### Islands
Tick **"I've visited this island"** and check off chests as you open them. Islands where every quest is complete
are dimmed on the map (turn this off in *Layers → Dim finished islands*). Use **My notes** for anything else.

### Spoilers
Story-sensitive content is blurred: farewell quests, endings, life stories and secret islands.
Click any blurred text to reveal just that item, or use **Spoilers hidden/shown** in the top bar to toggle everything.

### Backing up progress
Go to **Progress → Export JSON** (or **Copy**). To restore, use **Import file** or paste the JSON.
Progress lives in the browser's localStorage, so **different browsers keep separate progress**.
The Chromium app window and Firefox, for example, don't share it, and neither do your phone and computer.
Export on one device and import on the other to carry progress across.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `nvm: command not found` after install | Close and reopen the terminal, then run the script again |
| Build fails | `cd ~/spiritfarer-map && npm run build` shows the full error |
| Window doesn't open | Open `~/spiritfarer-map/dist/index.html` in any browser |
| Wiki map says "couldn't load" | You're offline or the wiki CDN is unreachable; the sea chart is used instead |
| Flatpak Firefox shows a blank page | Flatpak can't read the folder: `flatpak override --user --filesystem=~/spiritfarer-map org.mozilla.firefox` |
| Progress disappeared | You may be in a different browser or private window; import your last export |
| `ld.so: libextest.so cannot be preloaded` | Harmless system message; ignore it |
| No **Install** button on Android | The browser already installed it, or doesn't support it; use the browser menu → *Add to Home screen* |
| Installed app shows an old version | Open it once while online, then close and reopen it to pick up the update |
