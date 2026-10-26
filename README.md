# ⛵ Spiritfarer — Everlight Atlas

An interactive, browser-based map and quest log for the game **Spiritfarer** by Thunder Lotus Games.
It plots every island at its real in-game coordinates, shows where each sea event triggers, lists what
you can find on each island, and turns the full quest list into a progress-tracking log with numbered
start → waypoint → finish pins on the map.

### 🌐 [Live Demo →](https://djsaintg.github.io/Spiritfarer-Interactive-Map/)

[![Deploy to GitHub Pages](https://github.com/djsaintg/Spiritfarer-Interactive-Map/actions/workflows/deploy.yml/badge.svg)](https://github.com/djsaintg/Spiritfarer-Interactive-Map/actions/workflows/deploy.yml)

---

## Features

### 🗺️ World map
- **All 38 locations** plotted at their in-game map coordinates, grouped into the six regions
  (Everdoor, Hummingberg, Furogawa, Industrial District, Oxbury, Crow's End)
- **Two backgrounds, one toggle:** a hand-drawn *sea chart* (works offline) or the community *world map* image from the Fandom wiki, with pins calibrated to it
- **Pan & zoom** (mouse wheel / drag / buttons, or **pinch, two-finger pan and double-tap** on touch screens), coordinate grid matching the in-game map
- **Layers:** islands, names, sea events, shrines, active quest pins, bus stops, treasure-map spots, grid
- **Hover tooltips** on every pin, **click/tap** to open details in the sidebar
- **Secret locations** (Lost Shrine, Hidden Shrine) stay hidden as `???` until you visit them or turn on spoilers

### 🏝️ Islands
- Region, coordinates, nearest bus stop and **boat-upgrade requirements** (Icebreaker, Rock Destroyer, Mist Cleaner 1000)
- **Spirits found there**, **shrine abilities** (Double Jump, Glide, Zipline, Bounce, Dash, Light Burst, Improved Tools)
- **Chest checklist** with the ability or key each chest needs
- Shop stock, resources, points of interest, and **every quest that starts, passes through, or ends there**
- Nearby **sea events**, plus **per-island notes**

### 📜 Quest log
- **183 quests**: every spirit's storyline in chain order, plus Shenanigans, Francis's Errands, and Lily/Stella's quests
- **Track progress:** not started / in progress / completed, with **per-objective checkboxes**
- **Route on the map:** each quest's start (green), waypoints (amber) and finish (red) as numbered pins joined by a dashed route
- Active quests stay pinned on the map while you play
- Description, unlock conditions, objectives, rewards, notes, and previous/next quest links
- Search by quest name **or place**, and filter by status or "has map pins"

### ✨ Events
- **Sea events** with exact trigger coordinates: Jellyfish (4 stages), Dragons (Quartz, Aluminium, Silver, Gold), Tortoise Sisters, Fireflies, Nebula Pillbugs, Pulsar Rays / Deadly Pulsar Rays, Severe Thunderstorm
- **Region-wide events** (Thunderstorm, Meteor Shower) shown as approximate areas taken from the community map
- **Island events** (Overbrook's Mind Palace and Vending Machine) and **boat events** (Dust Shades, Shadow Steel Orcs)
- Which spirit must be aboard, the reward, required boat upgrades, and how each event plays

### 🦌 Spirits
- All 15 spirits (including the free-update spirits **Lily, Beverly, Jackie & Daria**; Daffodil the cat has no storyline) with portrait, where to find them, house, event, favourite food, likes and dislikes
- Each storyline's progress, framed on the map
- Life stories and Everdoor farewells sit behind spoiler blur

### 🙈 Spoiler protection
Farewell quests, endings, life stories and secret locations are **blurred until clicked**. A global **Spoilers** toggle in the header reveals everything.

### 💾 Progress
- Saved automatically in your browser (localStorage)
- **Export / Copy / Import** as JSON to back up or move between machines
- Overview of quests, islands visited, chests opened and storylines finished
- Deep links: `#island/hummingberg`, `#quest/the-silver-company`, `#event/turtle-sisters`, `#spirit/atul`

---

## Running the App

### 📱 Phone or tablet (install as an app)
Open the [live demo](https://djsaintg.github.io/Spiritfarer-Interactive-Map/) and add it to your home screen:
- **Android (Chrome / Edge):** tap the **Install** button in the header, or ⋮ menu → *Install app*
- **iPhone / iPad (Safari):** Share button → *Add to Home Screen*

It opens full-screen like a native app and keeps working offline: the app itself is cached, and wiki artwork is cached as you browse it.
Progress is saved on the device; use **Progress → Export** to move it between phone and desktop.

### Linux (recommended)
A self-contained shell script handles everything: installing Node.js, building, and launching.

```bash
chmod +x spiritfarer_map.sh
./spiritfarer_map.sh
```

The script will:
1. Install Node.js via `nvm` if not already present
2. Write all project source files to `~/spiritfarer-map`
3. Build a single self-contained `dist/index.html`
4. Open it in a standalone window (Chromium `--app` mode, GTK WebKit2, or Firefox as fallbacks)

### Manual build (any platform with Node.js ≥ 18)
```bash
npm install
npm run build
# Then open dist/index.html in any browser
```

For development with hot reload: `npm run dev`.

### Regenerating the launcher
After changing any source file, rebuild the `.sh` launcher so it embeds the latest code:
```bash
python3 generate_sh.py
```

### Refreshing game data from the wiki
```bash
./tools/update_data.sh   # downloads wiki pages → rebuilds src/data/spiritfarer.json
npm run build
python3 generate_sh.py
```
`tools/build_data.py` parses the wiki's infobox templates (`{{Island}}`, `{{Quest}}`, `{{Event}}`, `{{Character}}`)
and derives each quest's map route from the location field and the places named in its objectives.

---

## Tech Stack

| Technology | Version | License |
|---|---|---|
| [React](https://react.dev) | 19.2.6 | MIT |
| [Vite](https://vitejs.dev) | 7.3.2 | MIT |
| [Tailwind CSS](https://tailwindcss.com) | 4.1.17 | MIT |
| [vite-plugin-singlefile](https://github.com/richardtallent/vite-plugin-singlefile) | 2.3.0 | MIT |
| [lucide-react](https://lucide.dev) | 1.x | ISC |
| [clsx](https://github.com/lukeed/clsx) | 2.1.1 | MIT |
| [tailwind-merge](https://github.com/dcastil/tailwind-merge) | 3.4.0 | MIT |

The map is plain SVG with a custom pan/zoom and pinch-zoom; no mapping library needed.
A web app manifest and a small service worker (`public/`) make the GitHub Pages build installable and usable offline.

---

## Data Sources & Credits

### Game
**Spiritfarer** is developed and published by **Thunder Lotus Games**.
- Website: [thunderlotusgames.com/spiritfarer](https://thunderlotusgames.com/spiritfarer/)
- Steam: [store.steampowered.com/app/972660](https://store.steampowered.com/app/972660/Spiritfarer_Farewell_Edition/)

All game content, characters, location names, lore and artwork are the intellectual property of
**Thunder Lotus Games**. This project is an unofficial fan tool and is **not affiliated with, endorsed by,
or produced by Thunder Lotus Games.**

### Wiki data
Island, quest, event, spirit, shrine and treasure-map data were compiled from the
**[Spiritfarer Fandom Wiki](https://spiritfarer.fandom.com)** via the public MediaWiki API.
Wiki text content is licensed under **[CC-BY-SA](https://creativecommons.org/licenses/by-sa/3.0/)**.

### Images
Spirit portraits, island artwork and the community world map (`MAP-OF-LOCATIONS.jpg`) are fetched
**at runtime** from the Fandom wiki CDN and are not bundled with this project. The game artwork in them remains the
property of Thunder Lotus Games.

---

## Disclaimer

This is an **unofficial fan-made reference tool** created for personal and community use.

- No game assets, audio, or executable code from *Spiritfarer* are included or redistributed
- Images are fetched at runtime from the Fandom wiki CDN and are not bundled with this project
- This project is **non-commercial** and **not for sale**
- All trademarks, game content, and intellectual property relating to *Spiritfarer* remain the property of **Thunder Lotus Games**

If Thunder Lotus Games has any concerns about this project, please open an issue or contact the repository owner directly and it will be addressed promptly.

---

## License

The source code of this tool (React components, data tooling, shell script) is released under the **MIT License**.

```
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

> **Note:** The MIT license applies to the tool's source code only.
> It does **not** grant any rights to game assets, artwork, lore, or any other content
> owned by Thunder Lotus Games. Data derived from the Fandom wiki remains under CC-BY-SA.
