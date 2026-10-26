# 🗺️ Roadmap

A living document of planned features, ideas, and improvements for the Spiritfarer Everlight Atlas.
Community suggestions are welcome: open an issue or pull request on GitHub!

---

## 📌 Versioning Scheme

This project follows **[Semantic Versioning](https://semver.org)**: `MAJOR.MINOR.PATCH`

| Part | When it increases | Example |
|---|---|---|
| **MAJOR** | Large reworks or breaking changes to how the app is used | `1.0.0` → `2.0.0` |
| **MINOR** | New features added, fully backwards compatible | `1.0.0` → `1.1.0` |
| **PATCH** | Bug fixes, data corrections, typo fixes, no new features | `1.0.0` → `1.0.1` |

**Current release: `v1.1.0`**

---

## ✅ v1.0.0: Initial release

- [x] 38 locations at in-game coordinates across 6 regions
- [x] Toggleable background: drawn sea chart (offline) or calibrated wiki world map
- [x] Pan / zoom, coordinate grid, hover tooltips, click-to-select
- [x] Island details: requirements, spirits, shrine ability, shop, resources, chests (with ability/key needs), extra notes
- [x] Chest checklist, visited flag and personal notes per island
- [x] 20 events with trigger coordinates, spirit, reward and requirements (approximate zones for region-wide events)
- [x] Bus stops, treasure-map coordinates and shrines as map layers
- [x] Quest log with 183 quests: spirit storylines in chain order, Shenanigans, Errands, Lily/Stella
- [x] Quest routes on the map: numbered start / waypoint / finish pins with a dashed path
- [x] Quest status tracking with per-objective checkboxes; active quests stay pinned
- [x] Spirit profiles incl. free-update spirits (Lily, Beverly, Jackie, Daria), storyline progress
- [x] Spoiler blur with click-to-reveal and a global toggle
- [x] Progress export / copy / import as JSON
- [x] Deep links (`#quest/…`, `#island/…`, `#event/…`, `#spirit/…`)
- [x] Wiki data pipeline (`tools/update_data.sh`) and self-contained Linux launcher

---

## ✅ v1.1.0: Mobile

- [x] Installable web app (Android "Install", iOS "Add to Home Screen") with app icon and full-screen standalone mode
- [x] Offline support via a service worker: app cached, wiki artwork and fonts cached as you browse
- [x] Multi-touch map: pinch to zoom, two-finger pan, double-tap to zoom in
- [x] Phone layout: dynamic viewport height, notch / safe-area padding, adjustable map/panel split, larger tap targets
- [x] No accidental page zoom when typing in search boxes on iOS

---

## 🔜 Ideas for v1.2.0

- [ ] Hand-verified routes for quests where the wiki's objectives don't name the island
- [ ] Per-island chest positions (pins inside an island view)
- [ ] Francis shop, Susan's Museum and Albert locations as their own layer
- [ ] Boat-upgrade filter: show only islands reachable with your current upgrades
- [ ] Fishing spots and fish per region
- [ ] Recipe / ingredient lookup tied to islands that sell or yield them
- [ ] "What should I do next?" suggestions based on active quests and nearby islands
- [ ] Route planner: order active quests' waypoints into a short sailing path, using bus stops

---

## 🐛 Known limitations

- About 90 quests have no island pins because they happen on Stella's boat or anywhere (building, cooking, hugging, errands)
- Thunderstorm and Meteor Shower positions are approximate, taken from the community map rather than exact coordinates
- Quest routes are derived from the island names in the wiki's objective text, so a quest whose wiki page doesn't name a place won't show it
- Some wiki images don't exist, so a few islands and events show no artwork
