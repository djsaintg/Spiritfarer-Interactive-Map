#!/usr/bin/env bash

# ─── Spiritfarer — Everlight Atlas ───────────────────────────────────────────
# Interactive island map + quest log for Spiritfarer (unofficial fan tool).
# "ld.so: libextest.so cannot be preloaded" messages are a harmless system
# quirk and can safely be ignored.
# ─────────────────────────────────────────────────────────────────────────────

set -e

PROJECT_DIR="$HOME/spiritfarer-map"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo ""
echo "📁  Project directory: $PROJECT_DIR"
echo ""

# ── Load nvm ──────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
fi

# ── Install Node.js if missing ────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "⚠️   Node.js not found. Installing via nvm..."
  if command -v curl &>/dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  elif command -v wget &>/dev/null; then
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  else
    echo "❌  Neither curl nor wget found. Install Node.js from https://nodejs.org"
    exit 1
  fi
  \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
fi

echo "✅  Node $(node --version)  /  npm $(npm --version)"
echo ""
echo "📝  Writing project files..."

mkdir -p "public"
mkdir -p "src"
mkdir -p "src/components"
mkdir -p "src/data"
mkdir -p "src/utils"

cat > "package.json" << 'SPIRITFARER_EOF'
{
  "name": "spiritfarer-map",
  "private": true,
  "version": "1.1.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "clsx": "2.1.1",
    "lucide-react": "^1.27.0",
    "react": "19.2.6",
    "react-dom": "19.2.6",
    "tailwind-merge": "3.4.0"
  },
  "devDependencies": {
    "@tailwindcss/vite": "4.1.17",
    "@types/node": "22.19.17",
    "@types/react": "19.2.7",
    "@types/react-dom": "19.2.3",
    "@vitejs/plugin-react": "5.1.1",
    "tailwindcss": "4.1.17",
    "typescript": "5.9.3",
    "vite": "7.3.2",
    "vite-plugin-singlefile": "2.3.0"
  }
}
SPIRITFARER_EOF

cat > "tsconfig.json" << 'SPIRITFARER_EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "types": ["node", "vite/client"],

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Path mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    },

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src", "vite.config.ts"]
}
SPIRITFARER_EOF

cat > "index.html" << 'SPIRITFARER_EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <title>Spiritfarer — Everlight Atlas</title>
    <meta name="description" content="Unofficial interactive island map and quest log for Spiritfarer." />
    <!-- Fandom's image CDN answers hotlinks from other sites with a "No image" placeholder, so send no Referer. -->
    <meta name="referrer" content="no-referrer" />
    <meta name="theme-color" content="#132a3e" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="apple-mobile-web-app-title" content="Everlight Atlas" />
    <link rel="manifest" href="./manifest.webmanifest" />
    <link rel="icon" type="image/svg+xml" href="./icon.svg" />
    <link rel="apple-touch-icon" href="./apple-touch-icon.png" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Caveat:wght@500;600;700&family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Inter:wght@400;500;600&display=swap"
      rel="stylesheet"
    />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
SPIRITFARER_EOF

cat > "vite.config.ts" << 'SPIRITFARER_EOF'
import path from "path";
import { fileURLToPath } from "url";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import { viteSingleFile } from "vite-plugin-singlefile";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// https://vite.dev/config/
export default defineConfig({
  base: "./", // relative URLs so the build works on GitHub Pages' /<repo>/ path and from file://
  plugins: [react(), tailwindcss(), viteSingleFile()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
});
SPIRITFARER_EOF

cat > "src/App.tsx" << 'SPIRITFARER_EOF'
import { useCallback, useEffect, useRef, useState } from "react";
import { BookOpen, ChevronsDown, ChevronsUp, Compass, Download, Eye, EyeOff, Layers, Map as MapIcon, ScrollText, Sparkles, Users } from "lucide-react";
import { useProgress, useSettings, type Settings } from "@/store";
import type { Selection, Tab } from "@/types";
import { cn } from "@/utils/cn";
import { SpoilerContext } from "@/components/Spoiler";
import WorldMap from "@/components/WorldMap";
import IslandPanel from "@/components/IslandPanel";
import QuestLog from "@/components/QuestLog";
import EventsPanel from "@/components/EventsPanel";
import SpiritsPanel from "@/components/SpiritsPanel";
import ProgressPanel from "@/components/ProgressPanel";
import { Segmented } from "@/components/ui";

const TABS: { id: Tab; label: string; icon: typeof Compass }[] = [
  { id: "islands", label: "Islands", icon: Compass },
  { id: "quests", label: "Quest Log", icon: ScrollText },
  { id: "events", label: "Events", icon: Sparkles },
  { id: "spirits", label: "Spirits", icon: Users },
  { id: "progress", label: "Progress", icon: BookOpen },
];
const TAB_FOR: Record<NonNullable<Selection>["kind"], Tab> = { island: "islands", quest: "quests", event: "events", spirit: "spirits" };

const LAYER_LABELS: [keyof Settings["layers"], string][] = [
  ["islands", "Islands"], ["labels", "Island names"], ["events", "Sea events"], ["shrines", "Shrines"],
  ["activeQuests", "Active quest pins"], ["busStops", "Bus stops"], ["treasures", "Treasure map spots"], ["grid", "Coordinate grid"],
];

export default function App() {
  const api = useProgress();
  const [settings, setSettings] = useSettings();
  const [tab, setTab] = useState<Tab>("islands");
  const [selection, setSelection] = useState<Selection>(null);
  const [focusKey, setFocusKey] = useState(0);
  const [layersOpen, setLayersOpen] = useState(false);
  const [bigMap, setBigMap] = useState(false); // phones: map/panel split
  const install = useInstallPrompt();
  const sideRef = useRef<HTMLDivElement>(null);
  const layersRef = useRef<HTMLDivElement>(null);

  const select = useCallback((s: Selection, fly = false) => {
    setSelection(s);
    if (s) setTab(TAB_FOR[s.kind]);
    if (s && fly) setFocusKey(k => k + 1);
    sideRef.current?.scrollTo({ top: 0 });
  }, []);

  // Deep links: #island/<id>, #quest/<id>, #event/<id>, #spirit/<id>
  useEffect(() => {
    const fromHash = () => {
      const [kind, id] = decodeURIComponent(location.hash.slice(1)).split("/");
      if (kind in TAB_FOR && id) select({ kind, id } as NonNullable<Selection>, true);
      else if ((TABS as { id: string }[]).some(t => t.id === kind)) setTab(kind as Tab);
    };
    fromHash();
    window.addEventListener("hashchange", fromHash);
    return () => window.removeEventListener("hashchange", fromHash);
  }, [select]);
  useEffect(() => {
    const h = selection ? `#${selection.kind}/${selection.id}` : `#${tab}`;
    if (location.hash !== h) history.replaceState(null, "", h);
  }, [selection, tab]);

  useEffect(() => {
    const close = (e: PointerEvent) => { if (!layersRef.current?.contains(e.target as Node)) setLayersOpen(false); };
    document.addEventListener("pointerdown", close);
    return () => document.removeEventListener("pointerdown", close);
  }, []);

  const idFor = (k: NonNullable<Selection>["kind"]) => (selection?.kind === k ? selection.id : null);
  // Going "back" in a panel clears the selection but stays on that tab.
  const panelSelect = (s: Selection, fly?: boolean) => (s ? select(s, fly) : setSelection(null));

  return (
    <SpoilerContext.Provider value={settings.showSpoilers}>
      <div className="flex h-screen h-dvh flex-col bg-[#0b1622] pl-[env(safe-area-inset-left)] pr-[env(safe-area-inset-right)] text-slate-100">
        <header className="flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-white/10 bg-gradient-to-r from-[#132a3e] via-[#1a2f45] to-[#2a2440] px-3 pb-2.5 pt-[max(0.625rem,env(safe-area-inset-top))] sm:px-4">
          <div className="flex items-baseline gap-2">
            <h1 className="font-display text-xl font-semibold tracking-wide text-amber-100">Spiritfarer</h1>
            <span className="font-hand text-lg text-amber-200/70">Everlight Atlas</span>
          </div>
          <div className="ml-auto flex flex-wrap items-center gap-2">
            {install && (
              <button onClick={install} className="inline-flex items-center gap-1.5 rounded-md border border-amber-300/40 bg-amber-300/10 px-2.5 py-1 text-xs text-amber-100 hover:bg-amber-300/20"
                title="Install the Atlas as an app (works offline)">
                <Download size={14} /> Install
              </button>
            )}
            <Segmented value={settings.background} onChange={v => setSettings(s => ({ ...s, background: v }))}
              options={[{ value: "chart", label: "Sea chart" }, { value: "wiki", label: "Wiki map" }]} />
            <div className="relative" ref={layersRef}>
              <button onClick={() => setLayersOpen(o => !o)} className="inline-flex items-center gap-1.5 rounded-md border border-white/10 bg-slate-950/50 px-2.5 py-1 text-xs text-slate-200 hover:bg-white/5">
                <Layers size={14} /> Layers
              </button>
              {layersOpen && (
                <div className="absolute right-0 top-full z-30 mt-1 w-56 rounded-lg border border-white/10 bg-slate-900/95 p-2 shadow-xl backdrop-blur">
                  {LAYER_LABELS.map(([k, label]) => (
                    <label key={k} className="flex cursor-pointer items-center gap-2 rounded px-2 py-1 text-sm text-slate-200 hover:bg-white/5">
                      <input type="checkbox" className="accent-amber-300" checked={settings.layers[k]}
                        onChange={e => setSettings(s => ({ ...s, layers: { ...s.layers, [k]: e.target.checked } }))} />
                      {label}
                    </label>
                  ))}
                  <div className="my-1 border-t border-white/10" />
                  <label className="flex cursor-pointer items-center gap-2 rounded px-2 py-1 text-sm text-slate-200 hover:bg-white/5">
                    <input type="checkbox" className="accent-amber-300" checked={settings.dimDone} onChange={e => setSettings(s => ({ ...s, dimDone: e.target.checked }))} />
                    Dim finished islands
                  </label>
                </div>
              )}
            </div>
            <button onClick={() => setSettings(s => ({ ...s, showSpoilers: !s.showSpoilers }))}
              className={cn("inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs",
                settings.showSpoilers ? "border-rose-300/40 bg-rose-300/10 text-rose-100" : "border-white/10 bg-slate-950/50 text-slate-200 hover:bg-white/5")}
              title="Story spoilers (farewells, endings, secret places) are blurred until clicked. Toggle to show them all.">
              {settings.showSpoilers ? <Eye size={14} /> : <EyeOff size={14} />} Spoilers<span className="hidden sm:inline"> {settings.showSpoilers ? "shown" : "hidden"}</span>
            </button>
          </div>
        </header>

        <div className="flex min-h-0 flex-1 flex-col md:flex-row">
          <main className={cn("relative min-h-0 shrink-0 transition-[height] duration-200 md:h-auto md:flex-1 md:shrink", bigMap ? "h-[62dvh]" : "h-[45dvh]")}>
            <WorldMap settings={settings} api={api} selection={selection} onSelect={s => select(s)} focusKey={focusKey} />
          </main>
          <button onClick={() => setBigMap(b => !b)} className="flex items-center justify-center gap-1 border-t border-white/10 bg-[#0e1c2a] py-1 text-[11px] text-slate-400 md:hidden"
            aria-label={bigMap ? "Shrink map" : "Enlarge map"}>
            {bigMap ? <ChevronsUp size={14} /> : <ChevronsDown size={14} />} {bigMap ? "Smaller map" : "Bigger map"}
          </button>
          <aside className="flex min-h-0 flex-1 flex-col bg-[#101f2e] md:w-[360px] md:flex-none md:border-l md:border-white/10 lg:w-[430px]">
            <nav className="flex border-b border-white/10">
              {TABS.map(t => (
                <button key={t.id} onClick={() => { setTab(t.id); if (selection && TAB_FOR[selection.kind] !== t.id) setSelection(null); }}
                  className={cn("flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] transition-colors",
                    tab === t.id ? "border-b-2 border-amber-300 text-amber-100" : "border-b-2 border-transparent text-slate-400 hover:text-slate-200")}>
                  <t.icon size={16} />{t.label}
                </button>
              ))}
            </nav>
            <div ref={sideRef} className="min-h-0 flex-1 overflow-y-auto px-4 py-3">
              {tab === "islands" && <IslandPanel api={api} selectedId={idFor("island")} onSelect={panelSelect} />}
              {tab === "quests" && <QuestLog api={api} selectedId={idFor("quest")} onSelect={panelSelect} />}
              {tab === "events" && <EventsPanel selectedId={idFor("event")} onSelect={panelSelect} />}
              {tab === "spirits" && <SpiritsPanel api={api} selectedId={idFor("spirit")} onSelect={panelSelect} />}
              {tab === "progress" && <ProgressPanel api={api} />}
            </div>
            <footer className="flex items-center gap-1.5 border-t border-white/5 px-4 pb-[max(0.375rem,env(safe-area-inset-bottom))] pt-1.5 text-[10px] text-slate-500">
              <MapIcon size={11} className="shrink-0" /> <span className="truncate">Unofficial fan tool · data: Spiritfarer Fandom Wiki (CC-BY-SA) · Spiritfarer © Thunder Lotus Games</span>
            </footer>
          </aside>
        </div>
      </div>
    </SpoilerContext.Provider>
  );
}

interface InstallEvent extends Event { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> }

/** Chrome/Edge/Android "Add to home screen" prompt, captured so we can offer our own Install button. */
function useInstallPrompt() {
  const [evt, setEvt] = useState<InstallEvent | null>(null);
  useEffect(() => {
    const onPrompt = (e: Event) => { e.preventDefault(); setEvt(e as InstallEvent); };
    const onInstalled = () => setEvt(null);
    window.addEventListener("beforeinstallprompt", onPrompt);
    window.addEventListener("appinstalled", onInstalled);
    return () => { window.removeEventListener("beforeinstallprompt", onPrompt); window.removeEventListener("appinstalled", onInstalled); };
  }, []);
  if (!evt) return null;
  return () => { evt.prompt(); evt.userChoice.finally(() => setEvt(null)); };
}
SPIRITFARER_EOF

cat > "src/data.ts" << 'SPIRITFARER_EOF'
import raw from "./data/spiritfarer.json";
import type { GameData, Island, Quest, Region, SeaEvent, Spirit, Waypoint } from "./types";

export const data = raw as unknown as GameData;

export const islandById = new Map<string, Island>(data.islands.map(i => [i.id, i]));
export const questById = new Map<string, Quest>(data.quests.map(q => [q.id, q]));
export const spiritById = new Map<string, Spirit>(data.spirits.map(s => [s.id, s]));
export const eventById = new Map<string, SeaEvent>(data.events.map(e => [e.id, e]));
export const spiritByName = new Map<string, Spirit>(data.spirits.map(s => [s.name, s]));

export const img = (path: string) => (path ? data.imageBase + path : "");

export const REGION_COLORS: Record<Region, string> = {
  "Everdoor": "#f0a868",
  "Hummingberg": "#7fb7a4",
  "Furogawa": "#e08a7a",
  "Industrial District": "#9aa3c7",
  "Oxbury": "#d9b25f",
  "Crow's End": "#a98bc9",
};

export const ROLE_COLORS = { start: "#4ade80", mid: "#fbbf24", end: "#f87171", single: "#38bdf8" } as const;
export const ROLE_LABEL = { start: "Start", mid: "Waypoint", end: "Finish", single: "Start & finish" } as const;

/** Game coordinates (y up) for a waypoint. */
export function waypointPos(w: Waypoint): { x: number; y: number; label: string } {
  if (w.kind === "island") {
    const i = islandById.get(w.ref as string);
    return i ? { x: i.x, y: i.y, label: i.name } : { x: 0, y: 0, label: String(w.ref) };
  }
  const [x, y] = w.ref as [number, number];
  return { x, y, label: `Coordinates ${x}, ${y}` };
}

/** Quests that pass through an island, with the role the island plays in each. */
export const questsByIsland = new Map<string, { quest: Quest; roles: Waypoint["role"][] }[]>();
for (const q of data.quests) {
  const seen = new Map<string, Waypoint["role"][]>();
  for (const w of q.waypoints) {
    if (w.kind !== "island") continue;
    const id = w.ref as string;
    seen.set(id, [...(seen.get(id) ?? []), w.role]);
  }
  for (const [id, roles] of seen) {
    questsByIsland.set(id, [...(questsByIsland.get(id) ?? []), { quest: q, roles }]);
  }
}

/** Events whose points sit at or near an island (within `r` map units). */
export function eventsNear(i: Island, r = 30): SeaEvent[] {
  return data.events.filter(e => e.island === i.id ||
    (!e.approx && e.points.some(p => Math.hypot(p.x - i.x, p.y - i.y) <= r)));
}

export const abilityAt = (islandId: string) => data.abilities.filter(a => a.island === islandId);

/** Islands that can't be found without a treasure map or special unlock. */
export const SECRET_ISLANDS = new Set(["lost-shrine", "hidden-shrine"]);

export const QUEST_GROUPS: { id: string; label: string; filter: (q: Quest) => boolean }[] = [
  ...data.spirits.map(s => ({ id: s.id, label: s.name, filter: (q: Quest) => q.spirit === s.id })),
  { id: "shenanigans", label: "Shenanigans", filter: (q: Quest) => q.type === "Shenanigans" && !q.spirit },
  { id: "errands", label: "Francis's Errands", filter: (q: Quest) => q.type === "Errands" && !q.spirit },
  { id: "other", label: "Other", filter: (q: Quest) => q.type === "Requests" && !q.spirit },
];
SPIRITFARER_EOF

cat > "src/index.css" << 'SPIRITFARER_EOF'
@import "tailwindcss";

@theme {
  --font-display: "Fraunces", Georgia, serif;
  --font-hand: "Caveat", "Comic Neue", cursive;
}

::selection {
  background: rgba(245, 158, 11, 0.35);
  color: #fff;
}

html {
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
  color-scheme: dark;
}

body {
  background: #0b1622;
  overscroll-behavior: none; /* no pull-to-refresh / rubber-banding while panning the map */
  -webkit-tap-highlight-color: transparent;
  font-family: "Inter", system-ui, -apple-system, "Segoe UI", sans-serif;
}

/* Slim scrollbars for the sidebar */
* { scrollbar-width: thin; scrollbar-color: #334155 transparent; }

/* Touch screens: iOS zooms the page when focusing inputs under 16px, so bump them up. */
@media (pointer: coarse) {
  input:not([type="checkbox"]):not([type="radio"]), textarea, select { font-size: 16px; }
  input[type="checkbox"] { width: 1.05rem; height: 1.05rem; }
}
SPIRITFARER_EOF

cat > "src/main.tsx" << 'SPIRITFARER_EOF'
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);

// Offline support for the installed (home-screen) app. Skipped for file:// (the local launcher) and the dev server.
if ("serviceWorker" in navigator && import.meta.env.PROD && location.protocol !== "file:") {
  window.addEventListener("load", () => { navigator.serviceWorker.register("./sw.js").catch(() => {}); });
}
SPIRITFARER_EOF

cat > "src/store.ts" << 'SPIRITFARER_EOF'
import { useCallback, useEffect, useState } from "react";
import type { Progress, QuestStatus } from "./types";
import { questById } from "./data";

const PROGRESS_KEY = "spiritfarer-map:progress";
const SETTINGS_KEY = "spiritfarer-map:settings";

const emptyProgress = (): Progress => ({ version: 1, quests: {}, islands: {} });

function load<T>(key: string, fallback: T): T {
  try {
    const v = localStorage.getItem(key);
    return v ? { ...fallback, ...JSON.parse(v) } : fallback;
  } catch {
    return fallback;
  }
}
function save(key: string, value: unknown) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* storage unavailable */ }
}

export function useProgress() {
  const [progress, setProgress] = useState<Progress>(() => load(PROGRESS_KEY, emptyProgress()));
  useEffect(() => save(PROGRESS_KEY, progress), [progress]);

  const questStatus = useCallback((id: string): QuestStatus => progress.quests[id]?.status ?? "todo", [progress]);
  const questSteps = useCallback((id: string) => progress.quests[id]?.steps ?? [], [progress]);

  const setQuestStatus = useCallback((id: string, status: QuestStatus) => {
    setProgress(p => {
      const steps = status === "done" ? (questById.get(id)?.objectives.map((_, i) => i) ?? []) : (p.quests[id]?.steps ?? []);
      return { ...p, quests: { ...p.quests, [id]: { status, steps: status === "todo" ? [] : steps } } };
    });
  }, []);

  const toggleStep = useCallback((id: string, step: number) => {
    setProgress(p => {
      const cur = p.quests[id] ?? { status: "todo" as QuestStatus, steps: [] };
      const steps = cur.steps.includes(step) ? cur.steps.filter(s => s !== step) : [...cur.steps, step];
      const total = questById.get(id)?.objectives.length ?? 0;
      const status: QuestStatus = total > 0 && steps.length >= total ? "done" : steps.length > 0 ? "active" : cur.status === "done" ? "active" : cur.status;
      return { ...p, quests: { ...p.quests, [id]: { status, steps } } };
    });
  }, []);

  const updateIsland = useCallback((id: string, patch: Progress["islands"][string]) => {
    setProgress(p => ({ ...p, islands: { ...p.islands, [id]: { ...p.islands[id], ...patch } } }));
  }, []);

  const toggleChest = useCallback((id: string, n: number) => {
    setProgress(p => {
      const cur = p.islands[id]?.chests ?? [];
      const chests = cur.includes(n) ? cur.filter(c => c !== n) : [...cur, n];
      return { ...p, islands: { ...p.islands, [id]: { ...p.islands[id], chests } } };
    });
  }, []);

  const exportJson = useCallback(() => JSON.stringify({ app: "spiritfarer-map", exportedAt: new Date().toISOString(), ...progress }, null, 2), [progress]);

  const importJson = useCallback((text: string): string | null => {
    try {
      const parsed = JSON.parse(text);
      if (typeof parsed !== "object" || !parsed || typeof parsed.quests !== "object" || typeof parsed.islands !== "object") {
        return "That file doesn't look like a Spiritfarer Map progress export.";
      }
      setProgress({ version: 1, quests: parsed.quests, islands: parsed.islands });
      return null;
    } catch {
      return "Couldn't read that file as JSON.";
    }
  }, []);

  const reset = useCallback(() => setProgress(emptyProgress()), []);

  return { progress, questStatus, questSteps, setQuestStatus, toggleStep, updateIsland, toggleChest, exportJson, importJson, reset };
}
export type ProgressApi = ReturnType<typeof useProgress>;

export interface Settings {
  background: "chart" | "wiki";
  showSpoilers: boolean;
  layers: { islands: boolean; labels: boolean; events: boolean; busStops: boolean; treasures: boolean; shrines: boolean; activeQuests: boolean; grid: boolean };
  dimDone: boolean;
}
const defaultSettings: Settings = {
  background: "chart",
  showSpoilers: false,
  layers: { islands: true, labels: true, events: true, busStops: false, treasures: false, shrines: true, activeQuests: true, grid: true },
  dimDone: true,
};

export function useSettings() {
  const [settings, setSettings] = useState<Settings>(() => {
    const s = load(SETTINGS_KEY, defaultSettings);
    return { ...s, layers: { ...defaultSettings.layers, ...s.layers } };
  });
  useEffect(() => save(SETTINGS_KEY, settings), [settings]);
  return [settings, setSettings] as const;
}
SPIRITFARER_EOF

cat > "src/types.ts" << 'SPIRITFARER_EOF'
export type Region = "Everdoor" | "Hummingberg" | "Furogawa" | "Industrial District" | "Oxbury" | "Crow's End";

export interface Chest { text: string; needs: string[] }
export interface Section { heading: string; lines: string[] }

export interface Island {
  id: string; name: string; region: Region;
  x: number; y: number; bus: [number, number] | null;
  requirements: string[]; spirits: string[];
  resources: string[]; shop: string[]; other: string[];
  intro: string[]; chests: Chest[]; sections: Section[];
  image: string; spoiler: boolean;
}

export interface Spirit {
  id: string; name: string; species: string;
  origin: string | null; originText: string;
  house: string; event: string; favouriteFood: string;
  likes: string; dislikes: string; skills: string; flower: string;
  firstQuest: string; lastQuest: string;
  about: string[]; life: string[]; everdoor: string[];
  image: string; dlc: boolean; quests: string[];
}

export interface EventPoint { x: number; y: number; label: string }
export interface SeaEvent {
  id: string; name: string; spirit: string | null;
  resource: string; duration: string; requires: string; house: string;
  trigger: "sea" | "island" | "manual"; island: string | null;
  points: EventPoint[]; approx: boolean; regionText: string;
  details: string[]; image: string;
}

export type WaypointRole = "start" | "mid" | "end" | "single";
export interface Waypoint {
  kind: "island" | "point";
  ref: string | [number, number];
  step: number; why: string; role: WaypointRole;
}
export interface Objective { text: string; depth: number }
export type QuestType = "Requests" | "Shenanigans" | "Errands";
export interface Quest {
  id: string; title: string; number: string; type: QuestType;
  giver: string; spirit: string | null;
  description: string; prereq: string; location: string; onBoat: boolean;
  rewards: string[]; repeatable: boolean;
  prev: string[]; next: string[];
  objectives: Objective[]; notes: string[];
  waypoints: Waypoint[]; image: string; spoiler: boolean;
}

export interface Ability { name: string; island: string | null; unlock: string; controls: string; details: string[] }
export interface Treasure { x: number; y: number; source: string; reward: string }
export interface BusStop { x: number; y: number; near: string[] }

export interface GameData {
  source: string; imageBase: string;
  worldMap: { url: string; bounds: { x0: number; x1: number; yTop: number; yBottom: number } };
  regions: Region[];
  islands: Island[]; spirits: Spirit[]; abilities: Ability[];
  treasures: Treasure[]; busStops: BusStop[];
  events: SeaEvent[]; quests: Quest[];
}

export type QuestStatus = "todo" | "active" | "done";
export interface Progress {
  version: 1;
  quests: Record<string, { status: QuestStatus; steps: number[] }>;
  islands: Record<string, { visited?: boolean; chests?: number[]; notes?: string }>;
}

export type Selection =
  | { kind: "island"; id: string }
  | { kind: "quest"; id: string }
  | { kind: "event"; id: string }
  | { kind: "spirit"; id: string }
  | null;

export type Tab = "islands" | "quests" | "events" | "spirits" | "progress";
SPIRITFARER_EOF

cat > "src/components/EventsPanel.tsx" << 'SPIRITFARER_EOF'
import { islandById, data, eventById, img, spiritById } from "@/data";
import type { SeaEvent, Selection } from "@/types";
import { cn } from "@/utils/cn";
import { BackButton, Chip, Lines, SectionTitle, WikiImage } from "./ui";
import { eventStyle } from "./WorldMap";

interface Props { selectedId: string | null; onSelect: (s: Selection, fly?: boolean) => void }

const GROUPS: { trigger: SeaEvent["trigger"]; title: string; blurb: string }[] = [
  { trigger: "sea", title: "Sea events", blurb: "Sail into these spots with the right spirit aboard; your boat stops and an indicator asks “Start the event?”. After the spirit leaves, start it from their house door instead. The map's Safe Travel option skips them." },
  { trigger: "island", title: "Island events", blurb: "Triggered on an island itself." },
  { trigger: "manual", title: "Aboard the boat", blurb: "Started by interacting with something in the spirit's house. They recharge after a while, with no indicator." },
];

export default function EventsPanel({ selectedId, onSelect }: Props) {
  const e = selectedId ? eventById.get(selectedId) : undefined;
  if (e) return <EventDetail e={e} onSelect={onSelect} />;
  return (
    <div>
      {GROUPS.map(g => (
        <div key={g.trigger}>
          <SectionTitle>{g.title}</SectionTitle>
          <p className="mb-2 text-xs leading-relaxed text-slate-400">{g.blurb}</p>
          <ul className="divide-y divide-white/5 rounded-lg border border-white/5 bg-white/[0.02]">
            {data.events.filter(x => x.trigger === g.trigger).map(x => {
              const st = eventStyle(x); const Icon = st.icon;
              const s = x.spirit ? spiritById.get(x.spirit) : undefined;
              return (
                <li key={x.id}>
                  <button onClick={() => onSelect({ kind: "event", id: x.id }, true)} className="flex w-full items-center gap-2.5 px-3 py-2 text-left hover:bg-white/5">
                    <Icon size={16} color={st.color} className="shrink-0" />
                    <span className="flex-1">
                      <span className="block text-sm text-slate-100">{x.name}</span>
                      <span className="block text-[11px] text-slate-400">{[s?.name, x.resource].filter(Boolean).join(" · ")}</span>
                    </span>
                    {x.points.length > 1 && <span className="text-[11px] text-slate-500">{x.points.length} spots</span>}
                  </button>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </div>
  );
}

function EventDetail({ e, onSelect }: { e: SeaEvent; onSelect: Props["onSelect"] }) {
  const st = eventStyle(e); const Icon = st.icon;
  const s = e.spirit ? spiritById.get(e.spirit) : undefined;
  return (
    <div>
      <BackButton onClick={() => onSelect(null)} label="All events" />
      <div className="flex items-start gap-3">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl border" style={{ borderColor: st.color + "66", background: st.color + "14" }}>
          <WikiImage src={img(e.image)} alt="" className="h-10 w-10 object-contain" />
          {!e.image && <Icon size={24} color={st.color} />}
        </div>
        <div>
          <h2 className="font-display text-xl font-semibold text-amber-50">{e.name}</h2>
          <div className="mt-1 flex flex-wrap gap-1.5">
            <Chip color={st.color}><Icon size={10} /> {e.trigger === "sea" ? "Sea event" : e.trigger === "island" ? "Island event" : "Aboard the boat"}</Chip>
            {e.duration && <Chip className="border-white/10 text-slate-300">{e.duration}</Chip>}
          </div>
        </div>
      </div>

      <dl className="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1.5 text-[13px]">
        {s && <><dt className="text-slate-400">Spirit</dt><dd><button className="text-amber-200 hover:underline" onClick={() => onSelect({ kind: "spirit", id: s.id }, true)}>{s.name}</button> must be aboard</dd></>}
        {e.resource && <><dt className="text-slate-400">Reward</dt><dd className="text-slate-200">{e.resource}</dd></>}
        {e.requires && <><dt className="text-slate-400">Requires</dt><dd className="text-rose-200">{e.requires}</dd></>}
        {e.house && <><dt className="text-slate-400">Trigger</dt><dd className="text-slate-200">{e.house}</dd></>}
        {e.regionText && <><dt className="text-slate-400">Where</dt><dd className="text-slate-200">{e.regionText}</dd></>}
      </dl>

      {e.points.length > 0 && (
        <>
          <SectionTitle>{e.approx ? "Approximate areas" : "Locations"}</SectionTitle>
          {e.approx && <p className="mb-2 text-xs text-slate-400">The wiki lists this event by region. These pins are taken from the storm and meteor zones on the community world map.</p>}
          <div className="flex flex-wrap gap-1.5">
            {e.points.map((p, n) => {
              const isl = e.island ? islandById.get(e.island) : undefined;
              return (
                <button key={n} onClick={() => isl ? onSelect({ kind: "island", id: isl.id }, true) : onSelect({ kind: "event", id: e.id }, true)}
                  className={cn("rounded-md border border-white/10 px-2 py-1 text-xs text-slate-200 hover:bg-white/5")}>
                  {p.label ? `${p.label} · ` : ""}{p.x}, {p.y}
                </button>
              );
            })}
          </div>
        </>
      )}

      {e.details.length > 0 && (<><SectionTitle>How it works</SectionTitle><Lines lines={e.details} /></>)}
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/IslandPanel.tsx" << 'SPIRITFARER_EOF'
import { useContext, useMemo, useState } from "react";
import { Check, Gem, Lock, MapPin, NotebookPen, Store } from "lucide-react";
import { abilityAt, data, eventsNear, img, islandById, questsByIsland, REGION_COLORS, ROLE_COLORS, ROLE_LABEL, SECRET_ISLANDS, spiritByName } from "@/data";
import type { Island, Selection } from "@/types";
import type { ProgressApi } from "@/store";
import { cn } from "@/utils/cn";
import { Spoiler, SpoilerContext } from "./Spoiler";
import { BackButton, Chip, Lines, SearchBox, SectionTitle, StatusButton, WikiImage } from "./ui";
import { eventStyle } from "./WorldMap";

interface Props { api: ProgressApi; selectedId: string | null; onSelect: (s: Selection, fly?: boolean) => void }

export default function IslandPanel({ api, selectedId, onSelect }: Props) {
  const island = selectedId ? islandById.get(selectedId) : undefined;
  return island ? <IslandDetail i={island} api={api} onSelect={onSelect} /> : <IslandList api={api} onSelect={onSelect} />;
}

function IslandList({ api, onSelect }: Omit<Props, "selectedId">) {
  const [q, setQ] = useState("");
  const showSpoilers = useContext(SpoilerContext);
  const groups = useMemo(() => data.regions.map(r => ({
    region: r,
    islands: data.islands.filter(i => i.region === r && (!q || i.name.toLowerCase().includes(q.toLowerCase()) || i.shop.concat(i.other, i.spirits).join(" ").toLowerCase().includes(q.toLowerCase())))
      .sort((a, b) => a.name.localeCompare(b.name)),
  })).filter(g => g.islands.length), [q]);
  const visited = data.islands.filter(i => api.progress.islands[i.id]?.visited).length;
  return (
    <div>
      <div className="mb-3 flex items-center justify-between text-xs text-slate-400">
        <span>{data.islands.length} locations · {visited} visited</span>
        <span>Search names, spirits, shop items</span>
      </div>
      <SearchBox value={q} onChange={setQ} placeholder="Search islands…" />
      {groups.map(g => (
        <div key={g.region}>
          <SectionTitle>
            <span className="inline-flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{ background: REGION_COLORS[g.region] }} />{g.region} Region</span>
          </SectionTitle>
          <ul className="divide-y divide-white/5 rounded-lg border border-white/5 bg-white/[0.02]">
            {g.islands.map(i => {
              const p = api.progress.islands[i.id];
              const secret = SECRET_ISLANDS.has(i.id) && !showSpoilers && !p?.visited;
              const qs = questsByIsland.get(i.id)?.length ?? 0;
              return (
                <li key={i.id}>
                  <button onClick={() => onSelect({ kind: "island", id: i.id }, true)} className="flex w-full items-center gap-2 px-3 py-2 text-left hover:bg-white/5">
                    <span className={cn("flex h-4 w-4 items-center justify-center rounded-full border", p?.visited ? "border-emerald-400 bg-emerald-400/20 text-emerald-300" : "border-slate-600")}>
                      {p?.visited && <Check size={11} />}
                    </span>
                    <span className="flex-1 text-sm text-slate-100">{secret ? <span className="italic text-slate-500">Secret location</span> : i.name}</span>
                    {i.spirits.length > 0 && !secret && <span className="text-[11px] text-amber-200/80">{i.spirits.join(", ")}</span>}
                    {i.chests.length > 0 && <span className="text-[11px] text-slate-500">{(p?.chests?.length ?? 0)}/{i.chests.length}▣</span>}
                    {qs > 0 && <span className="text-[11px] text-slate-500">{qs}q</span>}
                  </button>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </div>
  );
}

function IslandDetail({ i, api, onSelect }: { i: Island; api: ProgressApi; onSelect: Props["onSelect"] }) {
  const p = api.progress.islands[i.id] ?? {};
  const quests = questsByIsland.get(i.id) ?? [];
  const events = eventsNear(i);
  const abilities = abilityAt(i.id);
  const secret = SECRET_ISLANDS.has(i.id);
  const order = { start: 0, single: 1, mid: 2, end: 3 };
  const sortedQuests = [...quests].sort((a, b) => Math.min(...a.roles.map(r => order[r])) - Math.min(...b.roles.map(r => order[r])));

  return (
    <div>
      <BackButton onClick={() => onSelect(null)} label="All islands" />
      <Spoiler active={secret} block>
        <div className="flex items-start gap-3">
          <WikiImage src={img(i.image)} alt={i.name} className="h-20 w-28 shrink-0 rounded-md border border-white/10 object-cover" />
          <div className="min-w-0 flex-1">
            <h2 className="font-display text-xl font-semibold text-amber-50">{i.name}</h2>
            <div className="mt-1 flex flex-wrap gap-1.5">
              <Chip color={REGION_COLORS[i.region]}>{i.region}</Chip>
              <Chip className="border-white/10 text-slate-300" title="In-game map coordinates"><MapPin size={10} />{i.x}, {i.y}</Chip>
              {i.bus && <Chip color="#38bdf8" title="Nearest bus stop">Bus {i.bus[0]}, {i.bus[1]}</Chip>}
            </div>
          </div>
        </div>
      </Spoiler>

      <label className="mt-3 flex cursor-pointer items-center gap-2 text-sm text-slate-200">
        <input type="checkbox" className="accent-emerald-400" checked={!!p.visited} onChange={e => api.updateIsland(i.id, { visited: e.target.checked })} />
        I've visited this island
      </label>

      {i.requirements.length > 0 && (
        <div className="mt-3 flex items-center gap-2 rounded-md border border-rose-400/20 bg-rose-400/5 px-3 py-2 text-[13px] text-rose-100">
          <Lock size={14} className="shrink-0" /> Needs boat upgrade: <b>{i.requirements.join(", ")}</b>
        </div>
      )}

      <Spoiler active={i.spoiler && i.id !== "everdoor"} block>
        {i.intro.length > 0 && <Lines lines={i.intro} className="mt-3" />}

        {i.spirits.length > 0 && (
          <>
            <SectionTitle>Spirits found here</SectionTitle>
            <div className="flex flex-wrap gap-2">
              {i.spirits.map(n => {
                const s = spiritByName.get(n);
                return s ? (
                  <button key={n} onClick={() => onSelect({ kind: "spirit", id: s.id }, true)} className="flex items-center gap-2 rounded-lg border border-amber-200/20 bg-amber-200/5 px-2 py-1 text-sm text-amber-100 hover:bg-amber-200/10">
                    <WikiImage src={img(s.image)} alt={n} className="h-7 w-7 rounded-full object-cover object-top" />{n}
                  </button>
                ) : <Chip key={n} color="#fcd34d">{n}</Chip>;
              })}
            </div>
          </>
        )}

        {abilities.length > 0 && (
          <>
            <SectionTitle>Shrine</SectionTitle>
            {abilities.map(a => (
              <div key={a.name} className="rounded-lg border border-violet-300/20 bg-violet-300/5 p-3 text-[13px]">
                <div className="flex items-center gap-2 font-semibold text-violet-200"><Gem size={14} /> {a.name} <span className="font-normal text-violet-300/60">· 2 Obols</span></div>
                <div className="mt-1 text-slate-300">{a.controls}</div>
                {a.unlock.includes("(") && <div className="mt-1 text-xs text-slate-400">{a.unlock.slice(a.unlock.indexOf("("))}</div>}
              </div>
            ))}
          </>
        )}

        {sortedQuests.length > 0 && (
          <>
            <SectionTitle>Quests here ({sortedQuests.length})</SectionTitle>
            <ul className="space-y-1">
              {sortedQuests.map(({ quest: q, roles }) => (
                <li key={q.id} className="flex items-center gap-2 rounded-md px-1 py-1 hover:bg-white/5">
                  <StatusButton status={api.questStatus(q.id)} onChange={s => api.setQuestStatus(q.id, s)} size={16} />
                  <button onClick={() => onSelect({ kind: "quest", id: q.id }, true)} className="min-w-0 flex-1 truncate text-left text-sm text-slate-100 hover:text-amber-100">
                    <Spoiler active={q.spoiler}>{q.title}</Spoiler>
                  </button>
                  {[...new Set(roles)].map(r => <Chip key={r} color={ROLE_COLORS[r]}>{ROLE_LABEL[r]}</Chip>)}
                </li>
              ))}
            </ul>
          </>
        )}

        {events.length > 0 && (
          <>
            <SectionTitle>Events here / nearby</SectionTitle>
            <div className="flex flex-wrap gap-1.5">
              {events.map(e => {
                const st = eventStyle(e); const Icon = st.icon;
                return (
                  <button key={e.id} onClick={() => onSelect({ kind: "event", id: e.id }, true)} className="inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs hover:bg-white/5" style={{ borderColor: st.color + "66", color: st.color }}>
                    <Icon size={12} /> {e.name}
                  </button>
                );
              })}
            </div>
          </>
        )}

        {i.chests.length > 0 && (
          <>
            <SectionTitle right={<span className="text-xs text-slate-500">{p.chests?.length ?? 0}/{i.chests.length} opened</span>}>Chests &amp; collectibles</SectionTitle>
            <ul className="space-y-1.5">
              {i.chests.map((c, n) => {
                const got = p.chests?.includes(n);
                return (
                  <li key={n}>
                    <label className={cn("flex cursor-pointer gap-2 rounded-md px-1 py-1 text-[13px] hover:bg-white/5", got ? "text-slate-500 line-through" : "text-slate-200")}>
                      <input type="checkbox" className="mt-0.5 accent-emerald-400" checked={!!got} onChange={() => api.toggleChest(i.id, n)} />
                      <span>
                        {c.text}
                        {c.needs.length > 0 && <span className="ml-1 inline-flex flex-wrap gap-1 align-middle no-underline">{c.needs.map(nd => <Chip key={nd} color={nd.startsWith("Key") ? "#fbbf24" : "#c4b5fd"}>{nd}</Chip>)}</span>}
                      </span>
                    </label>
                  </li>
                );
              })}
            </ul>
          </>
        )}

        {(i.shop.length > 0 || i.resources.length > 0 || i.other.length > 0) && (
          <>
            <SectionTitle>Shop, resources &amp; points of interest</SectionTitle>
            <div className="space-y-2 text-[13px]">
              {i.shop.length > 0 && <div className="flex gap-2"><Store size={14} className="mt-0.5 shrink-0 text-amber-300" /><span className="text-slate-300"><b className="text-slate-100">Shop:</b> {i.shop.join(", ")}</span></div>}
              {i.resources.length > 0 && <div className="text-slate-300"><b className="text-slate-100">Resources:</b> {i.resources.join(", ")}</div>}
              {i.other.length > 0 && <div className="text-slate-300"><b className="text-slate-100">Also here:</b> {i.other.join(", ")}</div>}
            </div>
          </>
        )}

        {i.sections.map(s => (
          <div key={s.heading}>
            <SectionTitle>{s.heading}</SectionTitle>
            <Lines lines={s.lines} />
          </div>
        ))}
      </Spoiler>

      <SectionTitle><span className="inline-flex items-center gap-1.5"><NotebookPen size={13} /> My notes</span></SectionTitle>
      <textarea
        value={p.notes ?? ""} onChange={e => api.updateIsland(i.id, { notes: e.target.value })}
        placeholder="Anything you want to remember about this island…" rows={3}
        className="w-full rounded-md border border-white/10 bg-slate-950/60 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600 focus:border-amber-300/50 focus:outline-none"
      />
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/ProgressPanel.tsx" << 'SPIRITFARER_EOF'
import { useRef, useState } from "react";
import { Copy, Download, Trash2, Upload } from "lucide-react";
import { data } from "@/data";
import type { ProgressApi } from "@/store";
import { SectionTitle } from "./ui";

export default function ProgressPanel({ api }: { api: ProgressApi }) {
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);
  const [paste, setPaste] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);
  const p = api.progress;

  const questsDone = data.quests.filter(q => api.questStatus(q.id) === "done").length;
  const questsActive = data.quests.filter(q => api.questStatus(q.id) === "active").length;
  const visited = data.islands.filter(i => p.islands[i.id]?.visited).length;
  const chestsTotal = data.islands.reduce((n, i) => n + i.chests.length, 0);
  const chestsDone = data.islands.reduce((n, i) => n + (p.islands[i.id]?.chests?.length ?? 0), 0);
  const notes = Object.values(p.islands).filter(i => i.notes?.trim()).length;
  const spiritsDone = data.spirits.filter(s => s.quests.length && s.quests.every(q => api.questStatus(q) === "done")).length;

  const stats: [string, number, number][] = [
    ["Quests completed", questsDone, data.quests.length],
    ["Islands visited", visited, data.islands.length],
    ["Chests opened", chestsDone, chestsTotal],
    ["Storylines finished", spiritsDone, data.spirits.length],
  ];

  const download = () => {
    const blob = new Blob([api.exportJson()], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `spiritfarer-progress-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(a.href);
  };
  const doImport = (text: string) => {
    const err = api.importJson(text);
    setMsg(err ? { ok: false, text: err } : { ok: true, text: "Progress imported." });
    if (!err) setPaste("");
  };

  return (
    <div>
      <div className="space-y-2.5">
        {stats.map(([label, n, total]) => (
          <div key={label}>
            <div className="flex justify-between text-[13px]"><span className="text-slate-300">{label}</span><span className="text-slate-400">{n} / {total}</span></div>
            <div className="mt-1 h-2 overflow-hidden rounded-full bg-slate-800"><div className="h-full rounded-full bg-gradient-to-r from-amber-300 to-emerald-400" style={{ width: `${total ? (n / total) * 100 : 0}%` }} /></div>
          </div>
        ))}
        <p className="text-xs text-slate-500">{questsActive} quests in progress · {notes} islands with notes</p>
      </div>

      <SectionTitle>Save &amp; share</SectionTitle>
      <p className="mb-2 text-xs leading-relaxed text-slate-400">Progress is saved in this browser automatically. Export a backup to move it to another machine or browser.</p>
      <div className="flex flex-wrap gap-2">
        <button onClick={download} className="inline-flex items-center gap-1.5 rounded-md bg-amber-300/15 px-3 py-1.5 text-sm text-amber-100 hover:bg-amber-300/25"><Download size={14} /> Export JSON</button>
        <button onClick={() => navigator.clipboard.writeText(api.exportJson()).then(() => setMsg({ ok: true, text: "Copied to clipboard." }), () => setMsg({ ok: false, text: "Clipboard unavailable." }))}
          className="inline-flex items-center gap-1.5 rounded-md bg-white/5 px-3 py-1.5 text-sm text-slate-200 hover:bg-white/10"><Copy size={14} /> Copy</button>
        <button onClick={() => fileRef.current?.click()} className="inline-flex items-center gap-1.5 rounded-md bg-white/5 px-3 py-1.5 text-sm text-slate-200 hover:bg-white/10"><Upload size={14} /> Import file</button>
        <input ref={fileRef} type="file" accept="application/json,.json" className="hidden"
          onChange={e => { const f = e.target.files?.[0]; if (f) f.text().then(doImport); e.target.value = ""; }} />
      </div>
      <textarea value={paste} onChange={e => setPaste(e.target.value)} rows={3} placeholder="…or paste exported JSON here"
        className="mt-2 w-full rounded-md border border-white/10 bg-slate-950/60 px-3 py-2 font-mono text-xs text-slate-200 placeholder:text-slate-600 focus:outline-none" />
      {paste.trim() && <button onClick={() => doImport(paste)} className="mt-1 rounded-md bg-white/5 px-3 py-1 text-sm text-slate-200 hover:bg-white/10">Import pasted JSON</button>}
      {msg && <p className={msg.ok ? "mt-2 text-sm text-emerald-300" : "mt-2 text-sm text-rose-300"}>{msg.text}</p>}

      <SectionTitle>Danger zone</SectionTitle>
      <button onClick={() => { if (confirm("Clear all quest, island and chest progress and notes? Export a backup first if you might want it back.")) { api.reset(); setMsg({ ok: true, text: "Progress cleared." }); } }}
        className="inline-flex items-center gap-1.5 rounded-md border border-rose-400/30 px-3 py-1.5 text-sm text-rose-200 hover:bg-rose-400/10"><Trash2 size={14} /> Reset all progress</button>

      <SectionTitle>Credits</SectionTitle>
      <p className="text-xs leading-relaxed text-slate-400">
        Island, quest, event and spirit data compiled from the <a className="text-amber-200 hover:underline" href="https://spiritfarer.fandom.com" target="_blank" rel="noreferrer">Spiritfarer Fandom Wiki</a> (CC-BY-SA).
        Artwork is loaded from the wiki at runtime. Spiritfarer © Thunder Lotus Games. This is an unofficial fan tool.
      </p>
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/QuestLog.tsx" << 'SPIRITFARER_EOF'
import { useMemo, useState } from "react";
import { ArrowLeft, ArrowRight, ChevronDown, ChevronRight, Gift, MapPin, Ship } from "lucide-react";
import { data, islandById, QUEST_GROUPS, questById, ROLE_COLORS, ROLE_LABEL, spiritById, waypointPos } from "@/data";
import type { Quest, QuestStatus, Selection } from "@/types";
import type { ProgressApi } from "@/store";
import { cn } from "@/utils/cn";
import { Spoiler } from "./Spoiler";
import { BackButton, Chip, Lines, SearchBox, Segmented, SectionTitle, STATUS_LABEL, StatusButton } from "./ui";

interface Props { api: ProgressApi; selectedId: string | null; onSelect: (s: Selection, fly?: boolean) => void }

const TYPE_COLOR = { Requests: "#fcd34d", Shenanigans: "#5eead4", Errands: "#f9a8d4" } as const;

export default function QuestLog({ api, selectedId, onSelect }: Props) {
  const q = selectedId ? questById.get(selectedId) : undefined;
  return q ? <QuestDetail q={q} api={api} onSelect={onSelect} /> : <QuestList api={api} onSelect={onSelect} />;
}

function QuestList({ api, onSelect }: Omit<Props, "selectedId">) {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<"all" | QuestStatus>("all");
  const [pinsOnly, setPinsOnly] = useState(false);
  const [open, setOpen] = useState<Record<string, boolean>>({});

  const groups = useMemo(() => {
    const s = search.toLowerCase();
    return QUEST_GROUPS.map(g => {
      const spirit = spiritById.get(g.id);
      // Spirit storylines follow the in-game chain order; other groups are alphabetical.
      const base = spirit
        ? spirit.quests.map(id => questById.get(id)!).filter(Boolean)
        : data.quests.filter(g.filter).sort((a, b) => a.title.localeCompare(b.title));
      const quests = base.filter(q =>
        (status === "all" || api.questStatus(q.id) === status) &&
        (!pinsOnly || q.waypoints.length > 0) &&
        (!s || q.title.toLowerCase().includes(s) || q.description.toLowerCase().includes(s) ||
          q.waypoints.some(w => waypointPos(w).label.toLowerCase().includes(s))));
      const done = base.filter(q => api.questStatus(q.id) === "done").length;
      return { ...g, spirit, quests, done, total: base.length };
    }).filter(g => g.quests.length);
  }, [search, status, pinsOnly, api]);

  const counts = useMemo(() => {
    const c = { todo: 0, active: 0, done: 0 };
    for (const q of data.quests) c[api.questStatus(q.id)]++;
    return c;
  }, [api]);
  const filtering = !!search || status !== "all" || pinsOnly;

  return (
    <div>
      <div className="mb-3 grid grid-cols-3 gap-2 text-center">
        {(["active", "done", "todo"] as const).map(k => (
          <button key={k} onClick={() => setStatus(status === k ? "all" : k)}
            className={cn("rounded-lg border px-2 py-1.5 transition-colors", status === k ? "border-amber-300/50 bg-amber-300/10" : "border-white/5 bg-white/[0.03] hover:bg-white/5")}>
            <div className={cn("font-display text-lg font-semibold", k === "done" ? "text-emerald-300" : k === "active" ? "text-amber-200" : "text-slate-300")}>{counts[k]}</div>
            <div className="text-[11px] text-slate-400">{STATUS_LABEL[k]}</div>
          </button>
        ))}
      </div>
      <SearchBox value={search} onChange={setSearch} placeholder="Search quests, places…" />
      <div className="mt-2 flex items-center justify-between">
        <Segmented value={status} onChange={setStatus} options={[{ value: "all", label: "All" }, { value: "active", label: "Active" }, { value: "todo", label: "To do" }, { value: "done", label: "Done" }]} />
        <label className="flex items-center gap-1.5 text-xs text-slate-400">
          <input type="checkbox" className="accent-amber-300" checked={pinsOnly} onChange={e => setPinsOnly(e.target.checked)} /> Has map pins
        </label>
      </div>

      {groups.map(g => {
        const isOpen = open[g.id] ?? (filtering || g.quests.some(q => api.questStatus(q.id) === "active"));
        return (
          <div key={g.id} className="mt-3 rounded-lg border border-white/5 bg-white/[0.02]">
            <button onClick={() => setOpen(o => ({ ...o, [g.id]: !isOpen }))} className="flex w-full items-center gap-2 px-3 py-2 text-left hover:bg-white/5">
              {isOpen ? <ChevronDown size={14} className="text-slate-500" /> : <ChevronRight size={14} className="text-slate-500" />}
              <span className="flex-1 font-display text-sm font-semibold text-amber-50">{g.spirit ? `${g.label}'s storyline` : g.label}</span>
              <span className="text-[11px] text-slate-500">{g.done}/{g.total}</span>
              <span className="h-1.5 w-14 overflow-hidden rounded-full bg-slate-800"><span className="block h-full bg-emerald-400/70" style={{ width: `${(g.done / g.total) * 100}%` }} /></span>
            </button>
            {isOpen && (
              <ol className="border-t border-white/5 py-1">
                {g.quests.map(q => <QuestRow key={q.id + g.id} q={q} api={api} onSelect={onSelect} />)}
              </ol>
            )}
          </div>
        );
      })}
      {!groups.length && <p className="mt-6 text-center text-sm text-slate-500">No quests match.</p>}
    </div>
  );
}

function QuestRow({ q, api, onSelect }: { q: Quest; api: ProgressApi; onSelect: Props["onSelect"] }) {
  const st = api.questStatus(q.id);
  const steps = api.questSteps(q.id).length;
  return (
    <li className="flex items-center gap-2 px-3 py-1.5 hover:bg-white/5">
      <StatusButton status={st} onChange={s => api.setQuestStatus(q.id, s)} size={16} />
      <button onClick={() => onSelect({ kind: "quest", id: q.id }, true)} className={cn("min-w-0 flex-1 truncate text-left text-[13px]", st === "done" ? "text-slate-500" : "text-slate-100 hover:text-amber-100")}>
        <Spoiler active={q.spoiler}>{q.title}</Spoiler>
      </button>
      {st === "active" && q.objectives.length > 1 && <span className="text-[10px] text-amber-200/70">{steps}/{q.objectives.length}</span>}
      {q.waypoints.length > 0
        ? <span className="inline-flex items-center gap-0.5 text-[11px] text-slate-400" title={q.waypoints.map(w => waypointPos(w).label).join(" → ")}><MapPin size={11} />{q.waypoints.length}</span>
        : <span title="Happens aboard Stella's boat or anywhere" className="text-slate-600"><Ship size={12} /></span>}
    </li>
  );
}

function QuestDetail({ q, api, onSelect }: { q: Quest; api: ProgressApi; onSelect: Props["onSelect"] }) {
  const st = api.questStatus(q.id);
  const steps = api.questSteps(q.id);
  const spirit = q.spirit ? spiritById.get(q.spirit) : undefined;
  const chain = spirit?.quests ?? [];
  const idx = chain.indexOf(q.id);

  return (
    <div>
      <BackButton onClick={() => onSelect(null)} label="Quest log" />
      <div className="flex items-start gap-3">
        <StatusButton status={st} onChange={s => api.setQuestStatus(q.id, s)} size={22} />
        <div className="min-w-0 flex-1">
          <h2 className="font-display text-xl font-semibold leading-tight text-amber-50"><Spoiler active={q.spoiler}>{q.title}</Spoiler></h2>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            <Chip color={TYPE_COLOR[q.type]}>{q.type === "Requests" ? "Request" : q.type === "Errands" ? "Errand" : "Shenanigan"}</Chip>
            {spirit
              ? <button onClick={() => onSelect({ kind: "spirit", id: spirit.id }, true)}><Chip color="#fdba74" className="hover:brightness-125">{spirit.name}{idx >= 0 && ` · ${idx + 1}/${chain.length}`}</Chip></button>
              : q.giver && <Chip className="border-white/10 text-slate-300">From {q.giver}</Chip>}
            {q.repeatable && <Chip className="border-white/10 text-slate-300">Repeatable</Chip>}
            {q.number && <Chip className="border-white/10 text-slate-500">#{q.number}</Chip>}
          </div>
        </div>
      </div>

      <div className="mt-3 flex items-center gap-2 text-xs text-slate-400">
        <span>Status:</span>
        <Segmented value={st} onChange={s => api.setQuestStatus(q.id, s)} options={[{ value: "todo", label: "Not started" }, { value: "active", label: "In progress" }, { value: "done", label: "Completed" }]} />
      </div>

      <Spoiler active={q.spoiler} block className="mt-1">
        {q.description && <p className="mt-3 border-l-2 border-amber-200/30 pl-3 text-[13px] italic leading-relaxed text-slate-300">“{q.description}”</p>}
        {q.prereq && <p className="mt-2 text-[13px] text-slate-400"><b className="text-slate-300">Unlocks:</b> {q.prereq}</p>}

        <SectionTitle>Route on the map</SectionTitle>
        {q.waypoints.length > 0 ? (
          <ol className="relative space-y-1 pl-1">
            {q.waypoints.map((w, n) => {
              const pos = waypointPos(w);
              const isl = w.kind === "island" ? islandById.get(w.ref as string) : undefined;
              return (
                <li key={n} className="flex items-start gap-2">
                  <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[11px] font-bold text-slate-900" style={{ background: ROLE_COLORS[w.role] }}>{n + 1}</span>
                  <div className="min-w-0 flex-1">
                    <button className="text-left text-sm font-medium text-slate-100 hover:text-amber-100" onClick={() => isl && onSelect({ kind: "island", id: isl.id }, true)}>
                      {pos.label}
                    </button>
                    <span className="ml-1.5 text-[11px] uppercase tracking-wider" style={{ color: ROLE_COLORS[w.role] }}>{ROLE_LABEL[w.role]}</span>
                    {w.why && w.why !== "Quest location" && <div className="text-xs text-slate-400">{w.step > 0 ? `Step ${w.step}: ` : ""}{w.why}</div>}
                  </div>
                </li>
              );
            })}
          </ol>
        ) : (
          <div className="flex items-center gap-2 rounded-md border border-white/5 bg-white/[0.03] px-3 py-2 text-[13px] text-slate-400">
            <Ship size={14} className="shrink-0" />
            {q.onBoat ? "Takes place aboard Stella's boat, so there are no island pins." : q.type === "Errands" ? "Francis errands can be handed in at any of Francis's shops." : "No specific island; this can be done anywhere."}
          </div>
        )}

        {q.objectives.length > 0 && (
          <>
            <SectionTitle right={<span className="text-xs text-slate-500">{steps.length}/{q.objectives.length}</span>}>Objectives</SectionTitle>
            <ul className="space-y-1">
              {q.objectives.map((o, n) => (
                <li key={n} style={{ paddingLeft: (o.depth - 1) * 16 }}>
                  <label className={cn("flex cursor-pointer gap-2 rounded-md px-1 py-1 text-[13px] hover:bg-white/5", steps.includes(n) ? "text-slate-500 line-through" : "text-slate-200")}>
                    <input type="checkbox" className="mt-0.5 accent-emerald-400" checked={steps.includes(n)} onChange={() => api.toggleStep(q.id, n)} />
                    <span><span className="mr-1 text-slate-500">{n + 1}.</span>{o.text}</span>
                  </label>
                </li>
              ))}
            </ul>
          </>
        )}

        {q.rewards.length > 0 && (
          <>
            <SectionTitle>Rewards</SectionTitle>
            <ul className="space-y-0.5 text-[13px] text-slate-300">{q.rewards.map(r => <li key={r} className="flex items-center gap-1.5"><Gift size={12} className="text-amber-300" />{r}</li>)}</ul>
          </>
        )}

        {q.notes.length > 0 && (
          <>
            <SectionTitle>Notes &amp; tips</SectionTitle>
            <Lines lines={q.notes} />
          </>
        )}
      </Spoiler>

      {(q.prev.length > 0 || q.next.length > 0) && (
        <>
          <SectionTitle>Quest chain</SectionTitle>
          <div className="flex flex-col gap-1.5">
            {q.prev.map(id => { const p = questById.get(id)!; return (
              <button key={id} onClick={() => onSelect({ kind: "quest", id }, true)} className="flex items-center gap-2 rounded-md border border-white/5 px-3 py-1.5 text-left text-[13px] text-slate-300 hover:bg-white/5">
                <ArrowLeft size={13} className="text-slate-500" /> Previous: <Spoiler active={p.spoiler}>{p.title}</Spoiler>
              </button>); })}
            {q.next.map(id => { const n = questById.get(id)!; return (
              <button key={id} onClick={() => onSelect({ kind: "quest", id }, true)} className="flex items-center gap-2 rounded-md border border-white/5 px-3 py-1.5 text-left text-[13px] text-slate-300 hover:bg-white/5">
                Next: <Spoiler active={n.spoiler}>{n.title}</Spoiler> <ArrowRight size={13} className="ml-auto text-slate-500" />
              </button>); })}
          </div>
        </>
      )}
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/SpiritsPanel.tsx" << 'SPIRITFARER_EOF'
import { Fragment } from "react";
import { data, eventById, img, islandById, questById, spiritById } from "@/data";
import type { Selection } from "@/types";
import type { ProgressApi } from "@/store";
import { cn } from "@/utils/cn";
import { Spoiler } from "./Spoiler";
import { BackButton, Chip, Lines, SectionTitle, StatusButton, WikiImage } from "./ui";

interface Props { api: ProgressApi; selectedId: string | null; onSelect: (s: Selection, fly?: boolean) => void }

export default function SpiritsPanel({ api, selectedId, onSelect }: Props) {
  const s = selectedId ? spiritById.get(selectedId) : undefined;
  if (s) return <SpiritDetail id={s.id} api={api} onSelect={onSelect} />;
  return (
    <div>
      <p className="mb-3 text-xs leading-relaxed text-slate-400">The passengers you ferry. Pick one to see where they're found and their whole storyline on the map.</p>
      <div className="grid grid-cols-2 gap-2">
        {data.spirits.map(sp => {
          const done = sp.quests.filter(id => api.questStatus(id) === "done").length;
          const origin = sp.origin ? islandById.get(sp.origin) : undefined;
          return (
            <button key={sp.id} onClick={() => onSelect({ kind: "spirit", id: sp.id }, true)}
              className="flex items-center gap-2.5 rounded-lg border border-white/5 bg-white/[0.03] p-2 text-left hover:border-amber-200/20 hover:bg-white/5">
              <WikiImage src={img(sp.image)} alt={sp.name} className="h-11 w-11 shrink-0 rounded-full border border-white/10 bg-slate-800 object-cover object-top" />
              <span className="min-w-0">
                <span className="block truncate text-sm font-semibold text-slate-100">{sp.name}{sp.dlc && <span className="ml-1 text-[10px] font-normal text-teal-300">update</span>}</span>
                <span className="block truncate text-[11px] text-slate-400">{origin?.name ?? sp.originText ?? "-"}</span>
                <span className="mt-1 block h-1 w-full overflow-hidden rounded-full bg-slate-800"><span className="block h-full bg-emerald-400/70" style={{ width: `${sp.quests.length ? (done / sp.quests.length) * 100 : 0}%` }} /></span>
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function SpiritDetail({ id, api, onSelect }: { id: string; api: ProgressApi; onSelect: Props["onSelect"] }) {
  const s = spiritById.get(id)!;
  const origin = s.origin ? islandById.get(s.origin) : undefined;
  const events = data.events.filter(e => e.spirit === s.id);
  const rows: [string, string][] = ([
    ["Species", s.species], ["House", s.house], ["Favourite food", s.favouriteFood], ["Likes", s.likes],
    ["Dislikes", s.dislikes], ["Skills", s.skills], ["Spirit flower", s.flower],
  ] as [string, string][]).filter(([, v]) => v && v !== "None");

  return (
    <div>
      <BackButton onClick={() => onSelect(null)} label="All spirits" />
      <div className="flex items-start gap-3">
        <WikiImage src={img(s.image)} alt={s.name} className="h-28 w-24 shrink-0 rounded-lg border border-white/10 bg-slate-800/60 object-contain" />
        <div>
          <h2 className="font-display text-2xl font-semibold text-amber-50">{s.name}</h2>
          <div className="mt-1 flex flex-wrap gap-1.5">
            {s.dlc && <Chip color="#5eead4">Free update</Chip>}
            {origin
              ? <button onClick={() => onSelect({ kind: "island", id: origin.id }, true)}><Chip color="#fcd34d" className="hover:brightness-125">Found at {origin.name}</Chip></button>
              : s.originText && <Chip className="border-white/10 text-slate-300">{s.originText}</Chip>}
          </div>
          {s.originText && origin && s.originText !== origin.name && <p className="mt-1.5 text-xs text-slate-400">{s.originText}</p>}
        </div>
      </div>

      <dl className="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-[13px]">
        {rows.map(([k, v]) => <Fragment key={k}><dt className="text-slate-400">{k}</dt><dd className="text-slate-200">{v}</dd></Fragment>)}
      </dl>

      {events.length > 0 && (
        <>
          <SectionTitle>Event</SectionTitle>
          <div className="flex flex-wrap gap-1.5">
            {events.map(e => <button key={e.id} onClick={() => onSelect({ kind: "event", id: e.id }, true)}><Chip color="#93c5fd" className="hover:brightness-125">{eventById.get(e.id)!.name} · {e.resource}</Chip></button>)}
          </div>
        </>
      )}

      <SectionTitle right={<span className="text-xs text-slate-500">{s.quests.filter(q => api.questStatus(q) === "done").length}/{s.quests.length} done</span>}>Storyline</SectionTitle>
      <ol className="space-y-0.5">
        {s.quests.map((qid, n) => {
          const q = questById.get(qid)!;
          const st = api.questStatus(qid);
          return (
            <li key={qid} className="flex items-center gap-2 rounded-md px-1 py-1 hover:bg-white/5">
              <span className="w-4 text-right text-[11px] text-slate-500">{n + 1}</span>
              <StatusButton status={st} onChange={v => api.setQuestStatus(qid, v)} size={16} />
              <button onClick={() => onSelect({ kind: "quest", id: qid }, true)} className={cn("min-w-0 flex-1 truncate text-left text-[13px]", st === "done" ? "text-slate-500" : "text-slate-100 hover:text-amber-100")}>
                <Spoiler active={q.spoiler}>{q.title}</Spoiler>
              </button>
              {q.waypoints.length > 0 && <span className="text-[11px] text-slate-500">{q.waypoints.map(w => typeof w.ref === "string" ? islandById.get(w.ref)?.name : "coords").filter((v, i, a) => a.indexOf(v) === i).slice(0, 2).join(", ")}</span>}
            </li>
          );
        })}
      </ol>

      {s.about.length > 0 && <><SectionTitle>About</SectionTitle><Lines lines={s.about} /></>}
      {s.life.length > 0 && <><SectionTitle>Life story</SectionTitle><Spoiler block><Lines lines={s.life} /></Spoiler></>}
      {s.everdoor.length > 0 && <><SectionTitle>At the Everdoor</SectionTitle><Spoiler block><Lines lines={s.everdoor} /></Spoiler></>}
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/Spoiler.tsx" << 'SPIRITFARER_EOF'
import { createContext, useContext, useState, type ReactNode } from "react";
import { cn } from "@/utils/cn";

export const SpoilerContext = createContext(false);

/** Blurs story-sensitive content until clicked, unless spoilers are globally enabled. */
export function Spoiler({ children, active = true, block = false, className }: { children: ReactNode; active?: boolean; block?: boolean; className?: string }) {
  const showAll = useContext(SpoilerContext);
  const [revealed, setRevealed] = useState(false);
  if (!active || showAll || revealed) return <>{children}</>;
  const Tag = block ? "div" : "span";
  return (
    <Tag
      role="button"
      tabIndex={0}
      title="Spoiler: click to reveal"
      onClick={e => { e.stopPropagation(); setRevealed(true); }}
      onKeyDown={e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); setRevealed(true); } }}
      className={cn("relative cursor-pointer select-none rounded", block && "block", className)}
    >
      <span className="pointer-events-none blur-[5px] opacity-70" aria-hidden>{children}</span>
      <span className={cn("absolute inset-0 flex items-center font-semibold uppercase tracking-wider text-amber-200/90", block ? "justify-center text-[11px]" : "justify-start text-[10px]")}>
        {block ? "Spoiler · click to reveal" : "Spoiler"}
      </span>
    </Tag>
  );
}
SPIRITFARER_EOF

cat > "src/components/WorldMap.tsx" << 'SPIRITFARER_EOF'
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import {
  Brain, Bug, CloudLightning, Coffee, Droplets, LocateFixed, Minus, Orbit, Pickaxe, Plus, Shell, Sparkle, Sun,
  type LucideIcon,
} from "lucide-react";
import { data, eventById, img, islandById, questById, REGION_COLORS, ROLE_COLORS, ROLE_LABEL, SECRET_ISLANDS, spiritById, waypointPos } from "@/data";
import type { Island, Quest, SeaEvent, Selection } from "@/types";
import type { ProgressApi, Settings } from "@/store";

const B = data.worldMap.bounds;
const VB = { x: B.x0, y: -B.yTop, w: B.x1 - B.x0, h: B.yTop - B.yBottom };
const MIN_K = 0.9, MAX_K = 10;
// The wiki map is 3384×2542 (8.6 MP). Phones can silently fail to paint an image that large inside a scaled SVG,
// so touch devices get the wiki's 2048 px rendition (3.1 MP) instead.
const WIKI_BG = img(data.worldMap.url) +
  (typeof matchMedia !== "undefined" && matchMedia("(pointer: coarse)").matches ? "/scale-to-width-down/2048" : "");

export const EVENT_STYLE: Record<string, { icon: LucideIcon; color: string }> = {
  jellyfish: { icon: Droplets, color: "#86efac" },
  thunderstorm: { icon: CloudLightning, color: "#fde047" },
  "severe-thunderstorm": { icon: CloudLightning, color: "#f87171" },
  dragon: { icon: Pickaxe, color: "#e2e8f0" },
  "gold-dragon": { icon: Pickaxe, color: "#facc15" },
  "turtle-sisters": { icon: Shell, color: "#5eead4" },
  "meteor-shower": { icon: Orbit, color: "#93c5fd" },
  fireflies: { icon: Sparkle, color: "#fb923c" },
  "nebula-pillbugs": { icon: Bug, color: "#c4b5fd" },
  "pulsar-rays": { icon: Sun, color: "#f0abfc" },
  "deadly-pulsar-rays": { icon: Sun, color: "#f43f5e" },
  "mind-palace": { icon: Brain, color: "#f9a8d4" },
  "vending-machine": { icon: Coffee, color: "#fcd34d" },
};
export function eventStyle(e: SeaEvent) {
  if (EVENT_STYLE[e.id]) return EVENT_STYLE[e.id];
  if (e.id.startsWith("jellyfish")) return EVENT_STYLE.jellyfish;
  if (e.id.endsWith("dragon")) return EVENT_STYLE.dragon;
  return { icon: Sparkle, color: "#e5e7eb" };
}

/** Deterministic organic island outline around (0,0). */
function islandPath(id: string, r: number) {
  let h = 2166136261;
  for (const c of id) h = Math.imul(h ^ c.charCodeAt(0), 16777619);
  const rnd = () => ((h = Math.imul(h ^ (h >>> 13), 1274126177)) >>> 0) / 4294967296;
  const n = 9, pts: [number, number][] = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2, rr = r * (0.72 + rnd() * 0.5);
    pts.push([Math.cos(a) * rr * 1.25, Math.sin(a) * rr * 0.85]);
  }
  const mid = (a: [number, number], b: [number, number]) => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
  let d = `M${mid(pts[n - 1], pts[0]).join(",")}`;
  for (let i = 0; i < n; i++) d += ` Q${pts[i].join(",")} ${mid(pts[i], pts[(i + 1) % n]).join(",")}`;
  return d + "Z";
}

interface Tip { x: number; y: number; content: ReactNode }

interface Props {
  settings: Settings;
  api: ProgressApi;
  selection: Selection;
  onSelect: (s: Selection) => void;
  focusKey: number;
}

export default function WorldMap({ settings, api, selection, onSelect, focusKey }: Props) {
  const svgRef = useRef<SVGSVGElement>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [view, setView] = useState({ k: 1, tx: 0, ty: 0 });
  const viewRef = useRef(view);
  viewRef.current = view;
  const [tip, setTip] = useState<Tip | null>(null);
  const [bgFailed, setBgFailed] = useState(false);
  const bgLoaded = useRef(false);
  // Retry each time the wiki background is picked, and fall back to the chart if the image never arrives.
  useEffect(() => {
    if (settings.background !== "wiki") return;
    setBgFailed(false);
    if (bgLoaded.current) return;
    const t = setTimeout(() => { if (!bgLoaded.current) setBgFailed(true); }, 20000);
    return () => clearTimeout(t);
  }, [settings.background]);
  const drag = useRef<{ x: number; y: number; tx: number; ty: number; moved: boolean } | null>(null);
  const anim = useRef<number>(0);
  const { layers, showSpoilers } = settings;
  const ps = 1 / Math.pow(view.k, 0.8); // pin scale: pins grow gently while zooming in

  const toViewBox = useCallback((cx: number, cy: number) => {
    const svg = svgRef.current!;
    const pt = svg.createSVGPoint(); pt.x = cx; pt.y = cy;
    return pt.matrixTransform(svg.getScreenCTM()!.inverse());
  }, []);

  const animateTo = useCallback((target: { k: number; tx: number; ty: number }) => {
    cancelAnimationFrame(anim.current);
    const start = performance.now(), from = viewRef.current;
    const step = (t: number) => {
      const p = Math.min(1, (t - start) / 420), e = 1 - Math.pow(1 - p, 3);
      setView({ k: from.k + (target.k - from.k) * e, tx: from.tx + (target.tx - from.tx) * e, ty: from.ty + (target.ty - from.ty) * e });
      if (p < 1) anim.current = requestAnimationFrame(step);
    };
    anim.current = requestAnimationFrame(step);
  }, []);

  /** Zoom/pan so that the given game-coordinate points are framed. */
  const frame = useCallback((pts: { x: number; y: number }[]) => {
    if (!pts.length) return;
    const xs = pts.map(p => p.x), ys = pts.map(p => -p.y);
    const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys);
    const w = Math.max(maxX - minX, 40), h = Math.max(maxY - minY, 40);
    const k = Math.max(MIN_K, Math.min(5, Math.min(VB.w / (w * 1.6), VB.h / (h * 1.6))));
    const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    animateTo({ k, tx: VB.x + VB.w / 2 - cx * k, ty: VB.y + VB.h / 2 - cy * k });
  }, [animateTo]);

  // Frame the selection whenever the app asks (focusKey bumps on explicit "show on map").
  useEffect(() => {
    if (!selection) return;
    if (selection.kind === "island") { const i = islandById.get(selection.id); if (i) frame([{ x: i.x - 25, y: i.y }, { x: i.x + 25, y: i.y }]); }
    if (selection.kind === "quest") { const q = questById.get(selection.id); if (q) frame(q.waypoints.map(waypointPos)); }
    if (selection.kind === "event") { const e = eventById.get(selection.id); if (e) frame(e.points.length > 1 ? e.points : e.points.flatMap(p => [{ x: p.x - 25, y: p.y }, { x: p.x + 25, y: p.y }])); }
    if (selection.kind === "spirit") {
      const s = spiritById.get(selection.id);
      const pts = (s?.quests ?? []).flatMap(id => questById.get(id)?.waypoints.map(waypointPos) ?? []);
      const o = s?.origin ? islandById.get(s.origin) : undefined;
      if (o) pts.push({ x: o.x, y: o.y, label: o.name });
      frame(pts);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [focusKey]);

  // Wheel zoom around the cursor (non-passive so the page doesn't scroll).
  useEffect(() => {
    const svg = svgRef.current!;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      cancelAnimationFrame(anim.current);
      const v = toViewBox(e.clientX, e.clientY);
      setView(cur => {
        const k = Math.max(MIN_K, Math.min(MAX_K, cur.k * Math.exp(-e.deltaY * 0.0015)));
        return { k, tx: v.x - (v.x - cur.tx) * (k / cur.k), ty: v.y - (v.y - cur.ty) * (k / cur.k) };
      });
    };
    svg.addEventListener("wheel", onWheel, { passive: false });
    return () => svg.removeEventListener("wheel", onWheel);
  }, [toViewBox]);

  const zoomBy = (f: number) => {
    const c = { x: VB.x + VB.w / 2, y: VB.y + VB.h / 2 };
    const k = Math.max(MIN_K, Math.min(MAX_K, view.k * f));
    animateTo({ k, tx: c.x - (c.x - view.tx) * (k / view.k), ty: c.y - (c.y - view.ty) * (k / view.k) });
  };

  // ── Pointer gestures: one pointer pans, two pointers pinch-zoom + pan, double-tap zooms in.
  // Hover tooltips are mouse-only; on touch a tap selects and the side panel shows the details.
  const pointers = useRef(new Map<number, { x: number; y: number }>());
  const pinch = useRef<{ dist: number; wx: number; wy: number; k: number } | null>(null);
  const lastTap = useRef({ t: 0, x: 0, y: 0 });

  const startPinch = () => {
    const [a, b] = [...pointers.current.values()];
    const m = toViewBox((a.x + b.x) / 2, (a.y + b.y) / 2), v = viewRef.current;
    // Remember the map point under the fingers' midpoint so it stays there while zooming.
    pinch.current = { dist: Math.hypot(a.x - b.x, a.y - b.y) || 1, wx: (m.x - v.tx) / v.k, wy: (m.y - v.ty) / v.k, k: v.k };
  };

  const onPointerDown = (e: React.PointerEvent) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    cancelAnimationFrame(anim.current);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 1) {
      drag.current = { x: e.clientX, y: e.clientY, tx: viewRef.current.tx, ty: viewRef.current.ty, moved: false };
      return;
    }
    // Second finger down: switch to pinching. Mark as moved so the gesture never counts as a tap.
    const svg = e.currentTarget as Element;
    for (const id of pointers.current.keys()) if (!svg.hasPointerCapture(id)) svg.setPointerCapture(id);
    if (drag.current) drag.current.moved = true;
    else drag.current = { x: e.clientX, y: e.clientY, tx: viewRef.current.tx, ty: viewRef.current.ty, moved: true };
    startPinch();
    setTip(null);
  };
  const onPointerMove = (e: React.PointerEvent) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    const pz = pinch.current;
    if (pz && pointers.current.size >= 2) {
      const [a, b] = [...pointers.current.values()];
      const m = toViewBox((a.x + b.x) / 2, (a.y + b.y) / 2);
      const k = Math.max(MIN_K, Math.min(MAX_K, pz.k * Math.hypot(a.x - b.x, a.y - b.y) / pz.dist));
      setView({ k, tx: m.x - pz.wx * k, ty: m.y - pz.wy * k });
      return;
    }
    const d = drag.current;
    if (!d) return;
    if (!d.moved && Math.hypot(e.clientX - d.x, e.clientY - d.y) < (e.pointerType === "mouse" ? 4 : 8)) return;
    if (!d.moved) { d.moved = true; (e.currentTarget as Element).setPointerCapture(e.pointerId); }
    const a = toViewBox(d.x, d.y), b = toViewBox(e.clientX, e.clientY);
    setView(v => ({ ...v, tx: d.tx + (b.x - a.x), ty: d.ty + (b.y - a.y) }));
    setTip(null);
  };
  const onPointerUp = (e: React.PointerEvent) => {
    if (!pointers.current.delete(e.pointerId)) return;
    const left = [...pointers.current.values()];
    if (left.length >= 2) { startPinch(); return; }
    if (left.length === 1) {
      // Lifted one finger of a pinch: keep panning with the other one, from where it is now.
      pinch.current = null;
      drag.current = { x: left[0].x, y: left[0].y, tx: viewRef.current.tx, ty: viewRef.current.ty, moved: true };
      return;
    }
    pinch.current = null;
    if (e.type === "pointerup" && drag.current && !drag.current.moved) {
      const now = performance.now(), lt = lastTap.current;
      if (now - lt.t < 320 && Math.hypot(e.clientX - lt.x, e.clientY - lt.y) < 30) {
        lastTap.current = { t: 0, x: 0, y: 0 };
        const v = toViewBox(e.clientX, e.clientY), cur = viewRef.current;
        const k = Math.min(MAX_K, cur.k * 2);
        animateTo({ k, tx: v.x - (v.x - cur.tx) * (k / cur.k), ty: v.y - (v.y - cur.ty) * (k / cur.k) });
      } else lastTap.current = { t: now, x: e.clientX, y: e.clientY };
    }
    endDrag();
  };
  const endDrag = () => { setTimeout(() => { drag.current = null; }, 0); };
  const click = (s: Selection) => (e: React.MouseEvent) => {
    e.stopPropagation();
    if (drag.current?.moved) return;
    onSelect(s);
  };

  const showTip = (content: ReactNode) => (e: React.PointerEvent) => {
    if (drag.current?.moved || e.pointerType !== "mouse") return;
    const r = wrapRef.current!.getBoundingClientRect();
    setTip({ x: e.clientX - r.left, y: e.clientY - r.top, content });
  };
  const hideTip = () => setTip(null);

  const selectedQuest = selection?.kind === "quest" ? questById.get(selection.id) : undefined;
  const selectedSpirit = selection?.kind === "spirit" ? spiritById.get(selection.id) : undefined;

  const activeQuests = useMemo(
    () => data.quests.filter(q => api.questStatus(q.id) === "active" && q.id !== selectedQuest?.id && q.waypoints.length),
    [api, selectedQuest],
  );

  const hidden = (i: Island) => SECRET_ISLANDS.has(i.id) && !showSpoilers && !api.progress.islands[i.id]?.visited;
  const islandLabel = (i: Island) => (hidden(i) ? "???" : i.name);
  const islandHighlighted = (i: Island) =>
    (selection?.kind === "island" && selection.id === i.id) ||
    (selectedSpirit && selectedSpirit.origin === i.id);

  // ── Layers ────────────────────────────────────────────────────────────────
  const chart = (
    <g>
      <defs>
        <radialGradient id="sea" cx="45%" cy="55%" r="75%">
          <stop offset="0%" stopColor="#1c3f5a" />
          <stop offset="60%" stopColor="#14304a" />
          <stop offset="100%" stopColor="#0b1c2e" />
        </radialGradient>
        <radialGradient id="everdoor-glow">
          <stop offset="0%" stopColor="#fff4d6" stopOpacity="0.95" />
          <stop offset="25%" stopColor="#f6a76b" stopOpacity="0.6" />
          <stop offset="100%" stopColor="#c2410c" stopOpacity="0" />
        </radialGradient>
        <filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="9" /></filter>
        <pattern id="waves" width="16" height="10" patternUnits="userSpaceOnUse">
          <path d="M0 6 Q4 3 8 6 T16 6" fill="none" stroke="#9ec9e0" strokeOpacity="0.07" strokeWidth="0.6" />
        </pattern>
      </defs>
      <rect x={VB.x - 400} y={VB.y - 400} width={VB.w + 800} height={VB.h + 800} fill="url(#sea)" />
      <rect x={VB.x - 400} y={VB.y - 400} width={VB.w + 800} height={VB.h + 800} fill="url(#waves)" />
      <g filter="url(#soft)" opacity="0.32">
        {data.islands.filter(i => i.region !== "Everdoor" && !SECRET_ISLANDS.has(i.id)).map(i => (
          <circle key={i.id} cx={i.x} cy={-i.y} r={34} fill={REGION_COLORS[i.region]} />
        ))}
      </g>
      <circle cx={0} cy={0} r={46} fill="#7f1d1d" opacity={0.25} filter="url(#soft)" />
      <circle cx={0} cy={0} r={22} fill="url(#everdoor-glow)" />
    </g>
  );

  const wikiBg = (
    <g>
      <rect x={VB.x - 400} y={VB.y - 400} width={VB.w + 800} height={VB.h + 800} fill="#0b0b0b" />
      <image
        href={WIKI_BG} x={B.x0} y={-B.yTop} width={B.x1 - B.x0} height={B.yTop - B.yBottom}
        preserveAspectRatio="none" onLoad={() => { bgLoaded.current = true; }} onError={() => setBgFailed(true)}
      />
    </g>
  );

  const grid = layers.grid && (
    <g pointerEvents="none">
      {Array.from({ length: 13 }, (_, n) => -250 + n * 50).map(v => (
        <g key={v}>
          <line x1={v} x2={v} y1={-260} y2={190} stroke="#cfe3ef" strokeOpacity={v === 0 ? 0.18 : 0.06} strokeWidth={0.4 * ps} />
          <line x1={-240} x2={340} y1={-v} y2={-v} stroke="#cfe3ef" strokeOpacity={v === 0 ? 0.18 : 0.06} strokeWidth={0.4 * ps} />
          {v >= -200 && v <= 300 && <text x={v + 1.5 * ps} y={-B.yTop + 9 * ps} fontSize={5 * ps} fill="#cfe3ef" opacity={0.35}>{v}</text>}
          {v >= -150 && v <= 240 && <text x={B.x0 + 2 * ps} y={-v - 1.5 * ps} fontSize={5 * ps} fill="#cfe3ef" opacity={0.35}>{v}</text>}
        </g>
      ))}
    </g>
  );

  const islandsLayer = layers.islands && (
    <g>
      {data.islands.map(i => {
        const hi = islandHighlighted(i);
        const visited = api.progress.islands[i.id]?.visited;
        const col = REGION_COLORS[i.region];
        const qs = data.quests.filter(q => q.waypoints.some(w => w.ref === i.id));
        const done = settings.dimDone && visited && qs.length > 0 && qs.every(q => api.questStatus(q.id) === "done");
        const s = 4.6 * ps;
        return (
          <g
            key={i.id} transform={`translate(${i.x},${-i.y})`} className="cursor-pointer"
            opacity={done ? 0.55 : 1}
            onClick={click({ kind: "island", id: i.id })}
            onPointerEnter={showTip(<IslandTip i={i} hidden={hidden(i)} />)} onPointerMove={showTip(<IslandTip i={i} hidden={hidden(i)} />)} onPointerLeave={hideTip}
          >
            <circle r={s * 2} fill="transparent" /> {/* generous tap target for fingers */}
            {hi && <circle r={s * 2.4} fill="none" stroke="#fde68a" strokeWidth={1.2 * ps} className="animate-pulse" />}
            {settings.background === "chart" && i.id !== "everdoor" && (
              <path d={islandPath(i.id, s * 1.25)} fill={hidden(i) ? "#334155" : "#e9d8b4"} stroke={col} strokeWidth={0.9 * ps} />
            )}
            {i.id === "everdoor" ? (
              <circle r={s * 1.05} fill="#fff7e6" stroke="#f97316" strokeWidth={1 * ps} />
            ) : (
              <circle r={s * 0.55} fill={col} stroke="#0f172a" strokeWidth={0.6 * ps} />
            )}
            {visited && <path d={`M${-1.4 * ps},${-0.1 * ps} l${1 * ps},${1 * ps} l${2 * ps},${-2.2 * ps}`} transform={`translate(${s * 1.25},${-s * 0.9})`} fill="none" stroke="#4ade80" strokeWidth={1.1 * ps} strokeLinecap="round" />}
            {layers.labels && (
              <text
                y={s * 2.1} textAnchor="middle" fontSize={6.8 * ps} className="font-hand select-none"
                fill={hi ? "#fde68a" : "#fdf6e3"} stroke="#0b1622" strokeWidth={1.6 * ps} paintOrder="stroke" fontWeight={600}
              >{islandLabel(i)}</text>
            )}
          </g>
        );
      })}
    </g>
  );

  const shrineLayer = layers.shrines && (
    <g>
      {data.abilities.filter(a => a.island).map(a => {
        const i = islandById.get(a.island!)!;
        if (hidden(i)) return null;
        const s = 2.6 * ps;
        return (
          <g key={a.name} transform={`translate(${i.x - 6.2 * ps},${-i.y - 5.6 * ps})`}
            onPointerEnter={showTip(<div><b className="text-violet-200">Shrine · {a.name}</b><div className="text-slate-300">{a.controls}</div><div className="text-slate-400 text-[11px] mt-1">Costs 2 Obols · {a.unlock}</div></div>)}
            onPointerLeave={hideTip} onClick={click({ kind: "island", id: i.id })} className="cursor-pointer">
            <path d={`M0,${-s} L${s * 0.8},0 L0,${s} L${-s * 0.8},0Z`} fill="#c4b5fd" stroke="#2e1065" strokeWidth={0.5 * ps} />
          </g>
        );
      })}
    </g>
  );

  const busLayer = layers.busStops && (
    <g>
      {data.busStops.map(b => (
        <g key={`${b.x},${b.y}`} transform={`translate(${b.x},${-b.y})`}
          onPointerEnter={showTip(<div><b className="text-sky-200">Bus Stop</b> <span className="text-slate-400">({b.x}, {b.y})</span><div className="text-slate-300">Alex the seal fast-travels you between discovered stops.</div><div className="text-slate-400 text-[11px]">Nearest: {b.near.map(n => islandById.get(n)?.name).join(", ")}</div></div>)}
          onPointerLeave={hideTip}>
          <rect x={-2.2 * ps} y={-2.2 * ps} width={4.4 * ps} height={4.4 * ps} rx={1 * ps} fill="#38bdf8" stroke="#082f49" strokeWidth={0.5 * ps} />
          <text y={1.3 * ps} textAnchor="middle" fontSize={3.6 * ps} fontWeight={700} fill="#082f49" className="select-none">B</text>
        </g>
      ))}
    </g>
  );

  const treasureLayer = layers.treasures && (
    <g>
      {data.treasures.map(t => (
        <g key={`${t.x},${t.y}`} transform={`translate(${t.x},${-t.y})`}
          onPointerEnter={showTip(<div><b className="text-amber-200">Treasure map · {t.reward}</b> <span className="text-slate-400">({t.x}, {t.y})</span><div className="text-slate-300 max-w-xs">{t.source}</div></div>)}
          onPointerLeave={hideTip}>
          <path d={`M${-2.4 * ps},${-2.4 * ps} L${2.4 * ps},${2.4 * ps} M${2.4 * ps},${-2.4 * ps} L${-2.4 * ps},${2.4 * ps}`} stroke="#b91c1c" strokeWidth={1.4 * ps} strokeLinecap="round" />
        </g>
      ))}
    </g>
  );

  const eventsLayer = layers.events && (
    <g>
      {data.events.filter(e => e.trigger !== "manual").flatMap(e => e.points.map((p, n) => {
        const st = eventStyle(e);
        const sel = selection?.kind === "event" && selection.id === e.id;
        const atIsland = e.trigger === "island";
        const s = (sel ? 8.5 : 6.6) * ps;
        const ox = atIsland ? 7 * ps : 0, oy = atIsland ? -7 * ps : 0;
        const Icon = st.icon;
        const tipC = <EventTip e={e} label={p.label} />;
        return (
          <g key={`${e.id}-${n}`} transform={`translate(${p.x + ox},${-p.y + oy})`} className="cursor-pointer"
            onClick={click({ kind: "event", id: e.id })} onPointerEnter={showTip(tipC)} onPointerMove={showTip(tipC)} onPointerLeave={hideTip}>
            {e.approx && <circle r={s * 1.6} fill={st.color} opacity={0.12} />}
            <circle r={s * 0.75} fill="#0f172a" fillOpacity={0.85} stroke={st.color} strokeWidth={(sel ? 1.2 : 0.6) * ps} strokeDasharray={e.approx ? `${1.2 * ps} ${0.8 * ps}` : undefined} />
            <Icon x={-s / 2} y={-s / 2} width={s} height={s} color={st.color} strokeWidth={2.2} />
          </g>
        );
      }))}
    </g>
  );

  const questPins = (q: Quest, faint: boolean) => {
    const pts = q.waypoints.map(waypointPos);
    const counts = new Map<string, number>();
    const offsets = pts.map(p => { const key = `${p.x},${p.y}`; const n = counts.get(key) ?? 0; counts.set(key, n + 1); return n; });
    const steps = api.questSteps(q.id);
    let d = "";
    pts.forEach((p, n) => {
      if (n === 0) { d = `M${p.x},${-p.y}`; return; }
      const a = pts[n - 1];
      const mx = (a.x + p.x) / 2, my = -(a.y + p.y) / 2, dx = p.x - a.x, dy = -(p.y - a.y);
      const len = Math.hypot(dx, dy) || 1, bend = Math.min(30, len * 0.18) + (len < 1 ? 18 : 0);
      d += ` Q${mx - (dy / len) * bend + (len < 1 ? 14 : 0)},${my + (dx / len) * bend - (len < 1 ? 14 : 0)} ${p.x},${-p.y}`;
    });
    return (
      <g key={q.id} opacity={faint ? 0.75 : 1}>
        {pts.length > 1 && (
          <path d={d} fill="none" stroke={faint ? "#fbbf24" : "#fde68a"} strokeOpacity={faint ? 0.45 : 0.9}
            strokeWidth={(faint ? 0.8 : 1.5) * ps} strokeDasharray={`${3 * ps} ${2 * ps}`} markerMid="url(#arrow)" markerEnd="url(#arrow)" />
        )}
        {q.waypoints.map((w, n) => {
          const p = pts[n], s = (faint ? 3.4 : 5.2) * ps;
          const done = w.step > 0 && steps.includes(w.step - 1);
          const ox = offsets[n] * s * 1.9;
          const tipC = <div><div className="text-[11px] uppercase tracking-wider" style={{ color: ROLE_COLORS[w.role] }}>{ROLE_LABEL[w.role]} · {p.label}</div><b>{q.title}</b>{w.why && <div className="text-slate-300 max-w-xs">{w.step > 0 ? `Step ${w.step}: ` : ""}{w.why}</div>}</div>;
          return (
            <g key={n} transform={`translate(${p.x + ox + (faint ? 0 : 5.5 * ps)},${-p.y - (faint ? 4 * ps : 9.5 * ps)})`} className="cursor-pointer"
              onClick={click({ kind: "quest", id: q.id })} onPointerEnter={showTip(tipC)} onPointerMove={showTip(tipC)} onPointerLeave={hideTip}>
              <path d={`M0,${s * 1.25} L${-s * 0.55},${s * 0.35} A${s * 0.9},${s * 0.9} 0 1 1 ${s * 0.55},${s * 0.35}Z`} transform={`translate(0,${-s * 0.25})`}
                fill={done ? "#475569" : ROLE_COLORS[w.role]} stroke="#0f172a" strokeWidth={0.6 * ps} />
              {!faint && <text y={-s * 0.05} textAnchor="middle" fontSize={s * 0.95} fontWeight={800} fill="#0f172a" className="select-none">{n + 1}</text>}
            </g>
          );
        })}
      </g>
    );
  };

  return (
    <div ref={wrapRef} className="relative h-full w-full overflow-hidden bg-[#0b1622]" onPointerLeave={hideTip}>
      <svg
        ref={svgRef} viewBox={`${VB.x} ${VB.y} ${VB.w} ${VB.h}`} className="h-full w-full touch-none select-none"
        onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={onPointerUp}
        onClick={() => { if (!drag.current?.moved) onSelect(null); }}
        style={{ cursor: drag.current?.moved ? "grabbing" : "grab" }}
      >
        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse">
            <path d="M0,1 L9,5 L0,9 z" fill="#fde68a" />
          </marker>
        </defs>
        <g transform={`translate(${view.tx},${view.ty}) scale(${view.k})`}>
          {settings.background === "wiki" && !bgFailed ? wikiBg : chart}
          {grid}
          {treasureLayer}
          {busLayer}
          {islandsLayer}
          {shrineLayer}
          {eventsLayer}
          {layers.activeQuests && activeQuests.map(q => questPins(q, true))}
          {selectedQuest && questPins(selectedQuest, false)}
          {selectedSpirit && selectedSpirit.quests.map(id => questById.get(id)).filter((q): q is Quest => !!q && q.waypoints.length > 0 && q.id !== selectedQuest?.id).map(q => questPins(q, true))}
        </g>
      </svg>

      {/* Zoom controls */}
      <div className="absolute bottom-3 right-3 flex flex-col overflow-hidden rounded-lg border border-white/10 bg-slate-900/80 shadow-lg backdrop-blur sm:bottom-4 sm:right-4">
        <button className="p-2.5 text-slate-200 hover:bg-white/10 pointer-fine:p-2" onClick={() => zoomBy(1.5)} title="Zoom in" aria-label="Zoom in"><Plus size={16} /></button>
        <button className="p-2.5 text-slate-200 hover:bg-white/10 pointer-fine:p-2" onClick={() => zoomBy(1 / 1.5)} title="Zoom out" aria-label="Zoom out"><Minus size={16} /></button>
        <button className="p-2.5 text-slate-200 hover:bg-white/10 pointer-fine:p-2" onClick={() => animateTo({ k: 1, tx: 0, ty: 0 })} title="Reset view" aria-label="Reset view"><LocateFixed size={16} /></button>
      </div>
      {settings.background === "wiki" && bgFailed && (
        <div className="absolute left-1/2 top-3 -translate-x-1/2 rounded-md bg-amber-900/90 px-3 py-1.5 text-xs text-amber-100">
          Couldn't load the wiki map image (offline?). Showing the drawn chart instead.
        </div>
      )}
      <Legend />
      {tip && (
        <div className="pointer-events-none absolute z-20 max-w-sm rounded-lg border border-white/10 bg-slate-950/95 px-3 py-2 text-xs text-slate-100 shadow-xl"
          style={{ left: Math.max(8, Math.min(tip.x + 14, (wrapRef.current?.clientWidth ?? 0) - 300)), top: tip.y + 14 }}>
          {tip.content}
        </div>
      )}
    </div>
  );
}

function IslandTip({ i, hidden }: { i: Island; hidden: boolean }) {
  if (hidden) return <div><b>Unknown location</b><div className="text-slate-400">A secret place, found with a treasure map or quest. Turn on spoilers to reveal.</div></div>;
  const qs = data.quests.filter(q => q.waypoints.some(w => w.ref === i.id)).length;
  return (
    <div className="space-y-0.5">
      <div className="font-display text-sm font-semibold" style={{ color: REGION_COLORS[i.region] }}>{i.name}</div>
      <div className="text-slate-400">{i.region} · ({i.x}, {i.y})</div>
      {i.spirits.length > 0 && <div>Spirit: <span className="text-amber-200">{i.spirits.join(", ")}</span></div>}
      {i.requirements.length > 0 && <div className="text-rose-200">Requires: {i.requirements.join(", ")}</div>}
      <div className="text-slate-300">{i.chests.length} chests · {qs} quests</div>
    </div>
  );
}

function EventTip({ e, label }: { e: SeaEvent; label: string }) {
  const s = e.spirit ? spiritById.get(e.spirit) : undefined;
  return (
    <div className="space-y-0.5">
      <div className="font-display text-sm font-semibold" style={{ color: eventStyle(e).color }}>{e.name}{label && label !== e.name ? ` · ${label}` : ""}</div>
      {s && <div>With <span className="text-amber-200">{s.name}</span> aboard</div>}
      {e.resource && <div className="text-slate-300">Reward: {e.resource}</div>}
      {e.requires && <div className="text-rose-200">Requires: {e.requires}</div>}
      {e.approx && <div className="text-slate-400 text-[11px]">Approximate area (from the community map)</div>}
    </div>
  );
}

function Legend() {
  const [open, setOpen] = useState(false);
  return (
    <div className="absolute bottom-3 left-3 flex max-h-[calc(100%-1.5rem)] max-w-[min(20rem,calc(100%-4.5rem))] flex-col rounded-lg border border-white/10 bg-slate-900/85 text-xs text-slate-200 shadow-lg backdrop-blur sm:bottom-4 sm:left-4">
      <button className="w-full shrink-0 px-3 py-2 text-left font-semibold hover:bg-white/5 pointer-fine:py-1.5" onClick={() => setOpen(o => !o)}>{open ? "▾" : "▸"} Legend</button>
      {open && (
        <div className="grid min-h-0 grid-cols-2 gap-x-4 gap-y-1 overflow-y-auto px-3 pb-3">
          {Object.entries(REGION_COLORS).map(([r, c]) => (
            <div key={r} className="flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full" style={{ background: c }} />{r}</div>
          ))}
          {(["start", "mid", "end", "single"] as const).map(r => (
            <div key={r} className="flex items-center gap-1.5"><span className="h-2.5 w-2.5 rotate-45 rounded-sm" style={{ background: ROLE_COLORS[r] }} />Quest {ROLE_LABEL[r].toLowerCase()}</div>
          ))}
          <div className="flex items-center gap-1.5"><span className="h-2.5 w-2.5 rotate-45 bg-violet-300" />Shrine</div>
          <div className="flex items-center gap-1.5"><span className="flex h-3 w-3 items-center justify-center rounded-sm bg-sky-400 text-[8px] font-bold text-sky-950">B</span>Bus stop</div>
          <div className="flex items-center gap-1.5"><span className="font-bold text-red-600">✕</span>Treasure map spot</div>
          <div className="flex items-center gap-1.5"><span className="text-green-400">✓</span>Visited</div>
          <div className="col-span-2 mt-1 text-slate-400">Dashed event rings = approximate area. Coordinates match the in-game map.</div>
        </div>
      )}
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/components/ui.tsx" << 'SPIRITFARER_EOF'
import type { ReactNode } from "react";
import { ChevronLeft, Circle, CircleCheck, CircleDot } from "lucide-react";
import { cn } from "@/utils/cn";
import type { QuestStatus } from "@/types";

export function SectionTitle({ children, right }: { children: ReactNode; right?: ReactNode }) {
  return (
    <div className="mb-1.5 mt-4 flex items-center justify-between">
      <h3 className="font-display text-[13px] font-semibold uppercase tracking-wider text-amber-200/80">{children}</h3>
      {right}
    </div>
  );
}

export function Chip({ children, color, className, title }: { children: ReactNode; color?: string; className?: string; title?: string }) {
  return (
    <span title={title} className={cn("inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] leading-tight", className)}
      style={color ? { borderColor: color + "88", color, background: color + "18" } : undefined}>
      {children}
    </span>
  );
}

export function BackButton({ onClick, label = "Back" }: { onClick: () => void; label?: string }) {
  return (
    <button onClick={onClick} className="mb-2 inline-flex items-center gap-1 text-xs text-slate-400 hover:text-slate-100">
      <ChevronLeft size={14} /> {label}
    </button>
  );
}

const STATUS_NEXT: Record<QuestStatus, QuestStatus> = { todo: "active", active: "done", done: "todo" };
export const STATUS_LABEL: Record<QuestStatus, string> = { todo: "Not started", active: "In progress", done: "Completed" };

export function StatusButton({ status, onChange, size = 18 }: { status: QuestStatus; onChange: (s: QuestStatus) => void; size?: number }) {
  const Icon = status === "done" ? CircleCheck : status === "active" ? CircleDot : Circle;
  return (
    <button
      title={`${STATUS_LABEL[status]} (click to change)`}
      onClick={e => { e.stopPropagation(); onChange(STATUS_NEXT[status]); }}
      className={cn("shrink-0 rounded-full transition-colors",
        status === "done" ? "text-emerald-400" : status === "active" ? "text-amber-300" : "text-slate-500 hover:text-slate-300")}
    >
      <Icon size={size} />
    </button>
  );
}

export function WikiImage({ src, alt, className }: { src: string; alt: string; className?: string }) {
  if (!src) return null;
  return (
    <img src={src} alt={alt} loading="lazy" referrerPolicy="no-referrer" className={className}
      onError={e => { (e.currentTarget as HTMLImageElement).style.display = "none"; }} />
  );
}

export function Lines({ lines, className }: { lines: string[]; className?: string }) {
  return (
    <div className={cn("space-y-1.5 text-[13px] leading-relaxed text-slate-300", className)}>
      {lines.map((l, i) => <p key={i}>{l}</p>)}
    </div>
  );
}

export function SearchBox({ value, onChange, placeholder }: { value: string; onChange: (v: string) => void; placeholder: string }) {
  return (
    <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
      className="w-full rounded-md border border-white/10 bg-slate-950/60 px-3 py-1.5 text-sm text-slate-100 placeholder:text-slate-500 focus:border-amber-300/50 focus:outline-none" />
  );
}

export function Segmented<T extends string>({ value, options, onChange }: { value: T; options: { value: T; label: string }[]; onChange: (v: T) => void }) {
  return (
    <div className="inline-flex rounded-md border border-white/10 bg-slate-950/50 p-0.5 text-xs">
      {options.map(o => (
        <button key={o.value} onClick={() => onChange(o.value)}
          className={cn("rounded px-2 py-1 transition-colors", value === o.value ? "bg-amber-300/20 text-amber-100" : "text-slate-400 hover:text-slate-200")}>
          {o.label}
        </button>
      ))}
    </div>
  );
}
SPIRITFARER_EOF

cat > "src/utils/cn.ts" << 'SPIRITFARER_EOF'
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
SPIRITFARER_EOF

cat > "src/data/spiritfarer.json" << 'SPIRITFARER_EOF'
{
 "source": "Spiritfarer Fandom Wiki (spiritfarer.fandom.com), CC-BY-SA",
 "imageBase": "https://static.wikia.nocookie.net/spiritfarer/images/",
 "worldMap": {
  "url": "e/ed/MAP-OF-LOCATIONS.jpg/revision/latest",
  "bounds": {
   "x0": -227.59,
   "x1": 324.14,
   "yTop": 247.37,
   "yBottom": -174.35
  }
 },
 "regions": [
  "Everdoor",
  "Hummingberg",
  "Furogawa",
  "Industrial District",
  "Oxbury",
  "Crow's End"
 ],
 "islands": [
  {
   "id": "alberts-shipyard",
   "name": "Albert's Shipyard",
   "region": "Hummingberg",
   "x": 61,
   "y": 64,
   "bus": [
    77,
    51
   ],
   "requirements": [],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "alt-harbor",
   "name": "Alt Harbor",
   "region": "Hummingberg",
   "x": 43,
   "y": 40,
   "bus": [
    77,
    51
   ],
   "requirements": [],
   "spirits": [
    "Gwen"
   ],
   "resources": [],
   "shop": [],
   "other": [],
   "intro": [
    "Alt Harbor is the island in Spiritfarer where Stella first appears after talking to Charon at the Everdoor. This is where Stella encounters Gwen and acquires her boat."
   ],
   "chests": [],
   "sections": [
    {
     "heading": "Before Cleaning",
     "lines": [
      "The remains of an old Shipyard."
     ]
    },
    {
     "heading": "After Cleaning",
     "lines": [
      "An old Harbor that's been cleaned up."
     ]
    },
    {
     "heading": "Hummingberg Preservation Society",
     "lines": [
      "This shenanigan is given here sometime after Stella unlocks the blueprint for the Windmill. The quest reward is the blueprint upgrade for the Windmill."
     ]
    }
   ],
   "image": "5/50/Alt_Harbor.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "ambertown-park",
   "name": "Ambertown Park",
   "region": "Oxbury",
   "x": 216,
   "y": -72,
   "bus": [
    202,
    -59
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [
    "5 Ash Log",
    "2 Blueberry"
   ],
   "shop": [],
   "other": [],
   "intro": [
    "It is the location for the following requests:",
    "From Giovanni: Indiscreet Shopping",
    "From Gustav: The Search for Erich Deskmann",
    "From talking to the spirit on the far right: Surf N Turf."
   ],
   "chests": [
    {
     "text": "There is a dive spot to the right of the area, containing 1 Valuable Ring.",
     "needs": []
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "barkensheim-creek",
   "name": "Barkensheim Creek",
   "region": "Hummingberg",
   "x": 5,
   "y": 117,
   "bus": [
    44,
    119
   ],
   "requirements": [],
   "spirits": [
    "Atul"
   ],
   "resources": [
    "3 Maple Log",
    "2 Raspberry"
   ],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [],
   "sections": [],
   "image": "6/63/Barkensheim_Creek_Map_Icon.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "bottom-line-corp",
   "name": "Bottom Line Corp.",
   "region": "Industrial District",
   "x": 137,
   "y": 59,
   "bus": [
    77,
    51
   ],
   "requirements": [],
   "spirits": [
    "Astrid"
   ],
   "resources": [
    "1 Coal"
   ],
   "shop": [
    "Linen Seed",
    "Corn Seed",
    "Coffee Beans Seed",
    "Carrot Seed",
    "Turnip Seed"
   ],
   "other": [
    "2 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "The spirit standing on the far right (on the same level as the Raccoon Inc. shop) will sell Stella the key to the CEO's office for 100 Glims. After unlocking his office, the CEO will reward Stella 1000 Glims.",
     "needs": []
    },
    {
     "text": "Left of the CEO: Old Painting x1, Recipe for Wonton Soup",
     "needs": []
    },
    {
     "text": "Up the elevator, on the steel platform: Sugar Cane Seed x2, Large Glim Bottle x1",
     "needs": []
    },
    {
     "text": "On the right side of the factory roof, can be reached by going up the elevator and dropping down from the steel platform: Amethyst x2, Ceramic Bowl x1",
     "needs": []
    },
    {
     "text": "On top of the highest chimney of the factory roof (need Glide): Recipe for Pancakes, Crystal Chandelier x1",
     "needs": [
      "Glide"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "crows-end-inc",
   "name": "Crow's End Inc.",
   "region": "Crow's End",
   "x": -126,
   "y": -51,
   "bus": [
    -120,
    -27
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [
    "Elena"
   ],
   "resources": [
    "1 Gold Ore",
    "1 Iron Ore"
   ],
   "shop": [],
   "other": [
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Up the crane platform, near Elena (requires Double Jump, Glide, Zipline, and Bounce): Lettuce Seed x8, Large Glim Bottle x2",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Bounce"
     ]
    },
    {
     "text": "On the roof of the factory building(requires Double Jump, Glide, Zipline, and Bounce): Onion Seed x2, Recipe for Green Salad",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Bounce"
     ]
    },
    {
     "text": "After the zipline, on the platform with the air duct, jump right and glide left under the platform to find a set of small platforms, follow them left to the chest (requires Double Jump, Glide, Zipline, Bounce and Dash): Ceramic Figurine (Sublime Figurine) Alternatively, go left and swim until you see the chest platform. Because the Dash ability also launches you up, you can Double Jump/Dash straight onto the chest platform from the water.",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Bounce",
      "Dash"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "An abandoned factory amongst the trees."
     ]
    }
   ],
   "image": "7/70/Crow%27s_End.png/revision/latest",
   "spoiler": true
  },
  {
   "id": "edgeborough-lane",
   "name": "Edgeborough Lane",
   "region": "Oxbury",
   "x": 192,
   "y": -105,
   "bus": [
    202,
    -59
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [],
   "shop": [
    "1 Obol",
    "Olive Seed",
    "Sugar Cane Seed",
    "Proof of Purchase: Cow",
    "Buck's Lair of Wonders blueprint (only available while on A Lair of Wonders quest)",
    "Archive Room B-2522 blueprint (only available while on The Beginning and the End quest)"
   ],
   "other": [
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "On the roof of the second building to the right of Randy (requires Double Jump and Zipline): Leek Seed x1, Signed Vintage Poster x1",
     "needs": [
      "Double Jump",
      "Zipline"
     ]
    },
    {
     "text": "Inside the fourth building to the right of Randy: Sugar Cane Seed x2, Large Glim Bottle x1",
     "needs": []
    },
    {
     "text": "On the roof of the third building to the right of Randy (requires Double Jump and Zipline): Proof of Purchase: Cow x1, Peach Seed x1",
     "needs": [
      "Double Jump",
      "Zipline"
     ]
    },
    {
     "text": "On the roof of the sixth building to the right of Randy (requires Zipline or Bounce): Medium Glim Bottle x1, Recipe for Muesli",
     "needs": [
      "Zipline",
      "Bounce"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "everdoor",
   "name": "Everdoor",
   "region": "Everdoor",
   "x": 0,
   "y": 0,
   "bus": [
    -1,
    -18
   ],
   "requirements": [],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [],
   "intro": [
    "The Everdoor is where Stella begins her journey, and where she inherits the responsibility from Charon to bring here the Spirits ready to pass on."
   ],
   "chests": [],
   "sections": [
    {
     "heading": "Trivia",
     "lines": [
      "The Everdoor is inspired by the Rakotzbrücke in Azalea and Rhododendron Park Kromlau, located in Gablenz, Germany, as it forms a perfect circle with its reflection. It is also known as Teufelsbrücke, or the \"Devil's Bridge\"."
     ]
    }
   ],
   "image": "b/bb/Everdoor.png/revision/latest",
   "spoiler": true
  },
  {
   "id": "flotsam-shores",
   "name": "Flotsam Shores",
   "region": "Industrial District",
   "x": 109,
   "y": -107,
   "bus": [
    132,
    -94
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [
    "1 Coal",
    "3 Zinc Ore",
    "1 Limestone",
    "1 Copper"
   ],
   "shop": [],
   "other": [
    "4 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "From your boat, to the far left (requires Double Jump or Glide): Anchovy x1, Amethyst x1, Sockeye Salmon x 1",
     "needs": [
      "Double Jump",
      "Glide"
     ]
    },
    {
     "text": "From your boat, above the starting platform, jump from the platform to the right (requires Double Jump): Flounder x1, Citrine x1",
     "needs": [
      "Double Jump"
     ]
    },
    {
     "text": "Inside the containers, when you encounter the first Bounce platform by the two spirits, bounce up and move left into the secret passage within the wall: Opal x1, Cuttlefish x1, Cobia x1",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "Inside the containers, to the right of the second Bounce platform: Lobster x2, Crystal Chandelier x1",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "Inside the containers, the hidden passage to the upper right when bouncing to maximum height on the second Bounce platform: Char x1, Mackerel x1, Citrine x1",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "At the exit of the containers, on the roof (requires Double Jump): Large Glim Bottle x1, Mahi-Mahi x1",
     "needs": [
      "Double Jump"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Maps",
     "lines": [
      "Notes:",
      "Dashed lines indicate hidden passages. (Unlike other locations, there are no ropes indicating the hidden passages.)",
      "Red lines indicate Bounce platforms.",
      "Numbers refer to chests, as described in the Chests section above."
     ]
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "furogawa",
   "name": "Furogawa",
   "region": "Furogawa",
   "x": -150,
   "y": 67,
   "bus": [
    -162,
    51
   ],
   "requirements": [],
   "spirits": [
    "Gustav"
   ],
   "resources": [],
   "shop": [
    "Rice Seed",
    "Leek Seed",
    "Apple Seed",
    "Pork"
   ],
   "other": [
    "Shrine",
    "Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Go up the air draft, then glide all the way to the right to talk to a spirit (need Glide): Key for Furogawa House",
     "needs": [
      "Glide",
      "Key for Furogawa House"
     ]
    },
    {
     "text": "Inside the house left of the sacred tree (need Key for Furogawa House): Large Glim Bottle x1, Linen Seed x2",
     "needs": [
      "Key for Furogawa House"
     ]
    },
    {
     "text": "Go up the air draft, then glide left until you see a chest on the light pole (need Glide): Signed Vintage Poster x1",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "From the house with a chair and table outside, jump off from the table and glide left to reach the lower level of the light pole (need Glide): Rice Seed x2, Leek Seed x1",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "On the upper level of the light pole mentioned above (need Double Jump and Glide, Dash recommended): Hematite x1, Recipe to Fish Curry",
     "needs": [
      "Double Jump",
      "Glide",
      "Dash"
     ]
    }
   ],
   "sections": [],
   "image": "6/6b/Furogawa.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "greenhalten-bay",
   "name": "Greenhalten Bay",
   "region": "Hummingberg",
   "x": -8,
   "y": 75,
   "bus": [
    -63,
    104
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "1 Copper Ore",
    "2 Maple Log",
    "2 Raspberry"
   ],
   "shop": [],
   "other": [
    "Dive Spot"
   ],
   "intro": [
    "Speaking to the spirit at this location will allow Stella to fish up a Message in a Bottle containing Ode to an Axe."
   ],
   "chests": [
    {
     "text": "Dive at the far right: Valuable Ring",
     "needs": []
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "greymist-peaks",
   "name": "Greymist Peaks",
   "region": "Crow's End",
   "x": 216,
   "y": 96,
   "bus": null,
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [],
   "shop": [
    "Onion Seed",
    "Tomato Seed",
    "Garlic Seed",
    "Peach Seed"
   ],
   "other": [
    "Shrine (Dash)"
   ],
   "intro": [],
   "chests": [],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A popular camping spot for fans of the occult."
     ]
    },
    {
     "heading": "Shrine",
     "lines": [
      "The Shrine for the Dash ability is located in the upper left side. Requires Double Jump, Glide, and Bounce abilities to access."
     ]
    },
    {
     "heading": "How to access the Shrine",
     "lines": [
      "Potential spoilers ahead!",
      "To access the shrine, glide on the geyser to the ledge with a Denizen and a tent. Bounce on the tent to gain height, then glide across to a few ledges on the left. There will be another tent, and another ledge with a geyser, and a few smaller ledges. Jump across to another tent, again using the first geyser to reach. The last tent will lead to the Shrine."
     ]
    }
   ],
   "image": "6/6d/Greymist_Peaks.png/revision/latest",
   "spoiler": true
  },
  {
   "id": "gurenu-fields",
   "name": "Gurenu Fields",
   "region": "Furogawa",
   "x": -65,
   "y": 55,
   "bus": [
    -71,
    31
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "2 Oak Log",
    "1 Mushroom",
    "1 Strawberry"
   ],
   "shop": [],
   "other": [
    "1 Sheep",
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "There is a diving spot to the left of the sacred tree, containing a Citrine.",
     "needs": []
    },
    {
     "text": "Further left of the sacred tree, on the island (need Dash and Glide): Amethyst x3, Wool Fabric x1, Miniature Diorama x3",
     "needs": [
      "Glide",
      "Dash"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hidden-shrine",
   "name": "Hidden Shrine",
   "region": "Crow's End",
   "x": -185,
   "y": -92,
   "bus": [
    -149,
    -104
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "Shrine (Lightburst)"
   ],
   "intro": [],
   "chests": [],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A sparse island with an ancient shrine."
     ]
    }
   ],
   "image": "7/76/Hidden_Shrine.png/revision/latest",
   "spoiler": true
  },
  {
   "id": "hidden-thicket",
   "name": "Hidden Thicket",
   "region": "Crow's End",
   "x": -42,
   "y": -91,
   "bus": [
    -74,
    -99
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [
    "1 Gold Ore",
    "1 Pine Log",
    "1 Iron Ore",
    "1 Zinc Ore"
   ],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [],
   "sections": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "hikarishima-lighthouse",
   "name": "Hikarishima Lighthouse",
   "region": "Furogawa",
   "x": -137,
   "y": -14,
   "bus": [
    -120,
    -27
   ],
   "requirements": [],
   "spirits": [
    "Buck"
   ],
   "resources": [],
   "shop": [
    "Tea Seed",
    "Lettuce Seed",
    "Cherry Seed",
    "Linen Seed",
    "Opal"
   ],
   "other": [
    "2 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Dive spot left of the lighthouse (requires Bounce): Recipe for Tomato Pizza",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "Jumping from the lighthouse or the umbrella, on top of the light pole between the lighthouse and the Raccoon Inc. stall (requires Bounce): Peach x2, Opal x1",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "Jumping from the lighthouse or the umbrella, above the Raccoon Inc. stall (requires Bounce): Amethyst x1, Mint Collectible Card x1",
     "needs": [
      "Bounce"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hoseki-quarry",
   "name": "Hoseki Quarry",
   "region": "Furogawa",
   "x": -138,
   "y": 28,
   "bus": [
    -162,
    51
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "4 Iron Ore",
    "2 Coal",
    "2 Slate",
    "4 Mushroom"
   ],
   "shop": [],
   "other": [
    "Blueprint x1",
    "Rare Chest x4"
   ],
   "intro": [],
   "chests": [
    {
     "text": "In the upper-right portion of the quarry, go up the air ducts (need Glide): Field Upgrade",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "Near the center of the quarry, left of the tall spirit by the ladder, hidden passage to the left as marked by the rope going into the wall: Amethyst x2, Miniature Diorama x1",
     "needs": []
    },
    {
     "text": "Near the center of the quarry, from the tall spirit by the ladder, go up two levels, hidden passage to the right as marked by the rope going into the wall: Diamond x1, Old Painting x1",
     "needs": []
    },
    {
     "text": "In the bottom-left portion of the quarry, travel upwards, chest to the right (need Zipline and Dash): Opal x2, Cherry Seed x2",
     "needs": [
      "Zipline",
      "Dash"
     ]
    },
    {
     "text": "In the bottom-left portion of the quarry, travel upwards, chest to the left (need Zipline and Dash): Diamond x3, Opal x1, Crystal Chandelier x1",
     "needs": [
      "Zipline",
      "Dash"
     ]
    },
    {
     "text": "In the upper portion of the quarry, in a room with books on the ground, hidden passage to the upper-right as marked by the rope going into the wall, talk to the spirit (need Double Jump): 1000 Glims",
     "needs": [
      "Double Jump"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Maps",
     "lines": [
      "Notes:",
      "Dashed lines indicate hidden passages. (Hidden passages are marked by ropes going into the wall.)",
      "Green lines indicate an air draft.",
      "Gold lines indicate ziplines.",
      "Blue lines indicate gaps requiring Dash to get across.",
      "Numbers refer to chests, as described in the Chests section above."
     ]
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hummingberg",
   "name": "Hummingberg",
   "region": "Hummingberg",
   "x": 39,
   "y": 139,
   "bus": [
    44,
    119
   ],
   "requirements": [],
   "spirits": [
    "Summer"
   ],
   "resources": [],
   "shop": [
    "Linen Seed",
    "Corn Seed",
    "Coffee Beans Seed",
    "Carrot Seed",
    "Turnip Seed",
    "1 Key for Hummingberg"
   ],
   "other": [
    "1 Shrine (Double Jump)",
    "1 Sheep",
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Inside the first house, upstairs, left side: Carrot Seed x2, Turnip Seed x1",
     "needs": []
    },
    {
     "text": "Inside the second house, ground floor, left side: Carrot Seed x2, Turnip Seed x1",
     "needs": []
    },
    {
     "text": "On the roof of the third house (need Double Jump): Vibrant Necklace x1",
     "needs": [
      "Double Jump"
     ]
    },
    {
     "text": "Windowsill above the Feedorama employee (need Double Jump): Linen Seed x2",
     "needs": [
      "Double Jump"
     ]
    },
    {
     "text": "Inside the house with the broken ladder (need Key for Hummingberg): Ceramic Figurine (Delicate Figurine)",
     "needs": [
      "Key for Hummingberg"
     ]
    },
    {
     "text": "Dive spot (appears after talking to a tall spirit about the bench at the end of the pier): Citrine x1",
     "needs": []
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A grand city with a mysterious shrine."
     ]
    }
   ],
   "image": "3/32/Hummingberg.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "iwashima-countryside",
   "name": "Iwashima Countryside",
   "region": "Furogawa",
   "x": -64,
   "y": 16,
   "bus": [
    -71,
    31
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "3 Oak Log",
    "1 Limestone",
    "1 Copper Ore",
    "2 Mushroom",
    "1 Strawberry"
   ],
   "shop": [],
   "other": [],
   "intro": [
    "Chests:",
    "1. On top of first pole as you walk right from the boat, need dash ability to dash from the pole right of it unto it. Alternatively you can double jump then glide to reach it. Reward: 1 Old Carpet"
   ],
   "chests": [],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "kaltstein-mines",
   "name": "Kaltstein Mines",
   "region": "Hummingberg",
   "x": -99,
   "y": 117,
   "bus": [
    -63,
    104
   ],
   "requirements": [
    "Icebreaker"
   ],
   "spirits": [],
   "resources": [
    "4 Marble",
    "2 Coal"
   ],
   "shop": [],
   "other": [
    "5 Rare Chest"
   ],
   "intro": [
    "Note that you cannot enter the mines proper without the Key for the Kaltstein Mines. The guard outside will give the key after completing the Shenanigans \"Training Wheels\", which requires having the Abilities Double Jump, Glide, and Zipline",
    "The mines provide Marble, which is needed as part of the storyline."
   ],
   "chests": [
    {
     "text": "Bottom-left of map, hidden passage to the left: Hematite x1, Metal Rope x1",
     "needs": []
    },
    {
     "text": "Right side of map, hidden passage to the right of the Coal mining spot: Maple Syrup x5, Amethyst x1",
     "needs": []
    },
    {
     "text": "A secret passage just below the end of the sloped drop off at the start of the mine. You can reach it by gliding down from the end of the slope. Can also be reached by dashing left from the Marble mining spot: Crystal Chandelier x1, Metal Rope x1",
     "needs": []
    },
    {
     "text": "Upper part of map, up the air ducts, fall down the narrow passage between the Marble and Coal mining spots: Sunflower Seed x1, Pear Seed x1",
     "needs": []
    },
    {
     "text": "Upper part of map, from the Marble mining spot, hidden passage to the upper right (requires Dash): Opal x1, Metal Rope x1",
     "needs": [
      "Dash"
     ]
    },
    {
     "text": "Upper-left of map, take the zipline to accelerate, then jump left through the hidden passage: Diamond x2, Fancy Vase x1",
     "needs": []
    }
   ],
   "sections": [
    {
     "heading": "Maps",
     "lines": [
      "Notes:",
      "Arrows indicate one-way passages.",
      "Dashed lines indicate hidden passages. (Hidden passages are marked by ropes going into the wall.)",
      "Green lines indicate an air draft.",
      "Gold lines indicate a zipline.",
      "Purple lines indicate a gap that requires Dash to clear.",
      "Numbers refer to chests, as described in the Chests section above."
     ]
    },
    {
     "heading": "Alternate Map",
     "lines": [
      "This map was made by Drag0nK1ng123, and posted on Reddit here."
     ]
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "loneberg",
   "name": "Loneberg",
   "region": "Hummingberg",
   "x": -40,
   "y": 192,
   "bus": [
    -64,
    196
   ],
   "requirements": [
    "Icebreaker"
   ],
   "spirits": [
    "Giovanni"
   ],
   "resources": [],
   "shop": [
    "Cabbage Seed",
    "Cotton Seed",
    "Metal Rope",
    "Glass"
   ],
   "other": [
    "1 Blueprint Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "On top of the roof of the house (requires Zipline): Chicken Coop Improvement",
     "needs": [
      "Zipline"
     ]
    },
    {
     "text": "Dive spot to the right of the island: Recipe for Beef Fondue",
     "needs": []
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "The remains of an abandoned cottage."
     ]
    }
   ],
   "image": "a/a4/Loneberg.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "lost-shrine",
   "name": "Lost Shrine",
   "region": "Crow's End",
   "x": 220,
   "y": 167,
   "bus": [
    173,
    147
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "Shrine (Tool Upgrade)"
   ],
   "intro": [
    "Lost Shrine is a hidden island found in Spiritfarer."
   ],
   "chests": [],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "Once lost at sea, this shrine breathed of life and power."
     ]
    },
    {
     "heading": "Notes",
     "lines": [
      "This island can only be visited after receiving the coordinates in-game from the Treasure Map rewarded from a late-game errand from Francis. This errand is unlocked after finishing some of Buck's questline. Attempting to visit it before this will result in empty ocean at its coordinates."
     ]
    }
   ],
   "image": "c/c3/Lost_Shrine.png/revision/latest",
   "spoiler": true
  },
  {
   "id": "misty-woods",
   "name": "Misty Woods",
   "region": "Crow's End",
   "x": 148,
   "y": 152,
   "bus": [
    173,
    147
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [
    "1 Gold Ore",
    "2 Pine Log",
    "1 Copper Ore"
   ],
   "shop": [],
   "other": [
    "1 Blueprint Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Below the Gold Ore mining spot, left of the Copper Ore mining spot (requires Double Jump, Bounce, Zipline and Glide): Cellar Improvement",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Bounce"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "mosstein-cove",
   "name": "Mosstein Cove",
   "region": "Hummingberg",
   "x": 78,
   "y": 130,
   "bus": [
    44,
    119
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "1 Limestone",
    "2 Maple Log",
    "2 Raspberry"
   ],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [
    {
     "text": "Along the main path, under the shelter: Empty Bottle x1, Medium Glim Bottle x1",
     "needs": []
    }
   ],
   "sections": [],
   "image": "b/b6/Mosstein_Cove_Map_Icon.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "mount-toroyama",
   "name": "Mount Toroyama",
   "region": "Furogawa",
   "x": -99,
   "y": 34,
   "bus": [
    -71,
    31
   ],
   "requirements": [],
   "spirits": [
    "Alice"
   ],
   "resources": [
    "2 Coal",
    "2 Slate",
    "1 Copper Ore"
   ],
   "shop": [],
   "other": [
    "1 Sheep",
    "7 Rare Chest",
    "1 Spirit"
   ],
   "intro": [],
   "chests": [
    {
     "text": "In the mines, near the exit: 1x Opal, 1x Apple Seed (see map below for more details)",
     "needs": []
    },
    {
     "text": "In the mines, hidden passage above ladder: 1x Ceramic Figurine (see map below for more details)",
     "needs": []
    },
    {
     "text": "In the mines, right of the air draft (requires Glide): 1x Antique Bust, 1x Amethyst (can be reached without Glide by holding right against the wall while dropping down the air draft from left of chest 2) (see map below for more details)",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "In the mines, hidden passage left of air draft (requires Glide): 1x Hematite, 1x Veggie-Pot Pie recipe (can be reached without Glide by holding left while jumping over the air draft after accessing the chest 3 area) (see map below for more details)",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "On top of the roof of the house: 1x Citrine (can be reached either from the ledge above the mines, or repeated jumping on the slanted roof)",
     "needs": []
    },
    {
     "text": "Inside the house (requires Key for Mount Toroyama's House): 2x Cherry Seed, 1x Ceramic Bowl",
     "needs": [
      "Key for Mount Toroyama's House"
     ]
    },
    {
     "text": "From the ledge above the mines, jump off the ledge, then glide left to above the mine entrance: 1x Citrine, 1x Old Carpet",
     "needs": [
      "Glide"
     ]
    },
    {
     "text": "From the ledge above the mines, jump off the ledge, then glide all the way right (or double jump, dash, then glide from the platform directly above the boat). Left chest: 1x Large Glim Bottle. Right Chest: 1x Hematite, 2x Tea Seed",
     "needs": [
      "Double Jump",
      "Glide",
      "Dash"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Maps",
     "lines": [
      "Notes:",
      "Arrows indicate one-way passages.",
      "Dashed lines indicate hidden passages. (Hidden passages are marked by ropes going into the wall.)",
      "Green lines indicate an air draft.",
      "Numbers refer to chests, as described in the Chests section above.",
      "Encountered fairly early on in Spiritfarer's story, Alice can be found on Mount Toroyama, located at -93 x, 34 y. To get her to join your crew though, you'll need to jump through a few hoops first. Upon reaching the mountain, you'll find her in need of help corralling a sheep back into its pen."
     ]
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "nordsee-pier",
   "name": "Nordsee Pier",
   "region": "Hummingberg",
   "x": -116,
   "y": 165,
   "bus": [
    -141,
    170
   ],
   "requirements": [
    "Icebreaker"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Dive spot to the right side of the lighthouse: Old Coin Collection x1",
     "needs": []
    },
    {
     "text": "On the roof of the house to the right of the lighthouse: Antique Bust x1",
     "needs": []
    },
    {
     "text": "On a ledge at the middle of the lighthouse: Tea Seed x1, Recipe for Heat-Treated Crab",
     "needs": []
    },
    {
     "text": "On a platform to the far left of the map (requires either Zipline at the middle of the lighthouse, or Glide and Dash from the top of the lighthouse: Lettuce Seed x1, Recipe for Lobster Germinal",
     "needs": [
      "Glide",
      "Zipline",
      "Dash"
     ]
    },
    {
     "text": "On a platform to the far right of the map (requires Glide and Dash; from the top of the lighthouse, glide all the way right, the glide is long enough to Dash multiple times, watch Stella's belt buckle on when you can Dash again): Metal Rope x1, Miniature Diorama x1",
     "needs": [
      "Glide",
      "Dash"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "nordweiler",
   "name": "Nordweiler",
   "region": "Hummingberg",
   "x": -3,
   "y": 185,
   "bus": [
    25,
    192
   ],
   "requirements": [
    "Icebreaker"
   ],
   "spirits": [],
   "resources": [],
   "shop": [
    "Celery Seed",
    "Sunflower Seed",
    "Pear Seed",
    "Cabbage Seed",
    "Chicken",
    "Pork",
    "Metal Rope",
    "The Autumn End 1000g"
   ],
   "other": [
    "Shrine (Zipline)",
    "1 Sheep",
    "1 Rare Chest",
    "2 Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "In front of the house up on the platform and to the left (requires Zipline): Apple Seed x1, Recipe for Apple Pie",
     "needs": [
      "Zipline"
     ]
    },
    {
     "text": "To get the rare chest located below the shrine, you need the Gliding Ability to glide from the side of the wall and to the platform. To the left of the shrine, jump (don't Double Jump) and start gliding right, under the shrine. Then use Double Jump near the chest. The Dash ability helps make it easier.: Diamond x2, Amethyst x2",
     "needs": [
      "Double Jump",
      "Glide",
      "Dash"
     ]
    },
    {
     "text": "The chest inside the house at the top left (requires Key for the Nordweiler house): Strasbourg, 1944",
     "needs": [
      "Key for the Nordweiler house"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A wintry village in the middle of nowhere."
     ]
    },
    {
     "heading": "Quests",
     "lines": [
      "Alice asks you to take her to Nordweiler for her quest Down the Rabbit Hole."
     ]
    }
   ],
   "image": "8/87/Nordweiler.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "obscure-canopy",
   "name": "Obscure Canopy",
   "region": "Crow's End",
   "x": 187,
   "y": 87,
   "bus": [
    206,
    78
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [
    "1 Gold Ore",
    "2 Pine Log",
    "1 Limestone"
   ],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [
    {
     "text": "From the start, go left in the water: Carrot Seed x7, Fancy Vase x1",
     "needs": []
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "old-central-district",
   "name": "Old-Central District",
   "region": "Oxbury",
   "x": 185,
   "y": -8,
   "bus": [
    202,
    -59
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "5 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Inside the left building, to the left on the top floor (requires Key for Oxbury or Double Jump, Glide, and Zipline): Miniature Diorama x1, Recipe for Aloo Gobi",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Key for Oxbury"
     ]
    },
    {
     "text": "Inside the middle building, bottom floor to the right (requires Key for Oxbury): Mint Collectible Card, Recipe for Maple Salmon",
     "needs": [
      "Key for Oxbury"
     ]
    },
    {
     "text": "Inside the middle building, on the top floor of the penthouse (requires Key for Oxbury): Amethyst x1, Recipe for Corn Bread",
     "needs": [
      "Key for Oxbury"
     ]
    },
    {
     "text": "Start from the left building, then jump across the platforms on the middle building to reach the roof of the right building (requires Double Jump, Glide and Bounce): Large Glim Bottle x1, Wheat Seed x2",
     "needs": [
      "Double Jump",
      "Glide",
      "Bounce"
     ]
    },
    {
     "text": "On the roof of the leftmost building, reached from the roof of the middle building (requires Double Jump, Glide and Bounce): Henry, 8 Years Old acetate",
     "needs": [
      "Double Jump",
      "Glide",
      "Bounce"
     ]
    },
    {
     "text": "On window ledge of middle building, reached by gliding from second door/platform on leftmost building (requires Glide, and either Key for Oxbury or both Double Jump and Zipline): Bovine License x1, Recipe for French Fries",
     "needs": [
      "Double Jump",
      "Glide",
      "Zipline",
      "Key for Oxbury"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "overbrook",
   "name": "Overbrook",
   "region": "Oxbury",
   "x": 212,
   "y": 56,
   "bus": [
    206,
    78
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [
    "Jackie",
    "Daria"
   ],
   "resources": [],
   "shop": [],
   "other": [
    "Vending Machine"
   ],
   "intro": [
    "Upon discovering Overbrook for the first time, you will see it is a run down hospital with only two workers. The first is an unnamed green spirit and the second is the orderly, Jackie. There are many spirits around, typically in white apart from the staff and a group of spirits still waiting to be admitted."
   ],
   "chests": [
    {
     "text": "Inside the tower (obtained during Daria's questline). - x1 Amethyst, x1 Fancy Vase",
     "needs": []
    },
    {
     "text": "On a upper platform on the left of the tower. - x1 Diamond, x1 Mint Collectible Card",
     "needs": []
    },
    {
     "text": "On top of the ruins at the far left of the area. - x1 Large Glim Bottle, x1 [Recipe]",
     "needs": []
    },
    {
     "text": "Inside the building at the eastern island - 1x Large Glim Bottle",
     "needs": []
    },
    {
     "text": "On the cliff to the left of the tower. - 1x Large Glim Bottle",
     "needs": []
    }
   ],
   "sections": [
    {
     "heading": "Shenanigans and Quests",
     "lines": [
      "An Arm and a Leg",
      "Bring 2 Household Glue, 10 Sawdust and 1 Pork to the spirit sitting next to the cafeteria",
      "The High Wire Act",
      "Talk to the spirit on the cliff ledge by chest #5 to begin",
      "Bring him 5 linen",
      "The Real Spiritfarer",
      "Talk to the white spirit on the eastern island (the island to the right of where your boat parks)",
      "Return to your ship and fish while still docked at Overbrook; you will fish up a lightbulb",
      "Bring the lightbulb to the spirit",
      "Three's Company - This hospital is cruelly understaffed and in need of dedicated employees. Time to find some competent people!",
      "Recruit a Chef for Overbrook in Hoseki Quarry.",
      "Recruit a Doctor for Overbrook in Old-Central District.",
      "Recruit a gardener for Overbrook in Villa Maggiore."
     ]
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "oxbury",
   "name": "Oxbury",
   "region": "Oxbury",
   "x": 233,
   "y": 18,
   "bus": [
    246,
    27
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [
    "Beverly"
   ],
   "resources": [
    "Ash Log"
   ],
   "shop": [
    "Potato Seed",
    "Wheat Seed",
    "Mulberry Seed",
    "Beef",
    "Pork",
    "Chicken",
    "Egg"
   ],
   "other": [
    "Shrine",
    "Rare Chest x4"
   ],
   "intro": [
    "The Key for Oxbury can be bought from Raccoon Inc. in Oxbury."
   ],
   "chests": [
    {
     "text": "Inside the top floor of the first house (requires Key for Oxbury): Miniature Diorama x1, Hematite x1",
     "needs": [
      "Key for Oxbury"
     ]
    },
    {
     "text": "On the roof of the third house (requires Bounce): Large Glim Bottle x1, Recipe for Bread",
     "needs": [
      "Bounce"
     ]
    },
    {
     "text": "Inside the top floor of the fourth house (the café): Amethyst x1, Crystal Chandelier x1",
     "needs": []
    },
    {
     "text": "On the roof of the fourth house: Potato Seed x2, Wheat Seed x2",
     "needs": []
    },
    {
     "text": "Inside the house to the left of the shrine (requires Key for Oxbury): Opal x1, Mint Collectible Card x1",
     "needs": [
      "Key for Oxbury"
     ]
    },
    {
     "text": "On the roof of the right-most house (requires Bounce or Zipline): Old Carpet x1, Ceramic Bowl x1, Amethyst x1",
     "needs": [
      "Zipline",
      "Bounce"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A cosmopolitan city with all kinds of shops and interesting people."
     ]
    }
   ],
   "image": "0/0f/Oxbury.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "resuteno-meadows",
   "name": "Resuteno Meadows",
   "region": "Furogawa",
   "x": -97,
   "y": -25,
   "bus": [
    -120,
    -27
   ],
   "requirements": [],
   "spirits": [],
   "resources": [
    "2 Oak Log",
    "1 Mushroom",
    "1 Strawberry"
   ],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "sandwich-walk",
   "name": "Sandwich Walk",
   "region": "Industrial District",
   "x": 141,
   "y": -54,
   "bus": [
    132,
    -94
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "1 Sheep",
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "On a platform to the left of the map: Garlic Seed x2, Recipe for Garlic Bread",
     "needs": []
    },
    {
     "text": "On a platform to the upper-middle of the map: Olive Seed x1, Valuable Ring x1",
     "needs": []
    },
    {
     "text": "On a platform to the far right of the map, there are arrow signs pointing in the right direction (requires Glide): Mulberry Seed x1, Amethyst x1",
     "needs": [
      "Glide"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "shadow-forest",
   "name": "Shadow Forest",
   "region": "Crow's End",
   "x": -95,
   "y": -78,
   "bus": [
    -74,
    -99
   ],
   "requirements": [
    "Mist Cleaner 1000"
   ],
   "spirits": [],
   "resources": [
    "3 Pine Log",
    "1 Coal"
   ],
   "shop": [],
   "other": [],
   "intro": [
    "This island's purpose is only for gathering the resources on its lower level. There is no way to reach the higher cliff as it doesn't contain anything else."
   ],
   "chests": [],
   "sections": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "southpoint-docks",
   "name": "Southpoint Docks",
   "region": "Industrial District",
   "x": 157,
   "y": 22,
   "bus": [
    77,
    51
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [
    "Bruce & Mickey"
   ],
   "resources": [
    "1 Gold Ore",
    "1 Iron Ore",
    "1 Marble",
    "2 Zinc Ore",
    "1 Coal"
   ],
   "shop": [],
   "other": [
    "1 Blueprint Chest",
    "2 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "To the right of the map, ride the elevator up, then on top of the crane (requires Double Jump and Bounce): Diamond x1, Opal x1",
     "needs": [
      "Double Jump",
      "Bounce"
     ]
    },
    {
     "text": "From the chest above, drop down to the platform to the right of the crane (requires (Double Jump and Bounce): Sheep Corral Improvement",
     "needs": [
      "Double Jump",
      "Bounce"
     ]
    },
    {
     "text": "On the top platform to the upper-left of the map (requires Dash): Diamond x1, Opal x1 [also obtainable with Bounce, Double Jump, and Glide - jump from the upper right ledge, double jump to gain maximum starting height, hold down and jump buttons briefly to pass through the lower ledge (be careful not to glide), then hold jump again to bounce on the trash can below, immediately start moving left as you as end through the ledge then glide the rest of the way. This will also net an early Gold Ore.]",
     "needs": [
      "Double Jump",
      "Glide",
      "Bounce",
      "Dash"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "sunspring-square",
   "name": "Sunspring Square",
   "region": "Oxbury",
   "x": 151,
   "y": -109,
   "bus": [
    132,
    -94
   ],
   "requirements": [
    "Rock Destroyer"
   ],
   "spirits": [],
   "resources": [
    "3 Ash Log",
    "2 Blueberry"
   ],
   "shop": [],
   "other": [
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "On the roof of the first building (requires Double Jump or Bounce): Onion Seed x2, Turnip Seed x6",
     "needs": [
      "Double Jump",
      "Bounce"
     ]
    },
    {
     "text": "On the roof of the building right of the park (requires Double Jump, Glide and Bounce): Amethyst x1, Wheat Seed x1, Fancy Vase x1",
     "needs": [
      "Double Jump",
      "Glide",
      "Bounce"
     ]
    }
   ],
   "sections": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "susans-museum",
   "name": "Susan's Museum",
   "region": "Hummingberg",
   "x": -150,
   "y": 150,
   "bus": [
    -141,
    170
   ],
   "requirements": [
    "Icebreaker"
   ],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [],
   "intro": [],
   "chests": [],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A harbor for the great collector, Susan."
     ]
    },
    {
     "heading": "Dishes Collection",
     "lines": [
      "Note that a dish is not added to the collection unless you have actually cooked it at least once; in other words, simply finding the recipe in the world is not enough to complete it! This is reflected in the difference between the \"Recipes\" page in your kitchen, versus the Dishes Collection in Susan's Museum: i.e., your recipe page may be completely filled in due to finding recipes in the world, but your Dishes Collection in Susan's Museum may still be missing some items."
     ]
    }
   ],
   "image": "e/e7/Susan%27s_Museum.png/revision/latest",
   "spoiler": false
  },
  {
   "id": "villa-maggiore",
   "name": "Villa Maggiore",
   "region": "Hummingberg",
   "x": -58,
   "y": 117,
   "bus": [
    -63,
    104
   ],
   "requirements": [],
   "spirits": [],
   "resources": [],
   "shop": [],
   "other": [
    "2 Blueprint Chest",
    "1 Rare Chest"
   ],
   "intro": [],
   "chests": [
    {
     "text": "Dive spot under the gardener’s door: Old Coin Collection",
     "needs": []
    },
    {
     "text": "Eastern pier: Linen Seed x2, Old Painting x1",
     "needs": []
    },
    {
     "text": "4th floor of the villa’s west wing (requires the Key for Villa Maggiore): Old Carpet x1",
     "needs": [
      "Key for Villa Maggiore"
     ]
    },
    {
     "text": "On the villa’s balcony (requires the Key for Villa Maggiore): Loom Upgrade, Music Box",
     "needs": [
      "Key for Villa Maggiore"
     ]
    },
    {
     "text": "In the shed after completing This Shed Is My Shed: Garden upgrade.",
     "needs": []
    },
    {
     "text": "On the villa’s roof (requires Bounce): Ceramic Bowl x1, Recipe for Noodle Soup",
     "needs": [
      "Bounce"
     ]
    }
   ],
   "sections": [
    {
     "heading": "Description",
     "lines": [
      "A giant Alpine villa that once belonged to Gwen's parents."
     ]
    },
    {
     "heading": "Trivia",
     "lines": [
      "Villa Maggiore is likely modeled after the world-famous palazzo on Isola Bella on Lago Maggiore (Lake Maggiore) in Northern Italy."
     ]
    }
   ],
   "image": "2/2b/Villa_Maggiore.png/revision/latest",
   "spoiler": false
  }
 ],
 "spirits": [
  {
   "id": "alice",
   "name": "Alice",
   "species": "Hedgehog",
   "origin": "mount-toroyama",
   "originText": "Mount Toroyama",
   "house": "Alice's Cottage",
   "event": "Nebula Pillbug",
   "favouriteFood": "Veggie-Pot Pie",
   "likes": "Old-Fashioned, Dessert",
   "dislikes": "Acquired Taste, Stimulants, Exotic",
   "skills": "Cooking, Harvesting fruit",
   "flower": "Peace lily",
   "firstQuest": "One Shoop, Two Sheep",
   "lastQuest": "Annie's Lost Hat",
   "about": [
    "Alice is a Spirit, who appears as a hedgehog, found in Spiritfarer. She can be found at Mount Toroyama. You must complete The Coziest Cottage quest in order for her to join you on your boat."
   ],
   "life": [
    "A stay-at-home mom, she spent most of her adulthood looking after her children and taking care of her family’s domestic life. Engaging with Alice meant doing so of your own volition, as she would never dare impose herself. However, she loved fashion, travelling, and Swedish romance novels, which she slowly reveals to Stella. Unfortunately, as she grew older, she started showing signs of dementia.",
    "In Stella’s life, she represents a turning point in her vocation as a nurse. Alice was the first patient to die in Stella’s care, an experience that reaffirmed her will to work in end-of-life care."
   ],
   "everdoor": [],
   "image": "8/82/Alice.png/revision/latest",
   "dlc": false,
   "quests": [
    "one-shoop-two-sheep",
    "the-coziest-cottage",
    "a-coat-of-wool",
    "a-spot-for-pots",
    "of-warts-and-ropes",
    "apples-and-oranges",
    "down-the-rabbit-hole",
    "taking-the-low-road",
    "a-chilling-realisation",
    "annies-lost-hat"
   ]
  },
  {
   "id": "astrid",
   "name": "Astrid",
   "species": "Lynx",
   "origin": "bottom-line-corp",
   "originText": "Bottom Line Corp.",
   "house": "Astrid's Bungalow",
   "event": "",
   "favouriteFood": "Noodle Soup",
   "likes": "Plain food, Soup",
   "dislikes": "Sugary food, Fine Dining",
   "skills": "Mining, Smelting, Fishing",
   "flower": "Mallow",
   "firstQuest": "Unite!",
   "lastQuest": "Lovers for Life",
   "about": [
    "Astrid is a spirit. She is first encountered leading a worker's strike at Bottom Line Corp."
   ],
   "life": [
    "As a young woman during World War II, Astrid hid Jewish children in the basement of her mother's restaurant. She devoted the remainder of her life to helping others. Eventually, she met and married Giovanni. Though she deeply loved him, the two had a tumultuous relationship. Despite Giovanni regularly being unfaithful, she found it difficult to separate herself from him.",
    "Stella met Astrid and her husband while she was a teenager living in France. The couple became surrogate grandparents to her, as Stella never knew her own."
   ],
   "everdoor": [],
   "image": "e/e4/Astrid_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "unite",
    "feed-your-elders",
    "three-sisters",
    "junior-architect",
    "bars-of-gold",
    "a-second-wind",
    "humble-abode",
    "i-have-my-doubts",
    "lovers-for-life",
    "past-lovers",
    "retrograde",
    "something-to-write-home-about"
   ]
  },
  {
   "id": "atul",
   "name": "Atul",
   "species": "Frog",
   "origin": "barkensheim-creek",
   "originText": "Barkensheim Creek",
   "house": "Atul's Workshop",
   "event": "Thunderstorms",
   "favouriteFood": "Pork Chops",
   "likes": "Everything!",
   "dislikes": "Nothing",
   "skills": "",
   "flower": "White Lily",
   "firstQuest": "Sticky Fingers",
   "lastQuest": "Uncle's Gone?",
   "about": [
    "Atul is a Spirit found in Spiritfarer. As stubborn as he is joyful, Atul is very handy, loves water and would never pass up a good (or bad) meal. Being on this boat with all of his fellow passengers really makes him miss his family, but it doesn't get him down too often."
   ],
   "life": [
    "Atul was Stella’s paternal uncle. He moved to north-eastern France at the same time as Stella and her parents, before they settled a decade later across the Atlantic Ocean. As a true handyman, he occupied various technical functions in many construction fields until he found his true vocation: union leader, fighting for the rights of disparaged workers.",
    "Atul took great pride in teaching Stella all he could about life’s little things, from fishing to cooking, to simply sitting and enjoying the sunset. As cheerful and petulant as could be, Atul hid an emotional hole that unfortunately could not be filled, regardless of all the love he received, no matter how sensational the gourmet food he ate was.",
    "While Stella was still in Europe in her early twenties, Atul disappeared without a trace. This was a great shock to Stella, and she never truly learned what had happened to him. His disappearance was one of the reasons Stella decided to move to North America with her mother Marie, and her sister Lily."
   ],
   "everdoor": [],
   "image": "e/ea/Atul_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "sticky-fingers",
    "welcome-aboard",
    "sea-master-2000",
    "the-drawing-board",
    "woodwork",
    "measure-twice-cut-once",
    "atuls-workshop-quest",
    "spice-up-your-life",
    "movie-night",
    "big-stove",
    "local-union-2187",
    "fishing-trip",
    "family-style",
    "sous-chef-extraordinaire",
    "au-pied-de-grenouille",
    "uncles-gone",
    "the-ice-breaker",
    "the-sommelier"
   ]
  },
  {
   "id": "beverly",
   "name": "Beverly",
   "species": "Tiny owl",
   "origin": "oxbury",
   "originText": "Oxbury",
   "house": "Beverly's Farmhouse",
   "event": "",
   "favouriteFood": "Laksa",
   "likes": "Exotic, Old-fashioned",
   "dislikes": "Acquired Taste, Stimulants",
   "skills": "Knitting",
   "flower": "Anemone",
   "firstQuest": "The One from Downstairs",
   "lastQuest": "Dusting Off Old Ghosts",
   "about": [
    "Beverly is a Spirit found in Spiritfarer. She was released on August 31st in the Summer 2021 update."
   ],
   "life": [
    "Beverly is Stella's old neighbor. She'd been rather lonely on Oxbury and is eager to join Stella and reminisce about the past with someone familiar. She first mentions 3 people, Henry, Sarah and David. Henry and Sarah are her children, and David her husband, who passed before her. David was a math teacher for a high school named Chelsea High. Beverly met David on a blind date, as her friend Pauline, who was the school's secretary, matched them up. She also mentions that her family house was designed by a professional architect, yet had to sell it when she was alone, as her children had moved out. The house was a cozy little farmhouse and it meant the world to her. Beverly had many friends that she mentions very often, and she loves to tell stories to Stella.",
    "Stella and Beverly met as neighbors when Beverly moved to the city after selling her farmhouse. It seems that as she got older, her memory started to fade, and began to forget names and recent events, causing her to repeat the same things to Stella over and over again."
   ],
   "everdoor": [],
   "image": "9/99/Beverly.png/revision/latest",
   "dlc": true,
   "quests": [
    "the-one-from-downstairs",
    "the-beginning-and-the-end",
    "cooking-with-fire",
    "family-vacation",
    "dish-the-dirt",
    "like-father-like-son",
    "dusting-off-old-ghosts"
   ]
  },
  {
   "id": "bruce-mickey",
   "name": "Bruce & Mickey",
   "species": "Hummingbird and Bull",
   "origin": "southpoint-docks",
   "originText": "Southpoint Docks",
   "house": "Bruce and Mickey's Crib",
   "event": "Pulsar Rays",
   "favouriteFood": "Garlic Bread",
   "likes": "Pub food",
   "dislikes": "One ingredient food, Allergic to crustacean",
   "skills": "",
   "flower": "Fennel",
   "firstQuest": "Bullying for Beginners",
   "lastQuest": "Brothers Until the End",
   "about": [
    "Bruce and Mickey are Spirit characters in Spiritfarer.",
    "Bruce (the hummingbird) does all the talking throughout the Journey. He speaks in a more tough manner, and will reminisce about their previous lavish life which eventually leads into them requesting a mansion (Bruce and Mickey's Crib) to be built."
   ],
   "life": [
    "Bruce and Mickey are two very odd patients most likely from just outside of Boston that Stella encounters during her senior year as an end-of-life care nurse. Mickey, an imposing and intimidating behemoth of a man, ends up in a coma after his drunk-driving leads to a car accident. His brother Bruce never leaves his side, accompanying him in the most extreme, dangerous, and illegal activities. The two of them are inseparable and, at Mickey’s arrival in Stella’s care, become a staple of the ward for many months.",
    "It is implied that Bruce may have committed suicide, which is suggested in the Everdoor dialogue.",
    "Bruce always talks “on behalf” of his brother, in denial that Mickey simply is not there anymore. Incapable of coming to terms with the fact that his brother, while technically alive, is not coming back, Bruce makes outlandish requests and angry or rude comments while aboard the ship, showing his pain."
   ],
   "everdoor": [],
   "image": "f/f2/Bruce_%26_Mickey.png/revision/latest",
   "dlc": false,
   "quests": [
    "bullying-for-beginners",
    "the-rhythm-of-the-night",
    "smash-smash",
    "mini-palace",
    "lifestyles-of-the-rich-and-famous",
    "a-taste-of-home",
    "camping-in-a-cadillac",
    "mask-off",
    "brothers-until-the-end"
   ]
  },
  {
   "id": "buck",
   "name": "Buck",
   "species": "Basilisk",
   "origin": "hikarishima-lighthouse",
   "originText": "Hikarishima Lighthouse (after getting the Bounce Ability)",
   "house": "Buck's Lair of Wonders",
   "event": "Shadow Steel Orcs",
   "favouriteFood": "Tomato Pizza",
   "likes": "Comfort food, Old-fashioned food",
   "dislikes": "Lactose intolerant, Fruit",
   "skills": "",
   "flower": "None",
   "firstQuest": "A Lair of Wonders",
   "lastQuest": "Looter's Literary Review",
   "about": [
    "Buck is a spirit character of Spiritfarer.",
    "He can be found atop Hikarishima Lighthouse after unlocking the bounce ability, and is the only spirit character that cannot be released at the Everdoor.",
    "Buck will be the last spirit on your ship and will keep you company until the end of the game. He will entertain any completionists by offering mini errand quests after the final spirits depart. He will not have a quest that ends with taking him through the Everdoor."
   ],
   "life": [
    "In a strange way, Buck has already passed on when Stella meets him. In Stella’s life, Buck was her sister Lily’s friend who died in his teenage years. Stella remembers Lily’s recounting of many of Buck’s stories, after his death. Although Stella never actually met him in life, his story fascinated her, as well as the geeky personality Lily described when she talked about him. Buck’s habits of escaping his reality through tabletop RPG’s led Stella to believe, in a very peculiar way, that his attunement with the end of his life defined him. This made her fall in love with Role Playing Games, idealizing Buck in the process."
   ],
   "everdoor": [],
   "image": "5/55/Buck.png/revision/latest",
   "dlc": false,
   "quests": [
    "a-lair-of-wonders",
    "the-silver-company",
    "demons-of-light",
    "the-fires-of-tondor",
    "looters-literary-review",
    "the-lizard-king",
    "visions-of-oil"
   ]
  },
  {
   "id": "daria",
   "name": "Daria",
   "species": "Bat",
   "origin": "overbrook",
   "originText": "Overbrook",
   "house": "",
   "event": "Mind Palace",
   "favouriteFood": "Apple",
   "likes": "Fresh fruit",
   "dislikes": "Everything else",
   "skills": "",
   "flower": "Saffron",
   "firstQuest": "The Old Guitarrist",
   "lastQuest": "Impression, Sunrise",
   "about": [
    "Daria is a Spirit character released on December 12th in the Fall 2021 update.",
    "She is a patient at an old run-down hospital in Overbrook. Her caretaker is Jackie.",
    "Daria experiences several mental and physical symptoms, including catatonia. She also discusses hearing voices that no one else can hear, suggesting auditory hallucinations. These symptoms led to her being institutionalized in young adulthood. Reaching Daria is challenging, as her room is at the top of a crumbling lighthouse in Overbrook, and the door is often guarded by Jackie. Playing through Jackie's quests will allow Stella increasing amounts of access to Daria."
   ],
   "life": [],
   "everdoor": [],
   "image": "c/cc/Daria.png/revision/latest",
   "dlc": true,
   "quests": [
    "the-old-guitarist",
    "hot-still-scape-for-six-colors",
    "the-night-watch",
    "the-raft-of-the-medusa",
    "the-titanic-days",
    "the-great-wave",
    "the-last-supper",
    "rooms-by-the-sea",
    "impression-sunrise"
   ]
  },
  {
   "id": "elena",
   "name": "Elena",
   "species": "Dog",
   "origin": "crows-end-inc",
   "originText": "Crow's End Inc.",
   "house": "Elena's Cubicle",
   "event": "Deadly Pulsar Rays, Severe Thunderstorm, Gold Dragon",
   "favouriteFood": "Green Salad",
   "likes": "Plain food, Healthy food",
   "dislikes": "Fine Dining food, Meat, Fried food",
   "skills": "",
   "flower": "Cypress",
   "firstQuest": "The Dog Whisperer",
   "lastQuest": "Postscripta",
   "about": [
    "Elena is a studious, teacher-like spirit. She is hard on Stella, putting her through several challenges without any praise, and criticizing her when she fails.",
    "Upon completing these challenges, Stella is rewarded with 10 treasure maps which lead to important treasures of hers. Elena then instructs her to choose one of these to give up on.",
    "In her lifestyle, Elena emphasizes on simplicity, ridding herself of unnecessary belongings and sentiments, as evidenced by her preference in food, lodging and her aversion towards hugs. She also expects the same behavior from those under her tutelage."
   ],
   "life": [
    "In life, Elena was a teacher. She worked in a school that made sure everyone would pass. It was the kind of school that's main lesson was that \"money can buy everything\". She was never impressed by any student that had come through her classroom, no one was focused enough for her. They were distracted, talkative, doing anything but paying attention to what Elena would attempt to teach. In her mind, there is one memorable day from her life. A student had come back from a rowdy gym class; it was Elena's first year on the job and the student was fuming. She was told to \"shape the mind\" of the youths who came through the halls. Though she tried to control them, they were too rowdy and wouldn't sit still. That day she snapped and screamed at the student. It was the first time that they listened. Elena had told them truths that would only reveal themselves later in life, truths that only came after losing someone or something dear to you. She focused on talent and excellence, to never let herself lose her resolve again. Elena hadn't ever felt useful to the gifted students, nor did she like breaking the spirit of the weaker students. She disliked seeing them just struggle as she tried to teach them, because they didn't know why she challenged them. She says she challenged them due to the fact that they never listened, which to Elena, is the easiest thing. But it was her favourite thing, she knew that eventually these students would learn. They would learn through the hardships and know how to survive, how to be better and how to become leaders.",
    "Though she did have a favorite student named among . She was determined to get that scholarship that Elena would coach her as she saw the potential. However she did not get the scholarship and was devastated as she said it was a number's game.",
    "Elena was one of Stella's final patients. While the cause of her death is unknown, the diagnosis that lead to her palliative care was extremely fatal and progressed rapidly."
   ],
   "everdoor": [],
   "image": "a/af/Elena_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "the-dog-whisperer",
    "missing-credentials",
    "elenas-dharma",
    "four-walls-a-roof",
    "on-the-sea-of-tranquility",
    "postscripta"
   ]
  },
  {
   "id": "giovanni",
   "name": "Giovanni",
   "species": "Lion",
   "origin": "loneberg",
   "originText": "Loneberg",
   "house": "None",
   "event": "Meteor Shower",
   "favouriteFood": "Beef Fondue",
   "likes": "Fine dining food, Stimulants",
   "dislikes": "Anything with Eggs, Carbs",
   "skills": "Finds valuables",
   "flower": "Borage",
   "firstQuest": "Indiscreet Shopping",
   "lastQuest": "One Last Drink for the Road",
   "about": [
    "Giovanni is a lion with dark purple/grey fur. His mane is very thick, covering most of his body and is adorned with borages on his neck.",
    "Before this, he had a very prominent nose but was already balding when he was under Stella's care."
   ],
   "life": [
    "Giovanni fought in World War II in the Resistance, then carved for himself an ordinary life of trade and simple pleasures. Extremely careful with his appearance and his witty one liners, Giovanni always made sure to do everything in his power to charm everyone around him, even if it sometimes involved doing shady things just to win someone’s heart. Up until his death by heart attack, Giovanni stood by his “Carpe Diem” motto. He understood the pain he had caused Astrid, without being truly sorry about it.",
    "The charm and bravado however can be seen as a façade as seen through his Everdoor dialogue, that he had to be the funny guy and charm everyone he meets but he knows that they only really came for Astrid."
   ],
   "everdoor": [],
   "image": "5/50/Giovanni_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "indiscreet-shopping",
    "indiscreet-meeting",
    "a-place-for-strangers",
    "one-last-drink-for-the-road"
   ]
  },
  {
   "id": "gustav",
   "name": "Gustav",
   "species": "Owl",
   "origin": "furogawa",
   "originText": "Furogawa",
   "house": "Gustav's Gallery",
   "event": "Fireflies",
   "favouriteFood": "Surstromming",
   "likes": "Acquired Taste, Exotic food",
   "dislikes": "Fried foods, Sweet foods",
   "skills": "Gifts valuables, Making Sushi",
   "flower": "Poppy",
   "firstQuest": "Five Views of Mount Furogawa",
   "lastQuest": "The Old Violinist",
   "about": [
    "Gustav is a tall, dark brown owl with red highlights. His Spirit Flower is positioned in the center of his chest."
   ],
   "life": [
    "As Stella travelled through Japan as a young adult, emancipated and in control of her life for the first time, she met Gustav. A German art curator who spent time teaching Stella nuances and invited her to his art gallery in Shirakawa-gō, Gustav had a brilliant career that led him to travel the world, curating exhibitions for a multitude of museums and galleries. His extensive knowledge of art, history, and architecture sometimes makes him come across as a smug intellectual.",
    "At a relatively young age, Gustav developed multiple sclerosis. His condition physically paralyzed him, but left him with a clear mind. He continued working as much as he could, but his condition stifled his career, soured his mood, and forced his mind towards more contemplative subjects.",
    "It can be assumed that this disease was what ultimately killed Gustav."
   ],
   "everdoor": [],
   "image": "1/11/Gustav_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "five-views-of-mount-furogawa",
    "taill-dans-lor-massif",
    "fully-loaded",
    "lock-and-load",
    "the-house-of-bau",
    "the-master-forger",
    "the-old-violinist",
    "the-search-for-erich-deskmann"
   ]
  },
  {
   "id": "gwen",
   "name": "Gwen",
   "species": "Deer",
   "origin": "alt-harbor",
   "originText": "Alt Harbor",
   "house": "Gwen's Lodge",
   "event": "Jellyfish",
   "favouriteFood": "Black Coffee",
   "likes": "Comfort Food, Fine Dining",
   "dislikes": "Anything with shellfish, Fruit",
   "skills": "Weaving",
   "flower": "Asphodel",
   "firstQuest": "Personal Connection",
   "lastQuest": "One Last Time",
   "about": [
    "Gwen is a tall, reddish-brown deer with three sets of ears. Her spirit flower is worn on her shoulders. In life, Gwen had a short bob cut as an adult."
   ],
   "life": [
    "Gwen’s parents had been friends with Stella’s family long before they moved to North America. As such, Gwen had been one of the very few constants in Stella’s life up to adulthood. Gifted with a brilliant mind and a pragmatic attitude, she had a mischievous side. Being a couple of years older than Stella, Gwen had always been a big sister figure for her; one who would always nudge her towards self-affirmation and taking the risks she otherwise wouldn’t dare to take on her own. She lived with Stella and Lily in France during their childhood.",
    "Heir to an aristocratic but mostly dysfunctional family, Gwen had a difficult relationship with her father. He was proud of his daughter, but would often distastefully parade her and her intelligence as a way to receive self-aggrandizement. This was exacerbated by her father leaving Gwen and her mother at a fairly young age, to live with his boyfriend, Doug. Gwen only talked to the accountant a few times, including for several hours when her father died, and then never again.",
    "Symbolic of her rebellious nature and her opposition to a guardian she had to call “Father”, Gwen picked up smoking at a very young age. Yet, despite all her courage and bravado, she never mustered the courage to smoke publicly or in front of him. Ironically, smoking is what eventually killed Gwen, when she passed from lung cancer in her 40s. As she reached the final stage of her disease, Gwen travelled back to her parent’s manor in Northern Italy’s Alpine Lakes region and considered attempting suicide.",
    "Ultimately, Stella reached out to her at that moment, and succeeded in helping Gwen accept her fate rather than taking her own life."
   ],
   "everdoor": [],
   "image": "5/5e/Gwen_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "personal-connection",
    "set-sail-captain",
    "i-get-cranky-when-im-hungry",
    "seeds-for-the-future",
    "the-more-the-merrier",
    "usonia-1",
    "cut-from-the-same-cloth",
    "basic-moves",
    "back-to-the-past",
    "more-than-meets-the-eye",
    "pretty-on-the-inside",
    "taking-time-off",
    "i-must-be-off",
    "one-last-time",
    "spring-feet"
   ]
  },
  {
   "id": "jackie",
   "name": "Jackie",
   "species": "Hyena",
   "origin": "overbrook",
   "originText": "Overbrook",
   "house": "Jackie's On-Call Room",
   "event": "Cosecha de miel",
   "favouriteFood": "Chilaquiles",
   "likes": "Meat, Fried Food",
   "dislikes": "Healthy Food",
   "skills": "Harvesting honey",
   "flower": "Red dahlia",
   "firstQuest": "Snack Attack",
   "lastQuest": "The Depths of the Pit",
   "about": [
    "Jackie is a Spirit character released on December 13th in the Fall 2021 update.",
    "He is a large, jovial, mixed-race caretaker at an old run-down hospital in Overbrook. His main patient is Daria. He worked with Stella when she was a nurse and he was an orderly, and envied her constant positivity and ability to deal with tough patients. Jackie, while personable and outgoing, neglected many of his orderly duties, leading to an accident with Daria and his eventual firing.",
    "Jackie stands in as a foil to Stella's above-and-beyond nursing, in which she takes small requests from patients (and as the Spiritfarer) and performs them to the best of her abilities, ensuring the comfort and peace of all her patients, regardless if they are rude to her. While Stella is dedicated if overwhelmed (especially by younger patients such as Stanley), Jackie is burned out and lackluster about his job commitment, even going so far as to say \"Why do I even do this?\" followed by \"everybody keeps thanking me\" and \"what else would I do?\" While Stella treats her nursing as a vocation, Jackie treats his work as an orderly as an imposition."
   ],
   "life": [],
   "everdoor": [],
   "image": "b/ba/Jackie_Updated.png/revision/latest",
   "dlc": true,
   "quests": [
    "snack-attack",
    "onboarding",
    "the-slop-shop",
    "wells-fartgo-co",
    "advanced-snackology",
    "slop-n-slide",
    "hide-and-seek",
    "house-call",
    "engineering-101",
    "the-incident",
    "threes-company",
    "a-heart-sized-desert",
    "feelin-the-buzz",
    "hang-in-there-skeleton",
    "hello-my-name-is-jackie",
    "letting-it-go-for-dummies",
    "perimeter-sweep",
    "the-depths-of-the-pit"
   ]
  },
  {
   "id": "lily",
   "name": "Lily",
   "species": "Butterflies",
   "origin": null,
   "originText": "Stella's Boat",
   "house": "",
   "event": "",
   "favouriteFood": "",
   "likes": "",
   "dislikes": "",
   "skills": "",
   "flower": "",
   "firstQuest": "Time Abroad",
   "lastQuest": "To Tundra",
   "about": [
    "Lily is the spirit manifestation of Stella's younger sister, unlocked after the third/final visit with Hades. She was released on April 20th in the Spring 2021 update.",
    "Lily serves as a narrator for the definitive exposition of Stella's memories collected on her three visits to Hades. Going from shrine to shrine at night, the audience learns of Stella's life and personality through Lily's recollection.",
    "Lily is Stella's foil, representing the softer sides to excited, compassionate, outgoing Stella. Lily admits she is more reserved, and was in awe of her sister's natural charisma. Upon their father contracting a terminal illness, Lily was present through the worst parts of it, watching him suffer, while Stella was in Japan on vacation. When Stella returned she looked at her father \"as if, for a moment, [she] didn't even know him.\""
   ],
   "life": [],
   "everdoor": [],
   "image": "0/0a/Lily.png/revision/latest",
   "dlc": true,
   "quests": [
    "time-abroad",
    "striking-out-on-my-own",
    "family-ties",
    "to-tundra",
    "stellas-last-voyage"
   ]
  },
  {
   "id": "stanley",
   "name": "Stanley",
   "species": "Mushroom",
   "origin": null,
   "originText": "Mystery Seed",
   "house": "Stanley's Playroom",
   "event": "Dust Shades",
   "favouriteFood": "French Fries",
   "likes": "Breakfast, Dessert",
   "dislikes": "Veggies, Stimulants, Fruit",
   "skills": "Drawing, Gifting useless items",
   "flower": "Fly Agaric Mushroom",
   "firstQuest": "Big Boy's Room",
   "lastQuest": "Last Vacation",
   "about": [
    "Stanley is very cheerful and will have odd requests compared to many of the other passengers. He will ask you to put odd things in the Foundry, or cook strange items in the Kitchen. He's very curious, and creative and has a passion for putting on plays, drawing and talking to his friend Jacob the beetle.",
    "He enjoys following you around, curious as to what the mighty captain is up to, expressing that he wants to be a captain like yourself when he gets older. He doesn't understand why people are mean sometimes, and can be easily disheartened. However, he always seems to bounce back, and cheer himself up again.",
    "\"I remember what my dad used to say. 'Stanley, people are not really mean. Sometimes their intentions just take the wrong path.'\" - Stanley"
   ],
   "life": [
    "Stanley is a wonderful 8-year-old boy who met Stella as he was losing his fight against a fatal disease. Cheerful and whimsical, Stanley is gifted with an analytical mind which allows him to crack one-liners and aphorisms. His wisdom makes full grown adults blush in humility.",
    "As the youngest patient Stella ever had to take care of, Stan left an unforgettable imprint on her. He helped her realize that death can take many forms, and that wisdom and peace of mind can be found in the most unusual patients."
   ],
   "everdoor": [],
   "image": "2/2b/Stanley_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "big-boys-room",
    "dr-splashs-strange-experiments",
    "junior-architectural-designer",
    "mysterious-word",
    "its-alive",
    "a-play-in-one-act",
    "the-reviews-are-in",
    "last-vacation"
   ]
  },
  {
   "id": "summer",
   "name": "Summer",
   "species": "Snake",
   "origin": "hummingberg",
   "originText": "Hummingberg",
   "house": "Summer's Sanctuary",
   "event": "Dragons",
   "favouriteFood": "Grain Salad",
   "likes": "Salads, Desserts",
   "dislikes": "Non vegan food",
   "skills": "Playing music",
   "flower": "Oxeye daisy",
   "firstQuest": "Nature Class",
   "lastQuest": "The Metastatic Coil",
   "about": [
    "Summer is a brownish-green and yellow snake who wears a green cloak. Her Spirit Flower sits just below the hood of the cloak, where her chest would be. The tip of her tail, along with a small loop, comes through a sleeve on the cloak to act as a hand.",
    "In life, she was rather stout and already elderly when under Stella's care."
   ],
   "life": [
    "A true child of the earth, Summer grew up on a midwestern farm, in a very strict household. Her job as an agronomic engineer led her to work with large farming corporations, where she developed breast cancer due to their heavy use of chemicals. Her sickness prompted her to leave her town behind, to heal. That is how she met Rose, the love of her life, and Stella's aunt.",
    "During her recovery, Summer developed an interest in biodynamic farming. Her journey toward better health also led her to embrace her more spiritual side. It is at that point in her life that she vowed to live every day in the glow of what she called the universal love. With Rose, she built a blooming garden in a remote area for just the two of them. Many happy days were spent in this house they made for themselves, until Rose passed away.",
    "Summer's last decade was filled with struggles. The loss of Rose left her adrift, and without her by her side, she found it hard to take care of herself. Then, when her cancer came back, it was for good. She died with Stella by her side.",
    "Summer was the person who inspired Stella to become a nurse."
   ],
   "everdoor": [],
   "image": "e/ed/Summer_Full.png/revision/latest",
   "dlc": false,
   "quests": [
    "nature-class",
    "jiving-chives",
    "an-old-acquaintance",
    "laying-at-the-ley-line",
    "the-diffracted-cabinet",
    "the-oneness-and-the-wholeness",
    "a-cold-and-dreamless-slumber",
    "the-metastatic-coil"
   ]
  }
 ],
 "abilities": [
  {
   "name": "Double Jump",
   "island": "hummingberg",
   "unlock": "Hummingberg",
   "controls": "While in the air, press [Jump] again to double jump.",
   "details": [
    "Double Jump allows Stella to jump higher and reach previously inaccessible areas. It is the first ability to be unlocked."
   ]
  },
  {
   "name": "Glide",
   "island": "furogawa",
   "unlock": "Furogawa",
   "controls": "While in the air, hold [Jump] to glide.",
   "details": [
    "Glide allows Stella to use air drafts to float upwards to gain height, and to fall down slowly and glide long distances before landing. Obtaining this ability unlocks the Air Draft structure blueprint."
   ]
  },
  {
   "name": "Zipline",
   "island": "nordweiler",
   "unlock": "Nordweiler (requires the Icebreaker boat upgrade to reach)",
   "controls": "Hold [Up] to zipline on ropes and wires.",
   "details": [
    "Zipline allows Stella to slide along hanging ropes or lines. Obtaining this ability unlocks the Zipline structure blueprint."
   ]
  },
  {
   "name": "Bounce",
   "island": "oxbury",
   "unlock": "Oxbury (requires the Rock Destroyer boat upgrade to reach)",
   "controls": "Press [Jump] to jump higher on bouncy surfaces.",
   "details": [
    "Bounce allows Stella to bounce on certain items, such as dumpsters, umbrellas, and window awnings, to gain extra height. Repeated jumping will further increase the height. Obtaining this ability unlocks the Bouncy structure blueprint."
   ]
  },
  {
   "name": "Dash",
   "island": "greymist-peaks",
   "unlock": "Greymist Peaks (requires the Mist Cleaner 1000 boat upgrade to reach)",
   "controls": "Press [Dash] to release Everlight energy and leap forward.",
   "details": [
    "Dash allows Stella to leap forward at great speed, either from the ground or in the air. Dashing depletes the Everlight (turning it darker in appearance) for about 3 seconds before recharging."
   ]
  },
  {
   "name": "Light Burst",
   "island": "hidden-shrine",
   "unlock": "Hidden Shrine (requires Request \"Demons of Light\")",
   "controls": "Press [Light Burst] to release Everlight energy in all directions around you.",
   "details": [
    "Light Burst allows Stella to release a circular burst of light from her Everlight, interacting with specific request- and event-related items in range. This skill is required for Buck's request The Fires of Tondor and Buck's event Shadow Steel Orcs. It is also helpful for catching certain Event targets such as Dust Shades, Pulsar Rays and Jellyfish. Using it depletes the Everlight (turning it darker in appearance) for about 3 seconds before recharging."
   ]
  },
  {
   "name": "Improved Tools",
   "island": "lost-shrine",
   "unlock": "Lost Shrine (requires completing Errand \"Saturday Night Shopping List\", which is available after unlocking Light Burst).",
   "controls": "An Everlight booster that improves both your mining and your fishing.",
   "details": [
    "Improved Tools upgrades Stella's fishing rod and pickaxe. Fishing becomes easier, and a gemstone drops upon mining certain veins.",
    "Mining Coal will yield 1 Diamond",
    "Mining Marble will yield 1 Opal"
   ]
  }
 ],
 "treasures": [
  {
   "x": -58,
   "y": -52,
   "source": "From the Errand \"A Little Bit of Sun\"; the errand appears roughly after visiting Iwashima Countryside",
   "reward": "Foundry Improvement"
  },
  {
   "x": 85,
   "y": 165,
   "source": "From the Mailbox; the mail appears possibly from progressing through Atul's storyline and after having built and used the Crusher. May also be found by accident while traversing these coordinates.",
   "reward": "Sawmill Improvement"
  },
  {
   "x": 220,
   "y": 167,
   "source": "From the Errand \"Saturday Night Shopping List\"; the errand appears after unlocking the Light Burst ability",
   "reward": "Lost Shrine"
  },
  {
   "x": 40,
   "y": -50,
   "source": "From completing one of Elena's challenges",
   "reward": "Rare Coin Collection"
  },
  {
   "x": 34,
   "y": 69,
   "source": "From completing one of Elena's challenges",
   "reward": "Marriage Ring"
  }
 ],
 "busStops": [
  {
   "x": 77,
   "y": 51,
   "near": [
    "alberts-shipyard",
    "alt-harbor",
    "bottom-line-corp",
    "southpoint-docks"
   ]
  },
  {
   "x": 202,
   "y": -59,
   "near": [
    "ambertown-park",
    "edgeborough-lane",
    "old-central-district"
   ]
  },
  {
   "x": 44,
   "y": 119,
   "near": [
    "barkensheim-creek",
    "hummingberg",
    "mosstein-cove"
   ]
  },
  {
   "x": -120,
   "y": -27,
   "near": [
    "crows-end-inc",
    "hikarishima-lighthouse",
    "resuteno-meadows"
   ]
  },
  {
   "x": -1,
   "y": -18,
   "near": [
    "everdoor"
   ]
  },
  {
   "x": 132,
   "y": -94,
   "near": [
    "flotsam-shores",
    "sandwich-walk",
    "sunspring-square"
   ]
  },
  {
   "x": -162,
   "y": 51,
   "near": [
    "furogawa",
    "hoseki-quarry"
   ]
  },
  {
   "x": -63,
   "y": 104,
   "near": [
    "greenhalten-bay",
    "kaltstein-mines",
    "villa-maggiore"
   ]
  },
  {
   "x": -71,
   "y": 31,
   "near": [
    "gurenu-fields",
    "iwashima-countryside",
    "mount-toroyama"
   ]
  },
  {
   "x": -149,
   "y": -104,
   "near": [
    "hidden-shrine"
   ]
  },
  {
   "x": -74,
   "y": -99,
   "near": [
    "hidden-thicket",
    "shadow-forest"
   ]
  },
  {
   "x": -64,
   "y": 196,
   "near": [
    "loneberg"
   ]
  },
  {
   "x": 173,
   "y": 147,
   "near": [
    "lost-shrine",
    "misty-woods"
   ]
  },
  {
   "x": -141,
   "y": 170,
   "near": [
    "nordsee-pier",
    "susans-museum"
   ]
  },
  {
   "x": 25,
   "y": 192,
   "near": [
    "nordweiler"
   ]
  },
  {
   "x": 206,
   "y": 78,
   "near": [
    "obscure-canopy",
    "overbrook"
   ]
  },
  {
   "x": 246,
   "y": 27,
   "near": [
    "oxbury"
   ]
  }
 ],
 "events": [
  {
   "id": "aluminium-dragon",
   "name": "Aluminium Dragon",
   "spirit": "summer",
   "resource": "Aluminium Ore",
   "duration": "",
   "requires": "Icebreaker",
   "house": "None; approach the front of the boat",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -132,
     "y": 134,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "9/90/Aluminium_Ore.png/revision/latest"
  },
  {
   "id": "deadly-pulsar-rays",
   "name": "Deadly Pulsar Rays",
   "spirit": "elena",
   "resource": "Pulsar Ore",
   "duration": "",
   "requires": "Rock Destroyer and Mist Cleaner 1000",
   "house": "Elena's Cubicle",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 194,
     "y": 127,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "This is a harder variant of Pulsar Rays, where the pulsar rays take winding trajectories more often, and Stella's Boat gets bombarded with more pulsar rays.",
    "Elena challenges Stella to collect at least 1/3 of the deadly pulsar rays as a part of the quest Elena's Dharma."
   ],
   "image": "b/b7/Pulsar_Ore.png/revision/latest"
  },
  {
   "id": "dust-shades",
   "name": "Dust Shades",
   "spirit": "stanley",
   "resource": "Bottled Ectoplasm",
   "duration": "",
   "requires": "",
   "house": "Stanley's Playroom",
   "trigger": "manual",
   "island": null,
   "points": [],
   "approx": false,
   "regionText": "",
   "details": [
    "Dust Shades is a manually-triggered Event that can only occur after Stanley's Playroom has been built. Bottled Ectoplasm can be collected after the event is introduced by the Spirit Stanley. Exactly 1 Bottled Ectoplasm will be collected for each Dust Shade that Stella touches during the event.",
    "Like all events, the Dust Shades event can still occur after the Spirit helper leaves through the Everdoor."
   ],
   "image": "c/ce/Bottled_Ectoplasm.png/revision/latest"
  },
  {
   "id": "fireflies",
   "name": "Fireflies",
   "spirit": "gustav",
   "resource": "Fireglow Seed",
   "duration": "",
   "requires": "Icebreaker",
   "house": "Gustav's Gallery",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -98,
     "y": 98,
     "label": ""
    },
    {
     "x": 114,
     "y": -45,
     "label": ""
    },
    {
     "x": 236,
     "y": -49,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "During the event, clouds of fireflies appear on the right side of the screen and move to the left in mostly a straight line. The majority will appear gold in color and reward glim. Occasional red fireflies carrying small square pouches reward Fireglow Seeds."
   ],
   "image": "9/9a/Fireglow_Seed.png/revision/latest"
  },
  {
   "id": "gold-dragon",
   "name": "Gold Dragon",
   "spirit": "elena",
   "resource": "Gold Ore",
   "duration": "",
   "requires": "Rock Breaker",
   "house": "Elena's Cubicle",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 120,
     "y": 111,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "The Gold Dragon is located at [121, 111] in the Hummingberg Region"
   ],
   "image": "f/f7/Gold_Ore.png/revision/latest"
  },
  {
   "id": "jellyfish-stage-i",
   "name": "Jellyfish Stage I",
   "spirit": "gwen",
   "resource": "Bright Jelly x8 (Max)",
   "duration": "~90 seconds",
   "requires": "",
   "house": "Gwen's Lodge",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 81,
     "y": 94,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "Jellyfish will appear from the right of the boat, flying towards the left. Green jellyfish will have a position indicator while off-screen. Touching jellyfish will give rewards.",
    "There are three types of jellyfish:",
    "Small yellow jellyfish give 10 Glims.",
    "Large yellow jellyfish give 25 Glims.",
    "Green jellyfish give Bright Jelly x2.",
    "Before the event starts, you can reposition buildings on the boat up high, to provide ladders to reach jellyfish that appear higher up."
   ],
   "image": "9/91/Bright_Jelly.png/revision/latest"
  },
  {
   "id": "jellyfish-stage-ii",
   "name": "Jellyfish Stage II",
   "spirit": "gwen",
   "resource": "Bright Jelly",
   "duration": "~75 seconds",
   "requires": "",
   "house": "Gwen's Lodge",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 65,
     "y": 161,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "9/91/Bright_Jelly.png/revision/latest"
  },
  {
   "id": "jellyfish-stage-iii",
   "name": "Jellyfish Stage III",
   "spirit": "gwen",
   "resource": "Bright Jelly",
   "duration": "",
   "requires": "",
   "house": "Gwen's Lodge",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -8,
     "y": 94,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "9/91/Bright_Jelly.png/revision/latest"
  },
  {
   "id": "jellyfish-stage-iv",
   "name": "Jellyfish Stage IV",
   "spirit": "gwen",
   "resource": "Bright Jelly",
   "duration": "",
   "requires": "",
   "house": "Gwen's Lodge",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -50,
     "y": 131,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "9/91/Bright_Jelly.png/revision/latest"
  },
  {
   "id": "meteor-shower",
   "name": "Meteor Shower",
   "spirit": "giovanni",
   "resource": "Comet Rock",
   "duration": "",
   "requires": "Rock Breaker",
   "house": "Astrid's Bungalow",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 224,
     "y": 12,
     "label": ""
    },
    {
     "x": 169,
     "y": -54,
     "label": ""
    },
    {
     "x": 221,
     "y": -118,
     "label": ""
    }
   ],
   "approx": true,
   "regionText": "Oxbury Region",
   "details": [
    "Meteor Showers are location-based Events where Comet Rock can be collected after the event is introduced byGiovanni.",
    "Like all events, the Meteor Shower event can still occur after the Spirit helper leaves through the Everdoor. Instead of talking to Giovanni to start the event, it can be started by interacting with the second story door of Astrid's Bungalow."
   ],
   "image": "d/dc/Meteor_Shower_Boat.png/revision/latest"
  },
  {
   "id": "mind-palace",
   "name": "Mind Palace",
   "spirit": "daria",
   "resource": "Radiant Spring",
   "duration": "",
   "requires": "",
   "house": "",
   "trigger": "island",
   "island": "overbrook",
   "points": [
    {
     "x": 212,
     "y": 56,
     "label": "Overbrook"
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "After triggering The Raft of the Medusa quest, Stella can play her guitar in different locations around Overbrook. Everytime she plays Daria's theme in those locations she will be transported to a platforming section representing Daria's mind and, in doing so, she'll learn more about the spirit's life.",
    "After finishing each section Stella will be rewarded some Radiant Spring, which can be used in the Vending Machine to improve Overbrook and to unlock another Mind Palace section."
   ],
   "image": "f/f3/Radiant_Spring.png/revision/latest"
  },
  {
   "id": "nebula-pillbugs",
   "name": "Nebula Pillbugs",
   "spirit": "alice",
   "resource": "Nebula Fibre",
   "duration": "",
   "requires": "",
   "house": "Alice's Cottage",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -117,
     "y": 20,
     "label": ""
    },
    {
     "x": -143,
     "y": 46,
     "label": ""
    },
    {
     "x": -62,
     "y": -20,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "After Alice joins you, the Nebula Pillbugs event can be played.",
    "After heading to one of the locations where the event takes place, a large Nebula Pillbug will hop onto your boat. Speak with Alice to start the event. The Pillbug will release its children over the boat, allowing Stella to run around, collect the baby pillbugs and return them to the mother (giving Stella 1 nebula fiber per bug). Some of the baby pillbugs will glow and run around excitedly; if caught in this state, they return 2 nebula fibers.",
    "Once all the baby pillbugs are caught, the mother will hop off the boat and the event ends."
   ],
   "image": "5/5e/Nebula_Fibre.png/revision/latest"
  },
  {
   "id": "pulsar-rays",
   "name": "Pulsar Rays",
   "spirit": "bruce-mickey",
   "resource": "Pulsar Ore",
   "duration": "",
   "requires": "Rock Destroyer or Mist Cleaner 1000",
   "house": "Bruce and Mickey's Crib",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 156,
     "y": -15,
     "label": ""
    },
    {
     "x": 219,
     "y": -95,
     "label": ""
    },
    {
     "x": 239,
     "y": 87,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "Pulsar Rays are location-based Events where Pulsar Ore can be collected after the event is introduced by the Spirits Bruce & Mickey. Exactly 1 Pulsar Ore will be collected for each Pulsar Ray that Stella touches during the event.",
    "Like all events, the Pulsar Rays event can still occur after the Spirit helper leaves through the Everdoor. Instead of talking to Bruce to start the event, it can be started by interacting with the door to Bruce and Mickey's Crib."
   ],
   "image": "b/b7/Pulsar_Ore.png/revision/latest"
  },
  {
   "id": "quartz-dragon",
   "name": "Quartz Dragon",
   "spirit": "summer",
   "resource": "Quartz",
   "duration": "~80 seconds",
   "requires": "",
   "house": "None; approach the front of the boat",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -24,
     "y": 65,
     "label": ""
    },
    {
     "x": -172,
     "y": 45,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "c/cf/Quartz.png/revision/latest"
  },
  {
   "id": "severe-thunderstorm",
   "name": "Severe Thunderstorm",
   "spirit": "elena",
   "resource": "Lightning in a Bottle",
   "duration": "",
   "requires": "Mist Cleaner 1000",
   "house": "Elena's Cubicle",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -144,
     "y": -79,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "Severe Thunderstorms are an event triggered by having Elena on the ship. Elena challenges Stella to collect at least 1/3 of the lightning strikes as a part of the quest Elena's Dharma.",
    "Much like the usual Thunderstorms activated by Atul's presence on the ship, severe Thunderstorms are slightly faster paced. They are marked as red Thunderstorms on the map, and once completed will refresh within a few days. Completing them successfully will improve Elena's mood (\"Elena is impressed by your work ethic\")."
   ],
   "image": "5/54/Lightning_in_a_Bottle.png/revision/latest"
  },
  {
   "id": "shadow-steel-orcs",
   "name": "Shadow Steel Orcs",
   "spirit": "buck",
   "resource": "XP Potion",
   "duration": "",
   "requires": "",
   "house": "Buck's Lair of Wonders",
   "trigger": "manual",
   "island": null,
   "points": [],
   "approx": false,
   "regionText": "",
   "details": [
    "Shadow Steel Orcs is a manually-triggered Event where XP Potion can be collected after the event is introduced by the Spirit Buck. Exactly 1 XP Potion will be collected for each corrupted Shadow Steel Orc that Stella defeats during the event.",
    "Corrupted Orcs can be identified by their dark aura, and can only be defeated using Light Burst. Regular Orcs can be defeated by bumping into them or using Light Burst, and they only reward Glim.",
    "The Spirit helper never leaves through the Everdoor (see Buck for more details)."
   ],
   "image": "9/9d/XP_Potion.png/revision/latest"
  },
  {
   "id": "silver-dragon",
   "name": "Silver Dragon",
   "spirit": "summer",
   "resource": "Silver Ore",
   "duration": "",
   "requires": "Rock Destroyer",
   "house": "None; approach the front of the boat",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 188,
     "y": -44,
     "label": ""
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [],
   "image": "9/97/Silver_Ore.png/revision/latest"
  },
  {
   "id": "thunderstorm",
   "name": "Thunderstorm",
   "spirit": "atul",
   "resource": "Lightning in a Bottle",
   "duration": "~80 seconds",
   "requires": "",
   "house": "Atul's Workshop",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": -40,
     "y": 85,
     "label": ""
    },
    {
     "x": 26,
     "y": 107,
     "label": ""
    },
    {
     "x": -30,
     "y": 5,
     "label": ""
    },
    {
     "x": 28,
     "y": 13,
     "label": ""
    },
    {
     "x": 126,
     "y": 40,
     "label": ""
    },
    {
     "x": 168,
     "y": 40,
     "label": ""
    },
    {
     "x": 86,
     "y": -49,
     "label": ""
    },
    {
     "x": 176,
     "y": -149,
     "label": ""
    },
    {
     "x": 276,
     "y": -84,
     "label": ""
    }
   ],
   "approx": true,
   "regionText": "Hummingberg Region, Oxbury Region",
   "details": [
    "Atul will go to a location near-ish to Stella and will start to play his flute, then small circles of lightning will appear around Stella. The lightning within the circle will grow with time. When you go into the circle, the lightning will come down and Stella will hold a bottle to the sky, and you get Glim and often Lightning in a Bottle."
   ],
   "image": "5/54/Lightning_in_a_Bottle.png/revision/latest"
  },
  {
   "id": "turtle-sisters",
   "name": "Tortoise Sisters",
   "spirit": "astrid",
   "resource": "Whatever is \"planted\"",
   "duration": "",
   "requires": "Icebreaker, Rock Destroyer",
   "house": "None; just walk to the front of the boat.",
   "trigger": "sea",
   "island": null,
   "points": [
    {
     "x": 81,
     "y": 28,
     "label": "Olga"
    },
    {
     "x": -91,
     "y": 138,
     "label": "Masha"
    },
    {
     "x": 127,
     "y": -76,
     "label": "Irina"
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "The three tortoise sisters; Olga, Masha, and Irina; are giant tortoises and points of interest that act as farms for wood or certain minerals.",
    "Stella can \"plant\" something in each of the three nodes on the back of each of the tortoises. If a log was planted then a tree of the respective type will grow, and if a mineral was planted then a rock of the respective type will grow. After planting items in the nodes, Stella can talk with the tortoise to confirm she is done, after which the tortoise will disappear underwater and reappear some time later when the trees or rocks are finished growing."
   ],
   "image": ""
  },
  {
   "id": "vending-machine",
   "name": "Vending Machine",
   "spirit": null,
   "resource": "Chocoblasterz, Crackers for Animals, Crispy Burlap Men, Health Nuts, Loose Spices, Muriel's Sticky Toffee, Space Sticks",
   "duration": "",
   "requires": "",
   "house": "",
   "trigger": "island",
   "island": "overbrook",
   "points": [
    {
     "x": 212,
     "y": 56,
     "label": "Overbrook"
    }
   ],
   "approx": false,
   "regionText": "",
   "details": [
    "The Vending Machine is a device available at Overbrook which, when interacted with, restores a portion of the hospital whereabouts, unlocking the next event and progressing Jackie's and Daria's quests.",
    "Each item can only be bought once."
   ],
   "image": "8/83/Chocoblasterz.png/revision/latest"
  }
 ],
 "quests": [
  {
   "id": "a-chilling-realisation",
   "title": "A Chilling Realisation",
   "number": "1409",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice, in a confused manner, asked me to find Eugene and tell him to bring her her \"old woolly.\" Maybe I can find what she meant by it, and bring her some other thing instead?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "taking-the-low-road"
   ],
   "next": [],
   "objectives": [
    {
     "text": "What did Alice mean by \"old woolly\"... A blanket maybe? A piece of fabric? I should find out and give it to her.",
     "depth": 1
    }
   ],
   "notes": [
    "Bring Alice a piece of Wool Fabric",
    "This quest is optional, and will go away when she does."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-coat-of-wool",
   "title": "A Coat of Wool",
   "number": "1403",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "We have a new passenger aboard... it's a sheep. Alice wants me to shear the wool off its back! Let's go put my barber skills to work.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Key for Mount Toroyama's House",
    "Ability to shear Sheep"
   ],
   "repeatable": false,
   "prev": [
    "the-coziest-cottage"
   ],
   "next": [
    "a-spot-for-pots"
   ],
   "objectives": [
    {
     "text": "Shear a sheep.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-cold-and-dreamless-slumber",
   "title": "A Cold and Dreamless Slumber",
   "number": "1307",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has fallen asleep several days ago, and shows no sign of waking up any time soon. I have to find a way to bring her back with us.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-oneness-and-the-wholeness"
   ],
   "next": [
    "the-metastatic-coil"
   ],
   "objectives": [
    {
     "text": "Figure out what is wrong with Summer. Albert the Shipwright might be able to help.",
     "depth": 1
    },
    {
     "text": "Improve Summer's Sanctuary with the HVAC system.",
     "depth": 1
    },
    {
     "text": "Talk to Summer when she wakes up.",
     "depth": 1
    }
   ],
   "notes": [
    "One of the other passengers will ask about Summer, initiating this quest. It’s not necessarily the same person in each save."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-heart-sized-desert",
   "title": "A Heart-Sized Desert",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie did not react very well to the motivational posters. He thinks that a sand garden would help him be more at peace.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "hang-in-there-skeleton"
   ],
   "next": [
    "letting-it-go-for-dummies"
   ],
   "objectives": [
    {
     "text": "Talk to Jackie",
     "depth": 1
    },
    {
     "text": "Improve Jackie's On-Call Room (Zen Garden)",
     "depth": 1
    },
    {
     "text": "Cost: 1300 Glims",
     "depth": 2
    },
    {
     "text": "Build Materials:",
     "depth": 2
    },
    {
     "text": "12 Pine Planks",
     "depth": 3
    },
    {
     "text": "1 Steel Sheet",
     "depth": 3
    },
    {
     "text": "16 Silk Fabric",
     "depth": 3
    },
    {
     "text": "Talk to Jackie again",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-lair-of-wonders",
   "title": "A Lair of Wonders",
   "number": "2001",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "Another passenger. Another house. From the sound of it, this one is complicated.",
   "prereq": "Requires the Mist Cleaner 1000 to unlock.",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "the-silver-company"
   ],
   "objectives": [
    {
     "text": "Buy the blueprint for Buck's Room from the merchant Edgeborough Lane.",
     "depth": 1
    },
    {
     "text": "Talk to Buck.",
     "depth": 1
    },
    {
     "text": "Build Buck's Lair of Wonders.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 1,
     "why": "Buy the blueprint for Buck's Room from the merchant Edgeborough Lane.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-place-for-strangers",
   "title": "A Place for Strangers",
   "number": "1603",
   "type": "Requests",
   "giver": "Giovanni",
   "spirit": "giovanni",
   "description": "A Lounge does sound nice. A calm place for the passengers. Maybe they'll stop asking me for things all the time.",
   "prereq": "Requires completion of Retrograde.",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "indiscreet-meeting"
   ],
   "next": [
    "one-last-drink-for-the-road"
   ],
   "objectives": [
    {
     "text": "Build the Lounge.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-play-in-one-act",
   "title": "A Play In One Act",
   "number": "1807",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley wants to throw a play. It's going to be a long day.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "its-alive"
   ],
   "next": [
    "the-reviews-are-in"
   ],
   "objectives": [
    {
     "text": "Invite your favourite friends to Stanley's play.",
     "depth": 1
    },
    {
     "text": "Head over to Oxbury.",
     "depth": 1
    },
    {
     "text": "Watch Stanley's play.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 2,
     "why": "Head over to Oxbury.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-second-wind",
   "title": "A Second Wind",
   "number": "1509",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Maybe I should give Astrid some space. She is dealing with a lot.",
   "prereq": "Requires One Last Drink for the Road to be complete",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "retrograde"
   ],
   "next": [
    "lovers-for-life"
   ],
   "objectives": [
    {
     "text": "Let Astrid live her best life.",
     "depth": 1
    },
    {
     "text": "(This Request completes after six in-game days elapse.)",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-spot-for-pots",
   "title": "A Spot for Pots",
   "number": "1404",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice would like to help with the cooking duties, and thus advised me to improve the kitchen.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "a-coat-of-wool"
   ],
   "next": [
    "of-warts-and-ropes"
   ],
   "objectives": [
    {
     "text": "Improve the Kitchen with an upgraded stove.",
     "depth": 1
    }
   ],
   "notes": [
    "Between this quest and Big Stove, only one can be triggered in a single save file."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "a-taste-of-home",
   "title": "A Taste of Home",
   "number": "1906",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "Bruce & Mickey need me to make them food. I hope I don't screw up their order.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "lifestyles-of-the-rich-and-famous"
   ],
   "next": [
    "camping-in-a-cadillac"
   ],
   "objectives": [
    {
     "text": "Give Bruce a Lobster Roll",
     "depth": 1
    },
    {
     "text": "Give Bruce Fried Chicken",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "advanced-snackology",
   "title": "Advanced Snackology",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has informed me that the vending machine at Overbrook Hospital has been restocked. I should go back and take a look!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Pager"
   ],
   "repeatable": false,
   "prev": [
    "wells-fartgo-co"
   ],
   "next": [
    "slop-n-slide"
   ],
   "objectives": [
    {
     "text": "Look at the new stock from the vending machine in Overbrook Hospital.",
     "depth": 1
    },
    {
     "text": "Using an Obol, buy a Crispy Burlap Men protein bar from the vending machine in Overbrook Hospital.",
     "depth": 1
    },
    {
     "text": "Crispy Burlap Men (0/1)",
     "depth": 2
    },
    {
     "text": "Talk to Jackie.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 1,
     "why": "Look at the new stock from the vending machine in Overbrook Hospital.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "an-old-acquaintance",
   "title": "An Old Acquaintance",
   "number": "1303",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has had a vision of a great snake in the middle of the sea. It made her very restless. I should visit the spot she marked on my map as soon as possible.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Quartz Dragon event"
   ],
   "repeatable": false,
   "prev": [
    "jiving-chives"
   ],
   "next": [
    "laying-at-the-ley-line"
   ],
   "objectives": [
    {
     "text": "Visit the spot Summer has marked on the map.",
     "depth": 1
    }
   ],
   "notes": [
    "Summer’s mood will take a hit (-1) from the unsettling dreams until you’ve completed the quest. Once you’ve completed it, she will get a temporary mood penalty (-2 for one day) from witnessing the dragon from her past."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "annies-lost-hat",
   "title": "Annie's Lost Hat",
   "number": "1410",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice doesn't seem to recognize me anymore. I think she is scared of leaving the prow of the boat with me. How can I get her out of there?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Alice's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "taking-the-low-road"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Find a way to shake Alice out of her confusion.",
     "depth": 1
    },
    {
     "text": "Dress as Annie while wearing the red hat.",
     "depth": 2
    },
    {
     "text": "Bring Alice to the Everdoor, and talk to her while wearing Annie's outfit with a red hat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 3,
     "why": "Bring Alice to the Everdoor, and talk to her while wearing Annie's outfit with a red hat.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "apples-and-oranges",
   "title": "Apples and Oranges",
   "number": "1406",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice has fond memories of her past life, surrounded by loving family. She talks passionately about different fruit trees they used to plant. An orchard will definitely cheer her up!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "of-warts-and-ropes"
   ],
   "next": [
    "down-the-rabbit-hole"
   ],
   "objectives": [
    {
     "text": "Build an orchard.",
     "depth": 1
    },
    {
     "text": "Grow a tree in the orchard.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "atuls-workshop-quest",
   "title": "Atul's Workshop",
   "number": "1207",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Time to help out my old uncle. Morale on the boat is pretty bad because of his snoring. A soundproof house could do that trick.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "measure-twice-cut-once"
   ],
   "next": [
    "spice-up-your-life"
   ],
   "objectives": [
    {
     "text": "Build a house for Atul.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "au-pied-de-grenouille",
   "title": "Au pied de grenouille",
   "number": "1215",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "The table is set and everything should be ready for our dinner.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "sous-chef-extraordinaire"
   ],
   "next": [
    "uncles-gone"
   ],
   "objectives": [
    {
     "text": "Head over to Hummingberg.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 1,
     "why": "Head over to Hummingberg.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "back-to-the-past",
   "title": "Back to the Past",
   "number": "1110",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen wants to take a trip down memory lane, visiting her parent's house.",
   "prereq": "Must have Double Jump",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Villa Maggiore coordinates",
    "Key for Villa Maggiore"
   ],
   "repeatable": false,
   "prev": [
    "basic-moves"
   ],
   "next": [
    "more-than-meets-the-eye"
   ],
   "objectives": [
    {
     "text": "Head over to the Villa Maggiore.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen at Villa Maggiore.",
     "depth": 1
    },
    {
     "text": "Find the Loom upgrade in Villa Maggiore.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    },
    {
     "text": "Give the Music Box.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "villa-maggiore",
     "step": 1,
     "why": "Head over to the Villa Maggiore.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "bars-of-gold",
   "title": "Bars of Gold",
   "number": "1504",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Astrid thinks we should have a Foundry on the boat. She said she would show me how to use it.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "junior-architect"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Build a Foundry.",
     "depth": 1
    },
    {
     "text": "Smelt an Ingot in the Foundry.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "basic-moves",
   "title": "Basic Moves",
   "number": "1109",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Apparently, there is a method to this weaving madness. Gwen will surely teach me.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "cut-from-the-same-cloth"
   ],
   "next": [
    "back-to-the-past"
   ],
   "objectives": [
    {
     "text": "Try the Loom.",
     "depth": 1
    }
   ],
   "notes": [
    "Gwen provides Linen Fibre x3 at the start of this Request.",
    "Gwen will get a mood boost (+2) for showing Stella around the loom once this quest has been completed."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "berry-good",
   "title": "Berry Good!",
   "number": "9015",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "Barry wants some berries. I wonder how he got that idea?",
   "prereq": "",
   "location": "Obscure Canopy",
   "onBoat": false,
   "rewards": [
    "Orchard Upgrade"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Find 15 Raspberries.",
     "depth": 1
    },
    {
     "text": "Find 15 Strawberries.",
     "depth": 1
    },
    {
     "text": "Find 15 Blueberries.",
     "depth": 1
    },
    {
     "text": "Talk to Barry.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "obscure-canopy",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "big-boys-room",
   "title": "Big Boy's Room",
   "number": "1802",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley wants something soft for our transformation guest house.",
   "prereq": "Grow a Mysterious Seed",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "dr-splashs-strange-experiments"
   ],
   "objectives": [
    {
     "text": "Give Stanley some Linen Fabric.",
     "depth": 1
    },
    {
     "text": "Give Stanley an old tchotchke.",
     "depth": 1
    },
    {
     "text": "Cannot be an Old Shoe.",
     "depth": 2
    }
   ],
   "notes": [
    "After completing this request, another unnamed request will become available to unlock the ectoplasm event."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "big-stove",
   "title": "Big Stove",
   "number": "1210",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Atul thinks your Kitchen is not up to snuff. You need to step up your culinary game.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "movie-night"
   ],
   "next": [
    "local-union-2187"
   ],
   "objectives": [
    {
     "text": "Improve the Kitchen with an upgraded stove.",
     "depth": 1
    }
   ],
   "notes": [
    "Between this quest and A Spot for Pots, only one can be triggered in a single save file."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "brothers-until-the-end",
   "title": "Brothers Until the End",
   "number": "1909",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "Bruce doesn't seem too happy with my work. I guess it's time for him to chew me out or leave.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Bruce & Mickey's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "mask-off"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Bruce & Mickey to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Bruce & Mickey to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "building-101",
   "title": "Building 101",
   "number": "9001",
   "type": "Shenanigans",
   "giver": "Albert The Shipwright",
   "spirit": null,
   "description": "If this keeps up, I'll be an architect in no time.",
   "prereq": "Part of Set Sail, Captain!",
   "location": "Albert's Shipyard",
   "onBoat": false,
   "rewards": [
    "The Captain’s Log will show boat upgrades."
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Upgrade your blueprint station.",
     "depth": 1
    },
    {
     "text": "Talk to Albert.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alberts-shipyard",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "bullying-for-beginners",
   "title": "Bullying for Beginners",
   "number": "1901",
   "type": "Requests",
   "giver": "Tough Denizens",
   "spirit": "bruce-mickey",
   "description": "This feels wrong. This feels illegal. I'll make it seem like I'm bullying them, but I'll still be nice.",
   "prereq": "Requires the Rock Destroyer",
   "location": "Southpoint Docks",
   "onBoat": false,
   "rewards": [
    "Bruce & Mickey"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "the-rhythm-of-the-night"
   ],
   "objectives": [
    {
     "text": "Find a worker to intimidate.",
     "depth": 1
    },
    {
     "text": "Talk to Bruce and Mickey.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "southpoint-docks",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "camping-in-a-cadillac",
   "title": "Camping in a Cadillac",
   "number": "1907",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "The world isn't big enough for these two. They want to go on vacation with me now.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "2 Obols"
   ],
   "repeatable": false,
   "prev": [
    "a-taste-of-home"
   ],
   "next": [
    "mask-off"
   ],
   "objectives": [
    {
     "text": "Go to Greymist Peaks.",
     "depth": 1
    },
    {
     "text": "Talk to Bruce and Mickey.",
     "depth": 1
    },
    {
     "text": "Talk to Bruce and MIckey on the boat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "greymist-peaks",
     "step": 1,
     "why": "Go to Greymist Peaks.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "cooking-with-fire",
   "title": "Cooking With Fire",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "Beverly wants her favourite food. She said something about \"Fireglow and... that delicious powder of grain.\" What could that be?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-beginning-and-the-end"
   ],
   "next": [
    "family-vacation"
   ],
   "objectives": [
    {
     "text": "Cook a Laksa for Beverly",
     "depth": 1
    },
    {
     "text": "Talk to Beverly",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "cut-from-the-same-cloth",
   "title": "Cut From The Same Cloth",
   "number": "1108",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen has always loved knitting and weaving. Let's make sure she can have fun with this one.",
   "prereq": "Completion of An Old Acquaintance",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "usonia-1"
   ],
   "next": [
    "basic-moves"
   ],
   "objectives": [
    {
     "text": "Build the Loom.",
     "depth": 1
    }
   ],
   "notes": [
    "Completing this quest will give Gwen a permanent mood bonus (+2) for having access to a loom."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "demons-of-light",
   "title": "Demons of Light",
   "number": "2003",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "A shrine in the middle of the ocean. An ancient evil. What are the odds?",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-silver-company"
   ],
   "next": [
    "the-fires-of-tondor"
   ],
   "objectives": [
    {
     "text": "Head over to -185, -92.",
     "depth": 1
    },
    {
     "text": "Acquire the powers of light.",
     "depth": 1
    },
    {
     "text": "Talk to Buck.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hidden-shrine",
     "step": 1,
     "why": "Head over to -185, -92.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "diamonds-are-everybodys-best-friend",
   "title": "Diamonds Are Everybody's Best Friend",
   "number": "9108",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Diamond x1"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "XP Potion x4",
     "depth": 1
    },
    {
     "text": "Bottled Ectoplasm x4",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "dice-boys-presents",
   "title": "Dice Boys presents...",
   "number": "9011",
   "type": "Shenanigans",
   "giver": "Oxbury Rap Crew",
   "spirit": null,
   "description": "This hip-hop act needs a little exposure boost. I'll be their one-person street team!",
   "prereq": "",
   "location": "Oxbury",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Talk to someone in Bottom Line Corp.",
     "depth": 2
    },
    {
     "text": "Talk to someone in Furogawa.",
     "depth": 2
    },
    {
     "text": "Talk to someone in Hummingberg.",
     "depth": 2
    },
    {
     "text": "Talk to the Dice Boys.",
     "depth": 1
    }
   ],
   "notes": [
    "In Oxbury, speak to the small group of spirits to the right of your boat. When they realize you've never heard of them before, they give you a bunch of records of their music to pass on to other people to help them become famous."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 1,
     "why": "Talk to someone in Bottom Line Corp.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 2,
     "why": "Talk to someone in Furogawa.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 3,
     "why": "Talk to someone in Hummingberg.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "dish-the-dirt",
   "title": "Dish the Dirt",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "Beverly believes all the passengers are talking behind her back. Saying nasty things. Let's get to the bottom of this.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "family-vacation"
   ],
   "next": [
    "like-father-like-son"
   ],
   "objectives": [
    {
     "text": "Talk to the other passengers aboard.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "down-the-rabbit-hole",
   "title": "Down the Rabbit Hole",
   "number": "1407",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice asked me if i would accompany her on a trip to Nordweiler. She is excited to see the village, as it reminds her of her Swedish romance novels.",
   "prereq": "Requires the Icebreaker to complete",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Nordweiler coordinates"
   ],
   "repeatable": false,
   "prev": [
    "apples-and-oranges"
   ],
   "next": [
    "taking-the-low-road"
   ],
   "objectives": [
    {
     "text": "Travel to Nordweiler.",
     "depth": 1
    },
    {
     "text": "Join Alice in Nordweiler.",
     "depth": 1
    },
    {
     "text": "Follow Alice.",
     "depth": 1
    },
    {
     "text": "Get back to the boat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "nordweiler",
     "step": 1,
     "why": "Travel to Nordweiler.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "dr-splashs-strange-experiments",
   "title": "Dr. Splash's Strange Experiments",
   "number": "1803",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley has some interesting ideas about putting things inside my hard-earned stations. This kid is a part-time job!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Allows new items to be made at stations."
   ],
   "repeatable": false,
   "prev": [
    "big-boys-room"
   ],
   "next": [
    "junior-architectural-designer"
   ],
   "objectives": [
    {
     "text": "Smelt an Old Shoe",
     "depth": 1
    },
    {
     "text": "Use the Crusher to experiment. (0/3)",
     "depth": 1
    },
    {
     "text": "Use the Foundry to have fun. (0/3)",
     "depth": 1
    },
    {
     "text": "Use the Loom to the extreme. (0/3)",
     "depth": 1
    }
   ],
   "notes": [
    "You can place multiple of the same items in the crusher, foundry, and loom. I started with the Crusher and used two Egg and an Apple. For the Loom I used leaks and Lime Powder. For the Foundry I used one Mackerel and the quest icon came up. Talking to Stanley ended the quest."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "driftwood",
   "title": "Driftwood",
   "number": "9010",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "This lost friend at sea needs a little bit of help. We should look around in furogawa for help.",
   "prereq": "Speak to the Gurenu Fields Tour Guide.",
   "location": "Either Fishing or Gurenu Fields",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Talk to Simon at 58, -11.",
     "depth": 1
    },
    {
     "text": "Find his sister in Furogawa.",
     "depth": 1
    },
    {
     "text": "Talk to Simon at 58, -11.",
     "depth": 1
    }
   ],
   "notes": [
    "Simon's location is given from Fishing up the document Help!. His sister is outside on the first house in Furogawa."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "gurenu-fields",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "point",
     "ref": [
      58,
      -11
     ],
     "step": 1,
     "why": "Talk to Simon at 58, -11.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 2,
     "why": "Find his sister in Furogawa.",
     "role": "mid"
    },
    {
     "kind": "point",
     "ref": [
      58,
      -11
     ],
     "step": 3,
     "why": "Talk to Simon at 58, -11.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "dusting-off-old-ghosts",
   "title": "Dusting Off Old Ghosts",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "I can see and feel that Beverly is hurting. She can barely talk. I'm not sure what to do. Maybe the Everdoor is the only answer.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Beverly's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "like-father-like-son"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Beverly to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Beverly to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "elemental-transmutation",
   "title": "Elemental Transmutation",
   "number": "9115",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Citrine x1"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Bright Jelly x4",
     "depth": 1
    },
    {
     "text": "Lightning in a Bottle x4",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "elenas-demand",
   "title": "Elena's Demand",
   "number": "9105",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "Working on Postscripta",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "x30 Coffee Beans x30",
     "depth": 1
    },
    {
     "text": "x30 Tea Leaves x30",
     "depth": 1
    },
    {
     "text": "x30 Celery x30",
     "depth": 1
    },
    {
     "text": "x30 Potato x30",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "elenas-dharma",
   "title": "Elena's Dharma",
   "number": "2102",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "Elena has a long list of things for you to do: fight a gold dragon, conquer the deadly pulsar rays, and survive a severe thunderstorm. What a challenge!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "missing-credentials"
   ],
   "next": [
    "four-walls-a-roof"
   ],
   "objectives": [
    {
     "text": "Complete the Gold Dragon in under 7 minutes.",
     "depth": 1
    },
    {
     "text": "Catch over one third of all deadly pulsar rays.",
     "depth": 1
    },
    {
     "text": "Find a treasure lost at sea at 40, -50. (Rare Coin Collection)",
     "depth": 2
    },
    {
     "text": "Capture over one third of all severe lightning strikes.",
     "depth": 1
    },
    {
     "text": "Find a treasure sunk at sea at 34, 69. (Marriage Ring)",
     "depth": 2
    },
    {
     "text": "Give Elena one of your newfound treasures.",
     "depth": 1
    }
   ],
   "notes": [
    "Using Light Burst makes the Deadly Pulsar Rays event much easier."
   ],
   "waypoints": [
    {
     "kind": "point",
     "ref": [
      40,
      -50
     ],
     "step": 3,
     "why": "Find a treasure lost at sea at 40, -50. (Rare Coin Collection)",
     "role": "start"
    },
    {
     "kind": "point",
     "ref": [
      34,
      69
     ],
     "step": 5,
     "why": "Find a treasure sunk at sea at 34, 69. (Marriage Ring)",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "elenas-lesson",
   "title": "Elena's Lesson",
   "number": "9104",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "Working on Postscripta",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "x3 Octopus x3",
     "depth": 1
    },
    {
     "text": "x3 Squid x3",
     "depth": 1
    },
    {
     "text": "x3 Snow Crab x3",
     "depth": 1
    },
    {
     "text": "x3 Lobster x3",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "elenas-stipulation",
   "title": "Elena's Stipulation",
   "number": "9106",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "Working on Postscripta",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "x7 Citrine x7",
     "depth": 1
    },
    {
     "text": "x7 Hematite x7",
     "depth": 1
    },
    {
     "text": "x7 Opal x7",
     "depth": 1
    },
    {
     "text": "x7 Amethyst x7",
     "depth": 1
    },
    {
     "text": "x7 Diamond x7",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "engineering-101",
   "title": "Engineering 101",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has sent me a message through the pager. It sounds like there are some power issues over at Overbrook Hospital.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [
    "Overbrook Elevator Key"
   ],
   "repeatable": false,
   "prev": [
    "house-call"
   ],
   "next": [
    "the-incident"
   ],
   "objectives": [
    {
     "text": "Go to Overbrook Hospital]] and inquire to Jackie about the “pwr out.”",
     "depth": 1
    },
    {
     "text": "Fix the fusebox at the top of the elevator on the eastern side of Overbrook.",
     "depth": 1
    },
    {
     "text": "Talk to Jackie.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "everyone-loves-errands",
   "title": "Everyone Loves Errands",
   "number": "9004",
   "type": "Shenanigans",
   "giver": "Francis The Hoarder",
   "spirit": null,
   "description": "This odd person wants me to gather resources in exchange for other resources! I don't get it.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Complete your first errand.",
     "depth": 1
    }
   ],
   "notes": [
    "The errand is Healthy Menu, requiring:",
    "1 Poached Fruit,",
    "1 Grilled Fish, and",
    "1 Grilled Veggie."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "family-style",
   "title": "Family Style",
   "number": "1213",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "A big family-style dinner sounds amazing. I just need to do all of the work now.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "fishing-trip"
   ],
   "next": [
    "sous-chef-extraordinaire"
   ],
   "objectives": [
    {
     "text": "Invite everyone to the dinner.",
     "depth": 1
    },
    {
     "text": "The first three passengers you talk to after starting this Request are invited.",
     "depth": 2
    }
   ],
   "notes": [
    "Bug: If you have less than three passengers (excluding Atul), the next quest (Sous-Chef Extraordinaire) can potentially bug out and prevent you from completing it."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "family-ties",
   "title": "Family Ties",
   "number": "",
   "type": "Requests",
   "giver": "Lily",
   "spirit": "lily",
   "description": "I don’t want to stop, even if it’s painful to hear these things. Lily, we need to keep going.",
   "prereq": "",
   "location": "Furogawa",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "striking-out-on-my-own"
   ],
   "next": [
    "to-tundra"
   ],
   "objectives": [
    {
     "text": "Meet with Lily at the Oxbury Shrine, during nighttime.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 1,
     "why": "Meet with Lily at the Oxbury Shrine, during nighttime.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "family-vacation",
   "title": "Family Vacation",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "Beverly wants to share even more with me. Her life is full of interesting stories.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "cooking-with-fire"
   ],
   "next": [
    "dish-the-dirt"
   ],
   "objectives": [
    {
     "text": "Find an Acetate in Old-Central District.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "old-central-district",
     "step": 1,
     "why": "Find an Acetate in Old-Central District.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "feed-your-elders",
   "title": "Feed Your Elders",
   "number": "1502",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Astrid is hungry. I need to give her some food quickly.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "unite"
   ],
   "next": [
    "three-sisters"
   ],
   "objectives": [
    {
     "text": "Feed something to Astrid.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "feelin-the-buzz",
   "title": "Feelin' the Buzz",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has something to show me in the field. He seems pretty excited about it!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "perimeter-sweep"
   ],
   "next": [
    "hello-my-name-is-jackie"
   ],
   "objectives": [],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "fishing-trip",
   "title": "Fishing Trip",
   "number": "1212",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Again with the food. What's next?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "local-union-2187"
   ],
   "next": [
    "family-style"
   ],
   "objectives": [
    {
     "text": "Give Atul some Fried Chicken.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "five-views-of-mount-furogawa",
   "title": "Five Views of Mount Furogawa",
   "number": "1701",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "Some person in Furogawa has enthusiastically asked for my help in completing a collection of traditional woodprints. I didn't recognize them, but they seem to know me very well.",
   "prereq": "Requires the Icebreaker upgrade to complete.",
   "location": "Furogawa",
   "onBoat": false,
   "rewards": [
    "Quaint Figurine",
    "Gustav",
    "Obol"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "taill-dans-lor-massif",
    "lock-and-load",
    "the-house-of-bau"
   ],
   "objectives": [
    {
     "text": "Ask the shopkeeper about the missing print.",
     "depth": 1
    },
    {
     "text": "Report back to the art collector.",
     "depth": 1
    },
    {
     "text": "Travel to Susan's Museum at coordinates -150, 150.",
     "depth": 1
    },
    {
     "text": "Get the missing woodprint from the Collector.",
     "depth": 1
    },
    {
     "text": "Woodblock Print (0/1)",
     "depth": 2
    },
    {
     "text": "Give the woodprint to the art collector in Furogawa.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "susans-museum",
     "step": 3,
     "why": "Travel to Susan's Museum at coordinates -150, 150.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 6,
     "why": "Give the woodprint to the art collector in Furogawa.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "four-walls-a-roof",
   "title": "Four Walls & A Roof",
   "number": "2103",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "Her description of her house sounds... depressing.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "elenas-dharma"
   ],
   "next": [
    "on-the-sea-of-tranquility"
   ],
   "objectives": [
    {
     "text": "Build Elena's Cubicle.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "fully-loaded",
   "title": "Fully Loaded",
   "number": "1707",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "With Gustav's Gallery fully functional, Gustav is ready to start filling it with pieces. While he should be able to do everything by himself, he asked me to stay ready for any of the bigger pieces that might need to be produced on site.",
   "prereq": "Requires the Mist Cleaner 1000 upgrade to complete.",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-master-forger"
   ],
   "next": [
    "the-old-violinist"
   ],
   "objectives": [
    {
     "text": "Wait for Gustav to give you more designs.",
     "depth": 1
    },
    {
     "text": "Improve Gustav's Gallery with Neoclassical Nordic Fireplace",
     "depth": 1
    },
    {
     "text": "Wait for Gustav to give you more designs.",
     "depth": 1
    },
    {
     "text": "Improve Gustav's Gallery with Maximinimalist Clock",
     "depth": 1
    },
    {
     "text": "Talk to Gustav in his Gallery",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "good-cholesterol-bad-cholesterol",
   "title": "Good Cholesterol! Bad Cholesterol!",
   "number": "9102",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Corn Bread x1",
     "depth": 1
    },
    {
     "text": "Fish Sticks x1",
     "depth": 1
    },
    {
     "text": "Fried Rice x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "greetings-from-furogawa",
   "title": "Greetings from Furogawa!",
   "number": "9003",
   "type": "Shenanigans",
   "giver": "Gurenu Fields Tour Guide",
   "spirit": null,
   "description": "A tour on an island this small. Odd.",
   "prereq": "",
   "location": "Gurenu Fields",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-sommelier"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Follow your tour guide.",
     "depth": 1
    }
   ],
   "notes": [
    "If you stand to the left, the tour guide will move faster. They run after you and say \"I'm giving a tour here!\" or \"Don't get too close!\"",
    "At the end, you have the option to tip your tour guide 50 glims."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "gurenu-fields",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hang-in-there-skeleton",
   "title": "Hang in There, Skeleton!",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has told me that he finds the bare walls of his room a bit depressing, and has asked me to get him some posters.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "hello-my-name-is-jackie"
   ],
   "next": [
    "a-heart-sized-desert"
   ],
   "objectives": [
    {
     "text": "Talk to Jackie",
     "depth": 1
    },
    {
     "text": "Improve Jackie's On-Call Room (Motivational Posters)",
     "depth": 1
    },
    {
     "text": "Cost: 1100 Glims",
     "depth": 2
    },
    {
     "text": "Build Materials:",
     "depth": 2
    },
    {
     "text": "1 Bronze Sheet",
     "depth": 3
    },
    {
     "text": "5 Iron Ingots",
     "depth": 3
    },
    {
     "text": "1 Clear Glass Sheet",
     "depth": 3
    },
    {
     "text": "Talk to Jackie again",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hello-my-name-is-jackie",
   "title": "Hello, my Name is Jackie",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie would like his own room, so he could assist me better with my tasks on the boat.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "feelin-the-buzz"
   ],
   "next": [
    "hang-in-there-skeleton"
   ],
   "objectives": [],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hide-and-seek",
   "title": "Hide and Seek",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has sent me a message through the pager. It sounds like he has \"lost some people\" and is \"freaking out\" over at Overbrook Hospital.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "slop-n-slide"
   ],
   "next": [
    "house-call"
   ],
   "objectives": [
    {
     "text": "Go to Overbrook Hospital and ask Jackie about the “lost ppl.”",
     "depth": 1
    },
    {
     "text": "Find the three patients that look \"hidden, lost or out of place\" in Overbrook Hospital. (0/3)",
     "depth": 1
    },
    {
     "text": "Talk to Jackie.",
     "depth": 1
    }
   ],
   "notes": [
    "One patient is in the ruins to the far left of the area.",
    "One patient is near the candy machine.",
    "One patient is on the platform above and to the right of Jackie outside Daria's door."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "honey-i-shrunk-the-fishes",
   "title": "Honey, I shrunk the Fishes",
   "number": "9107",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Honey x5"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Albacore Tuna x1",
     "depth": 1
    },
    {
     "text": "Bluefin Tuna x1",
     "depth": 1
    },
    {
     "text": "Yellowfin Tuna x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hot-still-scape-for-six-colors",
   "title": "Hot Still-Scape for Six Colors",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "Daria has asked me for a strange instrument: \"a delicate schooner, with masts of crystal and sails of warped steel.\" Perhaps Francis would know about it?",
   "prereq": "Engineering 101",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Strange Instrument"
   ],
   "repeatable": false,
   "prev": [
    "the-old-guitarist"
   ],
   "next": [
    "the-night-watch"
   ],
   "objectives": [
    {
     "text": "Ask Francis the Wandering Merchant about Daria’s peculiar demand.",
     "depth": 1
    },
    {
     "text": "Complete Francis' errand to obtain the Strange Instrument.",
     "depth": 1
    }
   ],
   "notes": [
    "The errand Handle With Care requires:",
    "2 Steel Sheet",
    "2 Clear Glass Sheet",
    "Or it will be these items, possibly depending on the game version:",
    "3 silver ingots",
    "3 squids",
    "3 snow crabs",
    "3 lobsters"
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "house-call",
   "title": "House Call",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has sent me a series of strange messages through the pager. I'm not sure what is going on, but I should be checking on him, over at Overbrook Hospital.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "hide-and-seek"
   ],
   "next": [
    "engineering-101"
   ],
   "objectives": [
    {
     "text": "Go to Overbrook Hospital and find out what Jackie wanted.",
     "depth": 1
    }
   ],
   "notes": [
    "Complete The Old Guitarist to finish this quest."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "humble-abode",
   "title": "Humble Abode",
   "number": "1505",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Astrid has received a letter from Olga, describing a nice house she might like. Olga hasn't got any news from the enigmatic Giovanni.",
   "prereq": "Requires a Mailbox to start. Must have the Icebreaker to complete.",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "three-sisters"
   ],
   "next": [
    "past-lovers"
   ],
   "objectives": [
    {
     "text": "Check the mail.",
     "depth": 1
    },
    {
     "text": "A letter from Olga (0/1)",
     "depth": 2
    },
    {
     "text": "Read the letter.",
     "depth": 1
    },
    {
     "text": "Build Astrid's Bungalow.",
     "depth": 1
    },
    {
     "text": "Visit Iwashima Countryside.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    },
    {
     "text": "Ask about Giovanni on the island.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    },
    {
     "text": "Visit Furogawa.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    },
    {
     "text": "Ask about Giovanni on the island.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    },
    {
     "text": "Check the mail.",
     "depth": 1
    },
    {
     "text": "A letter from Olga (0/1)",
     "depth": 2
    },
    {
     "text": "Read the letter.",
     "depth": 1
    },
    {
     "text": "Find Olga's sister, Masha.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid in front of Masha.",
     "depth": 1
    },
    {
     "text": "Plant some resources on Masha's shell.",
     "depth": 1
    },
    {
     "text": "Visit Loneberg.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    },
    {
     "text": "Talk to Giovanni.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "iwashima-countryside",
     "step": 5,
     "why": "Visit Iwashima Countryside.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 9,
     "why": "Visit Furogawa.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "loneberg",
     "step": 19,
     "why": "Visit Loneberg.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "hummingberg-preservation-society",
   "title": "Hummingberg Preservation Society",
   "number": "9002",
   "type": "Shenanigans",
   "giver": "Alt Harbour Island Renovator",
   "spirit": null,
   "description": "A cleaning effort. Why not! I do like it when things are clean.",
   "prereq": "Sail to Alt Harbor after getting the Key for Stella's Cabin.",
   "location": "Alt Harbor",
   "onBoat": false,
   "rewards": [
    "Windmill Upgrade"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Get rid of those floating crates.",
     "depth": 1
    },
    {
     "text": "Talk to this person.",
     "depth": 1
    },
    {
     "text": "Find Oak Planks. (0/10)",
     "depth": 2
    },
    {
     "text": "Find Household Glue. (0/5)",
     "depth": 2
    },
    {
     "text": "Find Silk Threads. (0/15)",
     "depth": 2
    },
    {
     "text": "Talk to Jabari in Alt Harbor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alt-harbor",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "i-get-cranky-when-im-hungry",
   "title": "I Get Cranky When I'm Hungry",
   "number": "1103",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen is famished. I better make her something and feed it to her.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Mosstein Cove coordinates",
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "set-sail-captain"
   ],
   "next": [
    "seeds-for-the-future"
   ],
   "objectives": [
    {
     "text": "Go hunt down some jellyfish.",
     "depth": 1
    },
    {
     "text": "Build the Kitchen.",
     "depth": 1
    },
    {
     "text": "Cook something in the Kitchen.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    },
    {
     "text": "Feed Gwen anything.",
     "depth": 1
    }
   ],
   "notes": [
    "Once the kitchen is built, Gwen will give Stella Corn x3 to cook with."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "i-have-my-doubts",
   "title": "I Have My Doubts",
   "number": "1507",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Something is afoot. Is Giovanni not sleeping at night? Is he leaving the boat at night? Maybe I should follow him around.",
   "prereq": "Requires completion of Indiscreet Shopping.",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Hidden Achievement, depending on what you tell Astrid"
   ],
   "repeatable": false,
   "prev": [
    "past-lovers"
   ],
   "next": [
    "retrograde"
   ],
   "objectives": [
    {
     "text": "Follow Giovanni during nighttime.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid the next morning.",
     "depth": 1
    },
    {
     "text": "Read the mysterious letter.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "i-must-be-off",
   "title": "I Must Be Off",
   "number": "1114",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Where is Gwen? I can't find her on the boat.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "taking-time-off"
   ],
   "next": [
    "one-last-time"
   ],
   "objectives": [
    {
     "text": "Find Gwen's whereabouts.",
     "depth": 1
    },
    {
     "text": "Talking to the other passengers will reveal Gwen went to Villa Maggiore.",
     "depth": 2
    },
    {
     "text": "Clicking on her door will start the I Must Be Off quest.",
     "depth": 2
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    },
    {
     "text": "Hug Gwen.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen on your boat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "villa-maggiore",
     "step": 2,
     "why": "Talking to the other passengers will reveal Gwen went to Villa Maggiore.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "impression-sunrise",
   "title": "Impression, Sunrise",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "I've received a message from Overbrook's caretaker. Daria wants to see me. I should hurry.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Daria's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "rooms-by-the-sea"
   ],
   "next": [],
   "objectives": [],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "indiscreet-meeting",
   "title": "Indiscreet Meeting",
   "number": "1602",
   "type": "Requests",
   "giver": "Giovanni",
   "spirit": "giovanni",
   "description": "Why do I always get babysitting duty? I guess I'll follow Giovanni around!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "indiscreet-shopping"
   ],
   "next": [
    "a-place-for-strangers"
   ],
   "objectives": [
    {
     "text": "Head over to Oxbury.",
     "depth": 1
    },
    {
     "text": "Follow Giovanni on the island.",
     "depth": 1
    },
    {
     "text": "After this Request, talking to Astrid will result in a choice of telling the truth, or lying about Giovanni's actions. Lying will give the Influence \"Feels guilty for hurting loved ones. (-2)\" to Giovanni.",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 1,
     "why": "Head over to Oxbury.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "indiscreet-shopping",
   "title": "Indiscreet Shopping",
   "number": "1601",
   "type": "Requests",
   "giver": "Giovanni",
   "spirit": "giovanni",
   "description": "Shopping? Really? He's definitely more romantic than I could have imagined!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Ambertown Park coordinates",
    "Obol"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "indiscreet-meeting"
   ],
   "objectives": [
    {
     "text": "Head over to Bottom Line Corp.",
     "depth": 1
    },
    {
     "text": "Buy a Box of Chocolate from the shop in Bottom Line Corp.",
     "depth": 1
    },
    {
     "text": "Box of Chocolate (0/1)",
     "depth": 2
    },
    {
     "text": "Give the Box of Chocolate to Giovanni.",
     "depth": 1
    },
    {
     "text": "Head over to Ambertown Park.",
     "depth": 1
    },
    {
     "text": "Find roses in Ambertown Park.",
     "depth": 1
    },
    {
     "text": "Bouquet of Roses (0/1)",
     "depth": 2
    },
    {
     "text": "Give roses to Giovanni.",
     "depth": 1
    },
    {
     "text": "Talk to Giovanni on the boat.",
     "depth": 1
    }
   ],
   "notes": [
    "The second part of the quest doesn't start automatically, and once it does, the description becomes:",
    "Roses? Such tender attention! Astrid will be delighted!"
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 1,
     "why": "Head over to Bottom Line Corp.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "ambertown-park",
     "step": 5,
     "why": "Head over to Ambertown Park.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "its-alive",
   "title": "It's Alive!",
   "number": "1806",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley wants to try fermentation. Let's let it rot in the cellar.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "mysterious-word"
   ],
   "next": [
    "a-play-in-one-act"
   ],
   "objectives": [
    {
     "text": "Build a Cellar.",
     "depth": 1
    },
    {
     "text": "Use the Cellar.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "its-an-island-boss",
   "title": "It's an Island, Boss",
   "number": "",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "I've received a brochure for a place called Overbrook. I should check it out!",
   "prereq": "Build the Mist Cleaner 1000",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "snack-attack"
   ],
   "objectives": [
    {
     "text": "Read the Overbrook Brochure.",
     "depth": 1
    },
    {
     "text": "Visit Overbrook at 213, 57.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 2,
     "why": "Visit Overbrook at 213, 57.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "jiving-chives",
   "title": "Jiving Chives",
   "number": "1302",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has discovered a melody that significantly speeds up plant growth. I should try playing it in a garden.",
   "prereq": "Have seeds growing in the garden",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Plantasia Fantastica Song",
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "nature-class"
   ],
   "next": [
    "an-old-acquaintance"
   ],
   "objectives": [
    {
     "text": "Play music to any sprouting plant in the garden. (0/5)",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "junior-architect",
   "title": "Junior Architect",
   "number": "",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Astrid thinks I should upgrade the blueprint station. More stations, I suppose.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "three-sisters"
   ],
   "next": [
    "bars-of-gold",
    "humble-abode"
   ],
   "objectives": [
    {
     "text": "Upgrade your blueprint station at Albert’s Shipyard.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alberts-shipyard",
     "step": 1,
     "why": "Upgrade your blueprint station at Albert’s Shipyard.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "junior-architectural-designer",
   "title": "Junior Architectural Designer",
   "number": "1804",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley wants some paper. I have to remember my arts and crafts class from grade school, I suppose. This kid is so full of energy.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "dr-splashs-strange-experiments"
   ],
   "next": [
    "mysterious-word"
   ],
   "objectives": [
    {
     "text": "Cook Sawdust and Household Glue together.",
     "depth": 1
    },
    {
     "text": "Give Stanley some Homemade Paper.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "last-vacation",
   "title": "Last Vacation",
   "number": "1809",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley looks and sounds hurt by the reactions to his play. Rejection is never fun.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Stanley's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "the-reviews-are-in"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Stanley to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Stanley to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "laying-at-the-ley-line",
   "title": "Laying at the Ley Line",
   "number": "1304",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has tasked me with building her a house. I should ask around to find someone who could design it.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "an-old-acquaintance"
   ],
   "next": [
    "the-diffracted-cabinet"
   ],
   "objectives": [
    {
     "text": "Build Summer's Sanctuary.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "letting-it-go-for-dummies",
   "title": "Letting It Go for Dummies",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "With everything else failing, Jackie has shifted the blame of his problems on his poor education. He's motivated to better himself through reading.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "a-heart-sized-desert"
   ],
   "next": [
    "the-depths-of-the-pit"
   ],
   "objectives": [
    {
     "text": "Talk to Jackie",
     "depth": 1
    },
    {
     "text": "Improve Jackie's On-Call Room (Self-Help Books)",
     "depth": 1
    },
    {
     "text": "Cost: 1100 Glims",
     "depth": 2
    },
    {
     "text": "Build Materials:",
     "depth": 2
    },
    {
     "text": "2 Crystal Glass Sheet",
     "depth": 3
    },
    {
     "text": "6 Pulsar Ingot",
     "depth": 3
    },
    {
     "text": "2 Rose Gold Sheet",
     "depth": 3
    },
    {
     "text": "Talk to Jackie again",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "lifestyles-of-the-rich-and-famous",
   "title": "Lifestyles of the Rich and Famous",
   "number": "1905",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "So now it's come out! They want me to make it more grandiose.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "mini-palace"
   ],
   "next": [
    "a-taste-of-home"
   ],
   "objectives": [
    {
     "text": "Improve their house by adding something big.",
     "depth": 1
    },
    {
     "text": "Improve their house by adding something flashy.",
     "depth": 1
    },
    {
     "text": "Improve their house by adding something loud.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "like-father-like-son",
   "title": "Like Father, Like Son",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "Beverly has another interesting story planned for me. Let's find out what she has planned.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "dish-the-dirt"
   ],
   "next": [
    "dusting-off-old-ghosts"
   ],
   "objectives": [
    {
     "text": "Find an Acetate in Nordweiler.",
     "depth": 1
    },
    {
     "text": "The acetate is found on the second floor of the house on top of the island. You will need the Nordweiler House Key to enter.",
     "depth": 2
    },
    {
     "text": "Project the STRASBOURG, 1944 ACETATE in the Archive Room B-2522.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "nordweiler",
     "step": 1,
     "why": "Find an Acetate in Nordweiler.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "local-union-2187",
   "title": "Local Union 2187",
   "number": "1211",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "More food! Atul is unfillable.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "big-stove"
   ],
   "next": [
    "fishing-trip"
   ],
   "objectives": [
    {
     "text": "Give Atul some Pork Chops.",
     "depth": 1
    }
   ],
   "notes": [
    "Completing this quest removes the mood penalty from Movie Night. Atul also gets a +2 mood bonus for being proud of his work."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "lock-and-load",
   "title": "Lock and Load",
   "number": "1703",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "Gustav has charged me with setting up the groundwork for his planned exhibit. To that end, he needs me to equip the boat with a variety of stations.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "five-views-of-mount-furogawa"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Build a sawmill.",
     "depth": 1
    }
   ],
   "notes": [
    "Gustav verifies you have the following: Sawmill, Loom, Foundry, and Mailbox. These are all necessary to get the Icebreaker and let Gustav on your boat, so unless you salvaged the sawmill, the quest will be completed right away. If you have the sawmill but are missing something else, the quest will complete but he will say “Well, it seems a couple of items are left unchecked. I’ll let you get to it.”"
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "looters-literary-review",
   "title": "Looter's Literary Review",
   "number": "",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "Buck is really excited about some magazine or journal or whatever it is.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Master Adventurer Membership Card"
   ],
   "repeatable": false,
   "prev": [
    "the-lizard-king"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Find the Crow's End Inc. lost bounty.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "crows-end-inc",
     "step": 1,
     "why": "Find the Crow's End Inc. lost bounty.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "lost-bounty",
   "title": "Lost Bounty",
   "number": "9006",
   "type": "Shenanigans",
   "giver": "Francis The Hoarder",
   "spirit": null,
   "description": "A map! Lost treasure! This is a real life pirate adventure.",
   "prereq": "From the errand Little Bit of Sun",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Foundry Upgrade"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Look inside the bottle.",
     "depth": 1
    },
    {
     "text": "Find the location of the lost bounty.",
     "depth": 1
    },
    {
     "text": "Coordinates: -58, -52",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "point",
     "ref": [
      -58,
      -52
     ],
     "step": 3,
     "why": "Coordinates: -58, -52",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "lovers-for-life",
   "title": "Lovers for Life",
   "number": "1510",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "I didn't know Astrid really missed Giovanni. There was so much tension between the two. I suppose you only find your true love once.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Astrid's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "a-second-wind"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Astrid to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Astrid to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "loyal-subject",
   "title": "Loyal Subject",
   "number": "",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "I've never heard and seen this Lizard King. Not a fan, to be honest.",
   "prereq": "",
   "location": "Edgeborough Lane",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-lizard-king"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Find 20 carrots.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "mask-off",
   "title": "Mask Off",
   "number": "1908",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "One big job! One big score! What are these boys planning on my ship?",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "camping-in-a-cadillac"
   ],
   "next": [
    "brothers-until-the-end"
   ],
   "objectives": [
    {
     "text": "Get 100 Carrots for Bruce.",
     "depth": 1
    },
    {
     "text": "Get 100 Peaches for Bruce.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "measure-twice-cut-once",
   "title": "Measure Twice, Cut Once",
   "number": "1206",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "The sawmill might not just spit out sawdust after this.",
   "prereq": "Try using the sawmill and get sawdust.",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Sawmill fixed"
   ],
   "repeatable": false,
   "prev": [
    "the-sommelier"
   ],
   "next": [
    "atuls-workshop-quest",
    "movie-night"
   ],
   "objectives": [
    {
     "text": "Try out the Sawmill.",
     "depth": 1
    }
   ],
   "notes": [
    "Atul gives you Maple Log x5 at the start of the Request."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "mini-palace",
   "title": "Mini Palace",
   "number": "1904",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "They say they want a palace to live in, but this feels a little bit too much.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "smash-smash"
   ],
   "next": [
    "lifestyles-of-the-rich-and-famous"
   ],
   "objectives": [
    {
     "text": "Build Bruce and Mickey's Crib.",
     "depth": 1
    },
    {
     "text": "Talk to Bruce & Mickey.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "missing-credentials",
   "title": "Missing Credentials",
   "number": "2101",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "Elena says my skills aren't up to the task. She wants me to add another one to my arsenal.",
   "prereq": "Find Elena at Crow's End Inc.. Requires Double Jump, Glide, Zipline, Bounce, and the Mist Cleaner 1000.",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-dog-whisperer"
   ],
   "next": [
    "elenas-dharma"
   ],
   "objectives": [
    {
     "text": "Acquire the Dash ability.",
     "depth": 1
    },
    {
     "text": "Talk to Elena.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "crows-end-inc",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "more-than-meets-the-eye",
   "title": "More Than Meets the Eye",
   "number": "1111",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "The Loom needs a bit of a makeover. Let's see what we can do!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "back-to-the-past"
   ],
   "next": [
    "pretty-on-the-inside"
   ],
   "objectives": [
    {
     "text": "Improve the Loom.",
     "depth": 1
    },
    {
     "text": "Try the upgraded Loom.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "movie-night",
   "title": "Movie Night",
   "number": "1209",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "I get it. I get food cravings too.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "measure-twice-cut-once"
   ],
   "next": [
    "big-stove"
   ],
   "objectives": [
    {
     "text": "Give Atul some Popcorn.",
     "depth": 1
    }
   ],
   "notes": [
    "Atul’s mood will take a hit (-2) from remembering his old family life until Stella completes Local Union 2187."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "mysterious-word",
   "title": "Mysterious Word",
   "number": "1805",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "What is he talking about? What is a fakinhage? A breakfast food?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "junior-architectural-designer"
   ],
   "next": [
    "its-alive"
   ],
   "objectives": [
    {
     "text": "Give Stanley a Fakinhage.",
     "depth": 1
    }
   ],
   "notes": [
    "It's an Egg. Translates to \"F******' Egg\". So… just give him an egg basically.",
    "If you wait a day before turning in the quest, the description changes to:",
    "Stanley says it's round and white and goes well with toast. What could it be?"
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "nature-class",
   "title": "Nature Class",
   "number": "1301",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer asked me if I could add a garden to the boat. She wants to use it as a classroom to teach me about gardening.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "jiving-chives"
   ],
   "objectives": [
    {
     "text": "Build a garden.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "new-beginnings",
   "title": "New Beginnings",
   "number": "",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "Albert makes a good point! I should have a guest house for my new passengers that don't have a home yet.",
   "prereq": "Stanley's upgrading pevious guest house to Stanley's Playroom.",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Build a new Guest House.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "new-coordinates",
   "title": "New Coordinates",
   "number": "",
   "type": "Requests",
   "giver": "",
   "spirit": null,
   "description": "A message in a bottle indicated the coordinates of a mysterious treasure.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Sawmill upgrade",
    "Foundry upgrade",
    "Improved tools"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Head over to 85, 165.",
     "depth": 1
    },
    {
     "text": "Head over to -58, -52.",
     "depth": 1
    },
    {
     "text": "Head over to 220, 167.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "point",
     "ref": [
      85,
      165
     ],
     "step": 1,
     "why": "Head over to 85, 165.",
     "role": "start"
    },
    {
     "kind": "point",
     "ref": [
      -58,
      -52
     ],
     "step": 2,
     "why": "Head over to -58, -52.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "lost-shrine",
     "step": 3,
     "why": "Head over to 220, 167.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "of-warts-and-ropes",
   "title": "Of Warts And Ropes",
   "number": "1405",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice asked me to add a wardrobe to her house, and even offered to let me use it to store extra sets of clothes. She seems quite excited by the whole prospect.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Ability to change clothes",
    "Periwinkle Outfit"
   ],
   "repeatable": false,
   "prev": [
    "a-spot-for-pots"
   ],
   "next": [
    "apples-and-oranges"
   ],
   "objectives": [
    {
     "text": "Improve Alice's quarters with a Wardrobe.",
     "depth": 1
    },
    {
     "text": "Change outfit with the wardrobe.",
     "depth": 1
    },
    {
     "text": "Put on the Periwinkle Outfit from the wardrobe.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "on-the-sea-of-tranquility",
   "title": "On the Sea of Tranquility",
   "number": "2104",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "This lesson seems easy. No talking, just sailing towards the Everdoor... Easy might not be the right word here.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Elena's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "four-walls-a-roof"
   ],
   "next": [
    "postscripta"
   ],
   "objectives": [
    {
     "text": "Bring Elena to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Elena to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "onboarding",
   "title": "Onboarding",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie invited me for a tour of his workplace, Overbrook Hospital. I should follow him around.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "snack-attack"
   ],
   "next": [
    "the-slop-shop"
   ],
   "objectives": [
    {
     "text": "Follow Jackie around at Overbrook Hospital.",
     "depth": 1
    },
    {
     "text": "Follow Jackie around at Overbrook.",
     "depth": 1
    },
    {
     "text": "Follow Jackie around at Overbrook Hospital.",
     "depth": 1
    },
    {
     "text": "Follow Jackie around at Overbrook Hospital.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "one-last-drink-for-the-road",
   "title": "One Last Drink for the Road",
   "number": "1604",
   "type": "Requests",
   "giver": "Giovanni",
   "spirit": "giovanni",
   "description": "Giovanni needs a ride. I don't really feel like it, but he looks tired.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Giovanni's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "a-place-for-strangers"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Giovanni to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Giovanni to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "one-last-time",
   "title": "One Last Time",
   "number": "1115",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen wants to go to the Everdoor. These might be our last moments together.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Gwen's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "i-must-be-off"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Gwen to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Gwen to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "one-shoop-two-sheep",
   "title": "One Shoop, Two Sheep",
   "number": "1401",
   "type": "Requests",
   "giver": "Plains Denizen",
   "spirit": "alice",
   "description": "I've been asked for some help in corralling some sheep back to their enclosure, in Mount Toroyama.",
   "prereq": "",
   "location": "Mount Toroyama",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "the-coziest-cottage"
   ],
   "objectives": [
    {
     "text": "Get the sheep at Mount Toroyama to follow you by feeding it.",
     "depth": 1
    },
    {
     "text": "Bring the sheep back to its enclosure, close to Mount Toroyama's pier.",
     "depth": 1
    },
    {
     "text": "Report back to the denizen.",
     "depth": 1
    },
    {
     "text": "Find a second sheep and escort it back to Mount Toroyama's enclosure.",
     "depth": 1
    }
   ],
   "notes": [
    "The sheep on Mount Toroyama will eventually be a permanent passenger on Stella’s boat. It’s possible to change its color by reloading the save to before Stella first disembarks on the island."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "mount-toroyama",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "opaleantoluous",
   "title": "Opaleantoluous",
   "number": "9113",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Opal x1"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Aluminium Ore x4",
     "depth": 1
    },
    {
     "text": "Fireglow x3",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "past-lovers",
   "title": "Past Lovers",
   "number": "1506",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "It's time for a big reunion. Hopefully, this goes well.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Giovanni"
   ],
   "repeatable": false,
   "prev": [
    "humble-abode"
   ],
   "next": [
    "i-have-my-doubts"
   ],
   "objectives": [
    {
     "text": "Welcome Giovanni aboard.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "pauls-vs-simons",
   "title": "Pauls vs. Simons",
   "number": "9014",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "These individuals are fighting for... I'm not sure about what... a song, maybe... anyway, I can't wait to see where this leads.",
   "prereq": "",
   "location": "Edgeborough Lane",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Find the fight score in Nordweiler.",
     "depth": 1
    },
    {
     "text": "Talk to this person (go back to the spirit in Edgeborough Lane)",
     "depth": 1
    }
   ],
   "notes": [
    "In Edgeborough Lane, you come across a group of people arguing about a song. When one of them spots you, he asks if you can help him by playing the song. To do so, you'll need to travel to Nordweiler first and purchase The Autumn End."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "nordweiler",
     "step": 1,
     "why": "Find the fight score in Nordweiler.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 2,
     "why": "Talk to this person (go back to the spirit in Edgeborough Lane)",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "peaches-cream",
   "title": "Peaches & Cream",
   "number": "9112",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Peach Seed x2"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Cherry x8",
     "depth": 1
    },
    {
     "text": "Apple x8",
     "depth": 1
    },
    {
     "text": "Pear x8",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "perimeter-sweep",
   "title": "Perimeter Sweep",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "A passenger has complained about late night noise, but I'm not sure what this could be about. I should look around the boat.",
   "prereq": "Impression, Sunrise",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-incident"
   ],
   "next": [
    "feelin-the-buzz"
   ],
   "objectives": [
    {
     "text": "Jackie can be found in any passenger’s house.",
     "depth": 1
    },
    {
     "text": "Talk to Jackie to complete this quest.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "personal-connection",
   "title": "Personal Connection",
   "number": "1101",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen is in need of some physical contact.",
   "prereq": "",
   "location": "Alt Harbor",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "set-sail-captain"
   ],
   "objectives": [
    {
     "text": "Hug Gwen.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alt-harbor",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "postscripta",
   "title": "Postscripta",
   "number": "2105",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "Elena has a few last words for you.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "on-the-sea-of-tranquility"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Read one of Elena's letters.",
     "depth": 1
    },
    {
     "text": "Complete Elena's errands with Francis. These include: Elena's Stipulation, Elena's Demand, and Elena's Lesson.",
     "depth": 1
    },
    {
     "text": "Improve your stations to their full potential.",
     "depth": 1
    },
    {
     "text": "Gardens",
     "depth": 1
    },
    {
     "text": "Animal Pens",
     "depth": 1
    },
    {
     "text": "Chicken Coop",
     "depth": 1
    },
    {
     "text": "Cellar",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "pretty-on-the-inside",
   "title": "Pretty on the Inside",
   "number": "1112",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen's Lodge looks bare-bones. Maybe we could spice things up.",
   "prereq": "Improve the Kitchen",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "more-than-meets-the-eye"
   ],
   "next": [
    "taking-time-off"
   ],
   "objectives": [
    {
     "text": "Improve Gwen's Lodge by fully decorating it.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "retrograde",
   "title": "Retrograde",
   "number": "1508",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Oh, no! I've got to tell Giovanni some hard truths.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "i-have-my-doubts"
   ],
   "next": [
    "a-second-wind"
   ],
   "objectives": [
    {
     "text": "Talk to Giovanni.",
     "depth": 1
    },
    {
     "text": "Wait until Astrid is ready to talk to you.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "ride-the-lemon-dragon",
   "title": "Ride The Lemon Dragon",
   "number": "9012",
   "type": "Shenanigans",
   "giver": "Oxbury Vendor",
   "spirit": null,
   "description": "This young lemonade start-up needs my help. I've got to find them some delicious lemons.",
   "prereq": "",
   "location": "Oxbury",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "tomato-squeeze-co"
   ],
   "objectives": [
    {
     "text": "Talk to delivery man in Southpoint Docks.",
     "depth": 1
    },
    {
     "text": "Talk to the lemonade vendor in Oxbury.",
     "depth": 1
    }
   ],
   "notes": [
    "In an earlier version of the game, apparently you would get actual lemons to take back, but the current version gives you plastic lemons. It's likely, based on the dialogue and fake lemons, that Stella is inadvertently helping with an illegal smuggling operation."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "southpoint-docks",
     "step": 1,
     "why": "Talk to delivery man in Southpoint Docks.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 2,
     "why": "Talk to the lemonade vendor in Oxbury.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "rooms-by-the-sea",
   "title": "Rooms by the Sea",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "The area around Overbrook's vending machine looks much better now. I should try playing Daria's song there.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-last-supper"
   ],
   "next": [
    "impression-sunrise"
   ],
   "objectives": [],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "royalty-diner",
   "title": "Royalty Diner",
   "number": "9103",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Crepes x1",
     "depth": 1
    },
    {
     "text": "Scrambled Eggs x1",
     "depth": 1
    },
    {
     "text": "Latte x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "saturday-night-shopping-list",
   "title": "Saturday Night Shopping List",
   "number": "9117",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "After obtaining Light Burst",
   "location": "",
   "onBoat": false,
   "rewards": [
    "1 Treasure Map"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Diamond x2",
     "depth": 1
    },
    {
     "text": "Electrum Sheet x5",
     "depth": 1
    },
    {
     "text": "Egg x20",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "sea-master-2000",
   "title": "Sea Master 2000",
   "number": "1202",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "According to my uncle, my fishing chair was broken. I should try it now.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Full fishing unlocked",
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "welcome-aboard"
   ],
   "next": [
    "the-drawing-board"
   ],
   "objectives": [
    {
     "text": "Fish for your Uncle Atul.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "seeds-for-the-future",
   "title": "Seeds for the Future",
   "number": "1104",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen would like me to buy some seeds at a shop in Hummingberg.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Hummingberg coordinates",
    "Reasonable Raccoon Inc. prices in Hummingberg"
   ],
   "repeatable": false,
   "prev": [
    "i-get-cranky-when-im-hungry"
   ],
   "next": [
    "the-more-the-merrier",
    "spring-feet"
   ],
   "objectives": [
    {
     "text": "Head to Mosstein Cove.",
     "depth": 1
    },
    {
     "text": "Cut down a Maple Tree in Mosstein Cove.",
     "depth": 2
    },
    {
     "text": "Talk to Gwen.",
     "depth": 2
    },
    {
     "text": "Build a Field.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 2
    },
    {
     "text": "Head over to Hummingberg.",
     "depth": 2
    },
    {
     "text": "Look at the shrine in the town square.",
     "depth": 2
    },
    {
     "text": "Browse the shop's inventory.",
     "depth": 2
    },
    {
     "text": "Talk to Gwen.",
     "depth": 2
    },
    {
     "text": "Buy some seeds for your Field from the merchant.",
     "depth": 2
    },
    {
     "text": "Talk to Gwen.",
     "depth": 2
    },
    {
     "text": "Plant any seed in the Field.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    }
   ],
   "notes": [
    "Completing this quest will give Gwen a permanent mood bonus (+2) for shopping at Raccoon Inc.",
    "Cutting down a tree on any island will count towards quest completion, but Stella does need to talk to Gwen on land about the trees to continue the quest.",
    "Although Theodore claims to offer a discount during this quest, even if the displayed prices change, the actual Glims required and deducted while buying an item do not."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "mosstein-cove",
     "step": 1,
     "why": "Head to Mosstein Cove.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 6,
     "why": "Head over to Hummingberg.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "set-sail-captain",
   "title": "Set Sail, Captain!",
   "number": "1102",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "I have the ability to travel the world now. How nice!",
   "prereq": "",
   "location": "Alt Harbor",
   "onBoat": false,
   "rewards": [
    "Key for Stella's Cabin",
    "Albert's Shipyard coordinates"
   ],
   "repeatable": false,
   "prev": [
    "personal-connection"
   ],
   "next": [
    "i-get-cranky-when-im-hungry"
   ],
   "objectives": [
    {
     "text": "Start your boat in Stella's cabin.",
     "depth": 1
    },
    {
     "text": "Head over to Albert's Shipyard.",
     "depth": 1
    },
    {
     "text": "Upgrade your Blueprint Station.",
     "depth": 1
    },
    {
     "text": "Head back to the boat.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    },
    {
     "text": "Look at your Blueprint Station above your cabin.",
     "depth": 1
    },
    {
     "text": "Clear the trash off your boat through the edit mode.",
     "depth": 1
    },
    {
     "text": "Talk to Gwen.",
     "depth": 1
    },
    {
     "text": "Build the Guest House with the blueprint table.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alt-harbor",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "alberts-shipyard",
     "step": 2,
     "why": "Head over to Albert's Shipyard.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "slop-n-slide",
   "title": "Slop 'N Slide",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has sent me a message through the pager. It sounds like there's a kitchen emergency over at Overbrook Hospital.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [
    "\"Nutritious\" Slop x3"
   ],
   "repeatable": false,
   "prev": [
    "advanced-snackology"
   ],
   "next": [
    "hide-and-seek"
   ],
   "objectives": [
    {
     "text": "Go to Overbrook Hospital and ask Jackie about the “ktchn mrgncy.”",
     "depth": 1
    },
    {
     "text": "Get food from the cafeteria at Overbrook Hospital.",
     "depth": 1
    },
    {
     "text": "Distribute the cafeteria food to three Overbrook Hospital patients.",
     "depth": 1
    },
    {
     "text": "Talk to Jackie.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "smash-smash",
   "title": "Smash! Smash!",
   "number": "1903",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "All this noise and violence can't be good for them! I suppose having a crusher might calm them down.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-rhythm-of-the-night"
   ],
   "next": [
    "mini-palace"
   ],
   "objectives": [
    {
     "text": "Build a crusher.",
     "depth": 1
    },
    {
     "text": "Talk to Bruce and Mickey.",
     "depth": 1
    },
    {
     "text": "Use crusher.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "snack-attack",
   "title": "Snack Attack",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "I've met my old colleague Jackie at Overbrook Hospital. He asked me to get him a snack from the hospital's vending machine.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "its-an-island-boss"
   ],
   "next": [
    "onboarding"
   ],
   "objectives": [
    {
     "text": "Use the vending machine at Overbrook to buy Jackie a Chocoblasterz candy bar.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "something-to-write-home-about",
   "title": "Something to Write Home About",
   "number": "1500",
   "type": "Requests",
   "giver": "Protest Denizen",
   "spirit": "astrid",
   "description": "I've been getting letters upon letters. Maybe I should check my mailbox more often!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Protest Flyer",
    "Raccoon Inc. Flyer",
    "Bottom Line Corp. coordinates"
   ],
   "repeatable": false,
   "prev": [
    "youve-got-mail"
   ],
   "next": [
    "unite"
   ],
   "objectives": [
    {
     "text": "Check your mail.",
     "depth": 1
    },
    {
     "text": "Read your new letters.",
     "depth": 1
    },
    {
     "text": "Head over to Bottom Line Corp.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 3,
     "why": "Head over to Bottom Line Corp.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "sous-chef-extraordinaire",
   "title": "Sous-Chef Extraordinaire",
   "number": "1214",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Apparently I have to prepare food and give it to Atul. What a day.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "family-style"
   ],
   "next": [
    "au-pied-de-grenouille"
   ],
   "objectives": [
    {
     "text": "You will need to cook the item for each invited person from the Request, \"Family Style\", not for all people. The recipe is given to you if you do not know it.",
     "depth": 1
    },
    {
     "text": "Cook a Noodle Soup for Astrid.",
     "depth": 1
    },
    {
     "text": "Cook Bouillabaisse for Giovanni.",
     "depth": 1
    },
    {
     "text": "Cook Tuna Tataki for Gustav.",
     "depth": 1
    },
    {
     "text": "Cook French Fries for Stanley.",
     "depth": 1
    },
    {
     "text": "Cook Corndog for Bruce & Mickey.",
     "depth": 1
    },
    {
     "text": "Cook a Casserole for Buck.",
     "depth": 1
    },
    {
     "text": "Cook a Green Salad for Elena.",
     "depth": 1
    },
    {
     "text": "Cook Laksa for Beverly.",
     "depth": 1
    },
    {
     "text": "Cook Garlic Bread for Jackie.",
     "depth": 1
    },
    {
     "text": "Give the cooked items to Atul.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "sparkle-for-days",
   "title": "Sparkle for Days",
   "number": "9109",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Hematite x1"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Nebula Fabric x12",
     "depth": 1
    },
    {
     "text": "Quartz x4",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "spice-up-your-life",
   "title": "Spice Up Your Life",
   "number": "1208",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Atul thinks I should take some time and improve his house.",
   "prereq": "Requires Rock Destroyer to complete.",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "atuls-workshop-quest"
   ],
   "next": [
    "movie-night"
   ],
   "objectives": [
    {
     "text": "Improve Atul's house by adding a Shower.",
     "depth": 1
    },
    {
     "text": "Improve Atul's house by adding a Desk.",
     "depth": 1
    },
    {
     "text": "Improve Atul's house by adding a Picture Frame.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "spring-feet",
   "title": "Spring Feet",
   "number": "1106",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "I've got two Obols. Let's see what happens when I activate that shrine in Hummingberg.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Double Jump"
   ],
   "repeatable": false,
   "prev": [
    "seeds-for-the-future"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Go activate the shrine in Hummingberg.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 1,
     "why": "Go activate the shrine in Hummingberg.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "stellas-last-voyage",
   "title": "Stella's Last Voyage",
   "number": "",
   "type": "Requests",
   "giver": "Stella",
   "spirit": null,
   "description": "My time has come. I am no longer alone. Lily and mom are with me, holding my hands, somewhere out there.",
   "prereq": "",
   "location": "Greymist Peaks",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "to-tundra"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Stella & Daffodil to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "greymist-peaks",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Stella & Daffodil to the Everdoor.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "sticky-fingers",
   "title": "Sticky Fingers",
   "number": "1201",
   "type": "Requests",
   "giver": "Pond Denizen",
   "spirit": "atul",
   "description": "This strange man wants me to jump in a pond for a lemon.",
   "prereq": "",
   "location": "Barkensheim Creek",
   "onBoat": false,
   "rewards": [
    "Atul"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "welcome-aboard"
   ],
   "objectives": [
    {
     "text": "Recover your new friend's lost lemon.",
     "depth": 1
    },
    {
     "text": "Lemon (0/1)",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "barkensheim-creek",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "striking-out-on-my-own",
   "title": "Striking out on my Own",
   "number": "",
   "type": "Requests",
   "giver": "Lily",
   "spirit": "lily",
   "description": "I don't remember all of these things. It’s been so long. To hear Lily's voice is such a sweet song.",
   "prereq": "",
   "location": "Hummingberg",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "time-abroad"
   ],
   "next": [
    "family-ties"
   ],
   "objectives": [
    {
     "text": "Meet with Lily at the Furogawa Shrine, during nighttime.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 1,
     "why": "Meet with Lily at the Furogawa Shrine, during nighttime.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "sugar-shacks-delight",
   "title": "Sugar Shack's Delight",
   "number": "9114",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Maple Syrup x2"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Sole x1",
     "depth": 1
    },
    {
     "text": "Squid x1",
     "depth": 1
    },
    {
     "text": "Sockeye Salmon x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "taill-dans-lor-massif",
   "title": "Taillé dans l'Or Massif",
   "number": "1702",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "Gustav, upon joining the crew, commented on the \"drabness\" of the boat's prow. He would enjoy a figurehead very much.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "five-views-of-mount-furogawa"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Upgrade the boat with a figurehead.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "taking-the-low-road",
   "title": "Taking the Low Road",
   "number": "1408",
   "type": "Requests",
   "giver": "Alice",
   "spirit": "alice",
   "description": "Alice might have some difficulty walking down from her house to the deck of the boat. I could lower her house so she has an easier time getting around.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Annie's Beach Outfit"
   ],
   "repeatable": false,
   "prev": [
    "down-the-rabbit-hole"
   ],
   "next": [
    "a-chilling-realisation",
    "annies-lost-hat"
   ],
   "objectives": [
    {
     "text": "Move Alice's house down to the deck level.",
     "depth": 1
    },
    {
     "text": "Check on Alice in the morning.",
     "depth": 1
    },
    {
     "text": "Walk Alice back to her house in the evening.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "taking-time-off",
   "title": "Taking Time Off",
   "number": "1113",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen doesn't feel so good right now. I should let her breathe for awhile.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "pretty-on-the-inside"
   ],
   "next": [
    "i-must-be-off"
   ],
   "objectives": [
    {
     "text": "Wait for Gwen to feel better.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "terrible-subject",
   "title": "Terrible Subject",
   "number": "",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "I did bad, I think.",
   "prereq": "",
   "location": "Edgeborough Lane",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-lizard-king"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Talk to the Lizard King.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-beginning-and-the-end",
   "title": "The Beginning and the End",
   "number": "",
   "type": "Requests",
   "giver": "Beverly",
   "spirit": "beverly",
   "description": "Beverly said something about getting a Super Saver Discount Book in Ambertown Park to buy the Archive Room B-2522! Maybe I should check it out.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Archive Room B-2522"
   ],
   "repeatable": false,
   "prev": [
    "the-one-from-downstairs"
   ],
   "next": [
    "cooking-with-fire"
   ],
   "objectives": [
    {
     "text": "Head to Edgeborough Lane",
     "depth": 1
    },
    {
     "text": "Buy the Archive Room B-2522 on Edgeborough Lane",
     "depth": 1
    },
    {
     "text": "Talk to Beverly",
     "depth": 1
    },
    {
     "text": "Build the Archive Room B-2522",
     "depth": 1
    },
    {
     "text": "Talk to Beverly",
     "depth": 1
    },
    {
     "text": "Try the Archive Room B-2522 projector",
     "depth": 1
    },
    {
     "text": "Project the MATH 116 - LECTURE NOTES ACETATE in the Archive Room B-2522",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 1,
     "why": "Head to Edgeborough Lane",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-coziest-cottage",
   "title": "The Coziest Cottage",
   "number": "1402",
   "type": "Requests",
   "giver": "Plains Denizen",
   "spirit": "alice",
   "description": "Alice seems eager to join me on my travels but does not want to bother me. Perhaps she would accept an invitation if I built her some quarters? She described a house very passionately.",
   "prereq": "",
   "location": "Mount Toroyama",
   "onBoat": false,
   "rewards": [
    "Alice",
    "Sheep",
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "one-shoop-two-sheep"
   ],
   "next": [
    "a-coat-of-wool"
   ],
   "objectives": [
    {
     "text": "Build a cozy cottage for Alice.",
     "depth": 1
    },
    {
     "text": "Tell Alice about the house you built for her.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "mount-toroyama",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-depths-of-the-pit",
   "title": "The Depths of the Pit",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie does not wish to stay on the boat anymore. I should respect his wishes, and lead him away with dignity.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Jackie's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "letting-it-go-for-dummies"
   ],
   "next": [],
   "objectives": [],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "the-diffracted-cabinet",
   "title": "The Diffracted Cabinet",
   "number": "1305",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has asked me to gather a variety of gemstones and crystals that she could use to bring herself back to health. She is not picky, and requires only three different kinds.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "laying-at-the-ley-line"
   ],
   "next": [
    "the-oneness-and-the-wholeness"
   ],
   "objectives": [
    {
     "text": "Give Summer three gemstones.",
     "depth": 1
    },
    {
     "text": "Citrine",
     "depth": 2
    },
    {
     "text": "Amethyst",
     "depth": 2
    },
    {
     "text": "Diamond",
     "depth": 2
    },
    {
     "text": "Hematite",
     "depth": 2
    },
    {
     "text": "Opal",
     "depth": 2
    }
   ],
   "notes": [
    "Summer gets a temporary mood boost (+1) when she is offered a gemstone during this quest.",
    "Her summary of the gem’s use in her spiritual practice is on the item page."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-dog-whisperer",
   "title": "The Dog Whisperer",
   "number": "",
   "type": "Requests",
   "giver": "Elena",
   "spirit": "elena",
   "description": "Someone is asking for my help.",
   "prereq": "",
   "location": "Crow's End Inc.",
   "onBoat": false,
   "rewards": [
    "Elena"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "missing-credentials"
   ],
   "objectives": [
    {
     "text": "Talk to the stranger.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "crows-end-inc",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-drawing-board",
   "title": "The Drawing Board",
   "number": "1203",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Atul says I can upgrade my boat at Albert's Shipyard.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "sea-master-2000"
   ],
   "next": [
    "woodwork",
    "the-sommelier"
   ],
   "objectives": [
    {
     "text": "Upgrade your blueprint station again at Albert's Shipyard.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alberts-shipyard",
     "step": 1,
     "why": "Upgrade your blueprint station again at Albert's Shipyard.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-fires-of-tondor",
   "title": "The Fires of Tondor",
   "number": "2004",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "The fires of Tondor have to be lit. Sounds like lighthouses that need to be switched on.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "demons-of-light"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Light the Nordsee Pier.",
     "depth": 1
    },
    {
     "text": "Light the Sandwich Walk.",
     "depth": 1
    },
    {
     "text": "Light the Hikarishima Lighthouse.",
     "depth": 1
    },
    {
     "text": "Talk to Buck on the boat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "nordsee-pier",
     "step": 1,
     "why": "Light the Nordsee Pier.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "sandwich-walk",
     "step": 2,
     "why": "Light the Sandwich Walk.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "hikarishima-lighthouse",
     "step": 3,
     "why": "Light the Hikarishima Lighthouse.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-great-wave",
   "title": "The Great Wave",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "The area around Overbrook's power station looks much better, now. I should try playing Daria's song there.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-titanic-days"
   ],
   "next": [
    "the-last-supper"
   ],
   "objectives": [
    {
     "text": "Play Daria's song at the power station.",
     "depth": 1
    },
    {
     "text": "Go to Overbrook's power station (it's to the right of the boat you ride in on). There, go to the top of one of the buildings. There will be some colourful paper. Interact with it and complete the platforming.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 2,
     "why": "Go to Overbrook's power station (it's to the right of the boat you ride in on). There, go to the top of one of the buildings. There will be some colourful paper. Interact with it and complete the platforming.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-high-wire-act",
   "title": "The High-Wire Act",
   "number": "",
   "type": "Shenanigans",
   "giver": "Overbrook Patient",
   "spirit": null,
   "description": "He sure seems hell bent on escaping this place. What should I do? Find some Linen Fabric for him or go talk to the doctors?",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Find some Linen Fabric.",
     "depth": 1
    },
    {
     "text": "Linen Fabric (0/5)",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-house-of-bau",
   "title": "The House of Bau",
   "number": "1704",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "What's a multipurpose area? And why does Gustav need one? This seems like a lot of work for one person! I do hope it will liven the mood on the boat.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "five-views-of-mount-furogawa"
   ],
   "next": [
    "the-search-for-erich-deskmann"
   ],
   "objectives": [
    {
     "text": "Build Gustav's Gallery.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-ice-breaker",
   "title": "The Ice Breaker",
   "number": "",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Atul says I can upgrade my boat at Albert's Shipyard.",
   "prereq": "Try to sail through the ice barrier.",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Ice Breaker improvement"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Add the Ice Breaker upgrade to your boat.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "alberts-shipyard",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-incident",
   "title": "The Incident",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "Jackie has sent me a message through the pager. He sounded very, very mad. I should probably head to Overbrook right away.",
   "prereq": "Hot Still-Scape for Six Colors",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "engineering-101"
   ],
   "next": [
    "threes-company"
   ],
   "objectives": [
    {
     "text": "Check on Jackie at Overbrook Hospital.",
     "depth": 1
    }
   ],
   "notes": [
    "Once you give Daria a strange instrument for one of her quests, Jackie will get mad at you, and then the quest will end. After the quest ends, you will get a shenanigan from a spirit standing nearby, then you can continue from there."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-last-supper",
   "title": "The Last Supper",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "The area around Overbrook's cafeteria looks much better now. I should try playing Daria's song there.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-great-wave"
   ],
   "next": [
    "rooms-by-the-sea"
   ],
   "objectives": [],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-lizard-king",
   "title": "The Lizard King",
   "number": "",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "What's a Lizard King? I wish I knew!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "visions-of-oil"
   ],
   "next": [
    "looters-literary-review"
   ],
   "objectives": [
    {
     "text": "Meet the Lizard King in Edgeborough Lane.",
     "depth": 1
    },
    {
     "text": "Do the Lizard King's bidding.",
     "depth": 1
    },
    {
     "text": "20 Carrots are needed.",
     "depth": 2
    },
    {
     "text": "Talk to Buck.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "edgeborough-lane",
     "step": 1,
     "why": "Meet the Lizard King in Edgeborough Lane.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-master-forger",
   "title": "The Master Forger",
   "number": "1706",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "Gustav suggested adding a Smithy to the boat, hinting that we might need it later.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-search-for-erich-deskmann"
   ],
   "next": [
    "fully-loaded"
   ],
   "objectives": [
    {
     "text": "Build a Smithy.",
     "depth": 1
    },
    {
     "text": "Talk to Gustav.",
     "depth": 1
    },
    {
     "text": "Use the Smithy.",
     "depth": 1
    },
    {
     "text": "Talk to Gustav.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-metastatic-coil",
   "title": "The Metastatic Coil",
   "number": "1308",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer had a new vision of another, more threatening dragon. I should visit it as soon as possible.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Aluminum Dragon event",
    "Summer's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "a-cold-and-dreamless-slumber"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Meet with the Aluminium Dragon.",
     "depth": 1
    },
    {
     "text": "Wait for Summer to gather her thoughts.",
     "depth": 1
    },
    {
     "text": "Bring Summer to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 3,
     "why": "Bring Summer to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "the-more-the-merrier",
   "title": "The More, the Merrier",
   "number": "1105",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "Gwen is convinced that other lost souls are out there. Let's go see.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "seeds-for-the-future"
   ],
   "next": [
    "usonia-1"
   ],
   "objectives": [
    {
     "text": "Find a passenger on Barkensheim Creek.",
     "depth": 1
    },
    {
     "text": "Find a passenger in Hummingberg.",
     "depth": 1
    }
   ],
   "notes": [
    "The passenger in Hummingberg requires either the Key for Hummingberg or Double Jump."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "barkensheim-creek",
     "step": 1,
     "why": "Find a passenger on Barkensheim Creek.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 2,
     "why": "Find a passenger in Hummingberg.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-night-watch",
   "title": "The Night Watch",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "I've received a message from Daria's caretaker. She would like to see me.",
   "prereq": "The Incident",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "hot-still-scape-for-six-colors"
   ],
   "next": [
    "the-raft-of-the-medusa"
   ],
   "objectives": [
    {
     "text": "Talk to Daria in her room on Overbrook.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-old-guitarist",
   "title": "The Old Guitarist",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "Jackie was not at his usual post, and I managed to enter the \"difficult patient\"'s room. She looks unresponsive, but perhaps I can snap her out of it?",
   "prereq": "House Call",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [
    "Strange Melody"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "hot-still-scape-for-six-colors"
   ],
   "objectives": [
    {
     "text": "Find a way to wake the “difficult patient.”",
     "depth": 1
    },
    {
     "text": "Play the strange melody in the \"difficult” patient's room.",
     "depth": 1
    }
   ],
   "notes": [
    "Examine the notes at the desk in the room, then press the button to play guitar (same as for growing in garden)."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-old-violinist",
   "title": "The Old Violinist",
   "number": "1708",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "With his exhibition finished, Gustav says he's ready to move on, and asked me to bring him to the Everdoor.",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Gustav's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "fully-loaded"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Bring Gustav to the Everdoor.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "everdoor",
     "step": 1,
     "why": "Bring Gustav to the Everdoor.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "the-one-from-downstairs",
   "title": "The One from Downstairs",
   "number": "2101",
   "type": "Requests",
   "giver": "Neighbor Denizen",
   "spirit": "beverly",
   "description": "This person sounds oddly familiar. I just can't put my finger on it. Let's see where this takes us.",
   "prereq": "",
   "location": "Oxbury",
   "onBoat": false,
   "rewards": [
    "Beverly"
   ],
   "repeatable": false,
   "prev": [],
   "next": [
    "the-beginning-and-the-end"
   ],
   "objectives": [
    {
     "text": "Head to Hummingberg.",
     "depth": 1
    },
    {
     "text": "Find someone dressed in black in Hummingberg.",
     "depth": 1
    },
    {
     "text": "Build [[Cuckoo Clock Tower.",
     "depth": 1
    },
    {
     "text": "Head to Oxbury.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly in Oxbury.",
     "depth": 1
    },
    {
     "text": "Welcome your new passenger on the boat.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly.",
     "depth": 1
    },
    {
     "text": "Head to Oxbury with Beverly.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly in Oxbury.",
     "depth": 1
    },
    {
     "text": "Build Beverly's Farmhouse.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly in Oxbury.",
     "depth": 1
    },
    {
     "text": "Talk to Beverly.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 1,
     "why": "Head to Hummingberg.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 4,
     "why": "Head to Oxbury.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-oneness-and-the-wholeness",
   "title": "The Oneness and the Wholeness",
   "number": "1306",
   "type": "Requests",
   "giver": "Summer",
   "spirit": "summer",
   "description": "Summer has a special lesson to teach me. She would like me to meet her on the cliff in Mount Toroyama.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-diffracted-cabinet"
   ],
   "next": [
    "a-cold-and-dreamless-slumber"
   ],
   "objectives": [
    {
     "text": "Go to Mount Toroyama.",
     "depth": 1
    },
    {
     "text": "Talk with Summer on the pier.",
     "depth": 1
    },
    {
     "text": "Talk with Summer on the cliffside.",
     "depth": 1
    },
    {
     "text": "Sit by the boulder next to Summer.",
     "depth": 1
    },
    {
     "text": "Talk to Summer on the pier.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "mount-toroyama",
     "step": 1,
     "why": "Go to Mount Toroyama.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-raft-of-the-medusa",
   "title": "The Raft of the Medusa",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "Daria, true to herself, has mysteriously asked me to play her song just outside of her room. I should try it!",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [
    "Radiant Spring x2"
   ],
   "repeatable": false,
   "prev": [
    "the-night-watch"
   ],
   "next": [
    "the-titanic-days"
   ],
   "objectives": [
    {
     "text": "Play Daria's song outside of Daria's room at Overbrook.",
     "depth": 1
    }
   ],
   "notes": [
    "You'll want to go to the cluster of sticky notes on the outside of Daria's room."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-real-spiritfarer",
   "title": "The Real Spiritfarer",
   "number": "",
   "type": "Shenanigans",
   "giver": "Overbrook Patient",
   "spirit": null,
   "description": "Wait? Are there other Spiritfarers around the world? I better go fish for that lost Everlight.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Fish around the waters of Overbrook.",
     "depth": 1
    },
    {
     "text": "Talk to this person.",
     "depth": 1
    }
   ],
   "notes": [
    "You will fish up a Light Bulb, a key item that \"will shine as bright as an Everlight!\""
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-reviews-are-in",
   "title": "The Reviews Are In!",
   "number": "1808",
   "type": "Requests",
   "giver": "Stanley",
   "spirit": "stanley",
   "description": "Stanley wants to know if people liked his play. Let's see...",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "a-play-in-one-act"
   ],
   "next": [
    "last-vacation"
   ],
   "objectives": [
    {
     "text": "Ask whoever you invited about Stanley's play.",
     "depth": 1
    },
    {
     "text": "Talk to Stanley.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-rhythm-of-the-night",
   "title": "The Rhythm of the Night",
   "number": "1902",
   "type": "Requests",
   "giver": "Bruce & Mickey",
   "spirit": "bruce-mickey",
   "description": "A light show at sea? This I got to see!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Unlocks the Pulsar Rays event."
   ],
   "repeatable": false,
   "prev": [
    "bullying-for-beginners"
   ],
   "next": [
    "smash-smash"
   ],
   "objectives": [
    {
     "text": "Find the pulsar rays.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-search-for-erich-deskmann",
   "title": "The Search for Erich Deskmann",
   "number": "1705",
   "type": "Requests",
   "giver": "Gustav",
   "spirit": "gustav",
   "description": "Gustav needs a desk in his office. He has heard of a master woodworker living in Oxbury, but couldn't get in touch with him. Perhaps his partner, working in a café there, could help us out?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Oxbury coordinates",
    "Surf and Turf recipe",
    "Casserole recipe",
    "Vintage Modernist Desk Blueprint"
   ],
   "repeatable": false,
   "prev": [
    "the-house-of-bau"
   ],
   "next": [
    "the-master-forger"
   ],
   "objectives": [
    {
     "text": "Find the woodworker's partner in a café in Oxbury.",
     "depth": 1
    },
    {
     "text": "Find the woodworker hanging around in Ambertown Park.",
     "depth": 1
    },
    {
     "text": "Bring a [[Surf and Turf to the woodworker.",
     "depth": 1
    },
    {
     "text": "(Or): Bring a Casserole to the woodworker.",
     "depth": 2
    },
    {
     "text": "(Or): Bring a Grilled Fish to the woodworker.",
     "depth": 2
    },
    {
     "text": "Pay the woodworker his fee of 450,000 glims.",
     "depth": 2
    },
    {
     "text": "DO NOT TELL the woodworker's partner in Oxbury.",
     "depth": 2
    },
    {
     "text": "If you paid him: Return to Erich.",
     "depth": 2
    },
    {
     "text": "If you tattled: Tell the woodworker that his partner will take him back in.",
     "depth": 2
    },
    {
     "text": "Improve Gustav's Gallery with the vintage modernist desk.",
     "depth": 1
    }
   ],
   "notes": [
    "You can change the requested food to a Casserole and then to a Grilled Fish by talking to the woodworker in Ambertown Park without the listed dish in your inventory.",
    "Step 4 is reverse psychology, DO speak with his partner to get the desk for free."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 1,
     "why": "Find the woodworker's partner in a café in Oxbury.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "ambertown-park",
     "step": 2,
     "why": "Find the woodworker hanging around in Ambertown Park.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 7,
     "why": "DO NOT TELL the woodworker's partner in Oxbury.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-silver-company",
   "title": "The Silver Company",
   "number": "2002",
   "type": "Requests",
   "giver": "Buck",
   "spirit": "buck",
   "description": "An adventure with a peculiar Oracle tree and role-playing friends. Buck sure has an active imagination...",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "a-lair-of-wonders"
   ],
   "next": [
    "demons-of-light"
   ],
   "objectives": [
    {
     "text": "Find Buck's friend Jerome in Hummingberg.",
     "depth": 1
    },
    {
     "text": "Find Buck's friend Bryan in Bottom Line Corp..",
     "depth": 1
    },
    {
     "text": "Find Buck's friend Bob in Oxbury.",
     "depth": 1
    },
    {
     "text": "Talk to Buck.",
     "depth": 1
    },
    {
     "text": "Give Buck Popcorn, a Corndog, and Toffee.",
     "depth": 1
    },
    {
     "text": "Head to Nordweiler and talk to Buck.",
     "depth": 1
    },
    {
     "text": "Talk to Buck on the boat.",
     "depth": 1
    },
    {
     "text": "Talk to the Oracle Tree at Furogawa.",
     "depth": 1
    },
    {
     "text": "Talk to Buck in Furogawa.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 1,
     "why": "Find Buck's friend Jerome in Hummingberg.",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 2,
     "why": "Find Buck's friend Bryan in Bottom Line Corp..",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 3,
     "why": "Find Buck's friend Bob in Oxbury.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "nordweiler",
     "step": 6,
     "why": "Head to Nordweiler and talk to Buck.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "furogawa",
     "step": 8,
     "why": "Talk to the Oracle Tree at Furogawa.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-slop-shop",
   "title": "The Slop Shop",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "The cafeteria at Overbrook Hospital has run out of supplies. Jackie has asked me for some.",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "onboarding"
   ],
   "next": [
    "wells-fartgo-co"
   ],
   "objectives": [
    {
     "text": "Bring five bags of Rice to Jackie.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-sommelier",
   "title": "The Sommelier",
   "number": "1205",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "A bottle from the sea. A message from far away. I should open it.",
   "prereq": "Fish up the Message in a Bottle",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Gurenu Fields coordinates",
    "Brochure for Furogawa Tours"
   ],
   "repeatable": false,
   "prev": [
    "the-drawing-board"
   ],
   "next": [
    "greetings-from-furogawa"
   ],
   "objectives": [
    {
     "text": "Atul really wants you to open a bottle from the sea.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-sweet-smell-of-success",
   "title": "The Sweet Smell of Success",
   "number": "9008",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "Me… a movie star? What an absurd idea! I better help this poor man. He probably hit his head or something. He's seeing stars everywhere.",
   "prereq": "Rock Destroyer to reach Ingrid, or Mist Cleaner 1000 to reach Katherine.",
   "location": "Nordsee Pier",
   "onBoat": false,
   "rewards": [
    "Cow Stall Upgrade"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Talk to Ingrid in Old-Central District.",
     "depth": 1
    },
    {
     "text": "Talk to Katherine in Obscure Canopy.",
     "depth": 1
    },
    {
     "text": "Talk to Larry in Nordsee Pier.",
     "depth": 1
    }
   ],
   "notes": [
    "In Nordsee Pier, speak to the first spirit standing closest to the docks. He will be convinced that you're an actor and ask you to speak to some of his colleagues so they can make you a star. You only need to speak to one of the two actresses to complete this Shenanigans, with minor different dialogue. There is no difference in the final reward."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "nordsee-pier",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "old-central-district",
     "step": 1,
     "why": "Talk to Ingrid in Old-Central District.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "obscure-canopy",
     "step": 2,
     "why": "Talk to Katherine in Obscure Canopy.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "nordsee-pier",
     "step": 3,
     "why": "Talk to Larry in Nordsee Pier.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "the-titanic-days",
   "title": "The Titanic Days",
   "number": "",
   "type": "Requests",
   "giver": "Daria",
   "spirit": "daria",
   "description": "That experience with Daria was quite something, but I think it's helping her. Perhaps if I help improve Overbrook she'll get even better?",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-raft-of-the-medusa"
   ],
   "next": [
    "the-great-wave"
   ],
   "objectives": [
    {
     "text": "Buy new items at the Vending Machine.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Mentioned in quest description",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "this-shed-is-my-shed",
   "title": "This Shed Is My Shed",
   "number": "9005",
   "type": "Shenanigans",
   "giver": "Villa Maggiore Gardener",
   "spirit": null,
   "description": "Hopefully, he won't work too long on that door.",
   "prereq": "",
   "location": "Villa Maggiore",
   "onBoat": false,
   "rewards": [
    "Garden Upgrade"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Let this upset man do his thing.",
     "depth": 1
    },
    {
     "text": "Talk to this person.",
     "depth": 1
    }
   ],
   "notes": [
    "The shenanigan can be started by returning to Villa Maggiore at any point after completing Back to the Past, but cannot be completed until Gwen goes through the Everdoor."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "villa-maggiore",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "three-sisters",
   "title": "Three Sisters",
   "number": "1503",
   "type": "Requests",
   "giver": "Astrid",
   "spirit": "astrid",
   "description": "Astrid says a friend is waiting for us. Who knows what surprise awaits us!",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [
    "Olga use"
   ],
   "repeatable": false,
   "prev": [
    "feed-your-elders"
   ],
   "next": [
    "junior-architect"
   ],
   "objectives": [
    {
     "text": "Find Astrid's seabound friend.",
     "depth": 1
    },
    {
     "text": "Talk to Astrid in front of Olga.",
     "depth": 1
    },
    {
     "text": "Plant some resources on Olga's shell.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "threes-company",
   "title": "Three's Company",
   "number": "",
   "type": "Shenanigans",
   "giver": "Overbrook Caretaker",
   "spirit": null,
   "description": "This hospital is cruelly understaffed and in need of dedicated employees. Time to find some competent people!",
   "prereq": "",
   "location": "Overbrook",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-incident"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Recruit a chef for Overbrook in Hoseki Quarry.",
     "depth": 2
    },
    {
     "text": "Talk to the foreman in Southpoint Docks.",
     "depth": 2
    },
    {
     "text": "Recruit a doctor for Overbrook in Old-Central District.",
     "depth": 3
    },
    {
     "text": "Recruit a gardener for Overbrook in Villa Maggiore.",
     "depth": 2
    },
    {
     "text": "Talk to this person.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "hoseki-quarry",
     "step": 1,
     "why": "Recruit a chef for Overbrook in Hoseki Quarry.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "southpoint-docks",
     "step": 2,
     "why": "Talk to the foreman in Southpoint Docks.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 3,
     "why": "Recruit a doctor for Overbrook in Old-Central District.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "old-central-district",
     "step": 3,
     "why": "Recruit a doctor for Overbrook in Old-Central District.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "overbrook",
     "step": 4,
     "why": "Recruit a gardener for Overbrook in Villa Maggiore.",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "villa-maggiore",
     "step": 4,
     "why": "Recruit a gardener for Overbrook in Villa Maggiore.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "thyst-but-a-flesh-wound",
   "title": "Thyst but a Flesh Wound",
   "number": "9111",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Amethyst x1"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Pulsar Ore x5",
     "depth": 1
    },
    {
     "text": "Comet Rock x5",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "time-abroad",
   "title": "Time Abroad",
   "number": "",
   "type": "Requests",
   "giver": "Lily",
   "spirit": "lily",
   "description": "I can hear Lily’s voice. She’s here with me, somehow. Let’s head to Hummingberg. I want to hear her voice again.",
   "prereq": "Third encounter with Hades.",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [
    "striking-out-on-my-own"
   ],
   "objectives": [
    {
     "text": "Meet with Lily at the Hummingberg Shrine, during nighttime.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hummingberg",
     "step": 1,
     "why": "Meet with Lily at the Hummingberg Shrine, during nighttime.",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "to-tundra",
   "title": "To Tundra",
   "number": "",
   "type": "Requests",
   "giver": "Lily",
   "spirit": "lily",
   "description": "Oh, Lily. I know this is painful for you. We are almost there... together.",
   "prereq": "",
   "location": "Oxbury",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "family-ties"
   ],
   "next": [
    "stellas-last-voyage"
   ],
   "objectives": [
    {
     "text": "Meet with Lily at the Greymist Peaks Shrine, during nighttime.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "greymist-peaks",
     "step": 1,
     "why": "Meet with Lily at the Greymist Peaks Shrine, during nighttime.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": true
  },
  {
   "id": "tomato-squeeze-co",
   "title": "Tomato Squeeze Co.",
   "number": "9013",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "What a pivot! They now sell tomato juice. I swear things move faster in the big city.",
   "prereq": "",
   "location": "Oxbury",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "ride-the-lemon-dragon"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Talk to delivery man in Bottom Line Corp..",
     "depth": 1
    },
    {
     "text": "Talk to the vendor in Oxbury.",
     "depth": 1
    }
   ],
   "notes": [
    "Takes a few days before it becomes available."
   ],
   "waypoints": [
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 0,
     "why": "Quest location",
     "role": "start"
    },
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 1,
     "why": "Talk to delivery man in Bottom Line Corp..",
     "role": "mid"
    },
    {
     "kind": "island",
     "ref": "oxbury",
     "step": 2,
     "why": "Talk to the vendor in Oxbury.",
     "role": "end"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "too-many-items-on-the-menu",
   "title": "Too Many Items on the Menu",
   "number": "9101",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Apple Pie x1",
     "depth": 1
    },
    {
     "text": "Corndog x1",
     "depth": 1
    },
    {
     "text": "Noodle Soup x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "training-wheels",
   "title": "Training Wheels",
   "number": "9009",
   "type": "Shenanigans",
   "giver": "",
   "spirit": null,
   "description": "This security guard wants me to train harder and upgrade my abilities. What could possibly be in that mine?",
   "prereq": "",
   "location": "Kaltstein Mines",
   "onBoat": false,
   "rewards": [
    "Key for the Kaltstein Mines"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Return when you have the Abilities Double Jump, Glide, and Zipline",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "kaltstein-mines",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "uncles-gone",
   "title": "Uncle's Gone?",
   "number": "1216",
   "type": "Requests",
   "giver": "Spirit",
   "spirit": null,
   "description": "Maybe I should ask around if anyone has seen my uncle.",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Atul's Spirit Flower"
   ],
   "repeatable": false,
   "prev": [
    "au-pied-de-grenouille"
   ],
   "next": [],
   "objectives": [
    {
     "text": "Ask the first guest about Atul's whereabouts.",
     "depth": 1
    },
    {
     "text": "Ask the second guest about Atul's whereabouts.",
     "depth": 1
    },
    {
     "text": "Ask the third guest about Atul's whereabouts.",
     "depth": 1
    },
    {
     "text": "This Request is completed from asking the third guest, the dialogue for the first two guests will be skipped after speaking to the third guest.",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": true
  },
  {
   "id": "unite",
   "title": "Unite!",
   "number": "1501",
   "type": "Requests",
   "giver": "Protest Denizen",
   "spirit": "astrid",
   "description": "I'm in the middle of a worker's strike and I love it.",
   "prereq": "",
   "location": "Bottom Line Corp.",
   "onBoat": false,
   "rewards": [
    "Astrid",
    "Obol"
   ],
   "repeatable": false,
   "prev": [
    "something-to-write-home-about"
   ],
   "next": [
    "feed-your-elders"
   ],
   "objectives": [
    {
     "text": "Talk to the protest leader.",
     "depth": 1
    },
    {
     "text": "Talk to the cowardly CEO.",
     "depth": 1
    },
    {
     "text": "Talk to the protest leader one more time.",
     "depth": 1
    },
    {
     "text": "Talk to the terrible CEO again.",
     "depth": 1
    },
    {
     "text": "Talk to the protest leader for the last time.",
     "depth": 1
    },
    {
     "text": "Talk to the obnoxious CEO one more time.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "bottom-line-corp",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "usonia-1",
   "title": "Usonia 1",
   "number": "1107",
   "type": "Requests",
   "giver": "Gwen",
   "spirit": "gwen",
   "description": "I remember Gwen's old condo. Everything looked so Nordic. It will be a blast from the past to see it on the boat.",
   "prereq": "Complete Jiving Chives.",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-more-the-merrier"
   ],
   "next": [
    "cut-from-the-same-cloth"
   ],
   "objectives": [
    {
     "text": "Build Gwen's Lodge.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "visions-of-oil",
   "title": "Visions of Oil",
   "number": "9110",
   "type": "Errands",
   "giver": "Buck",
   "spirit": "buck",
   "description": "What's with this one? A wandering merchant... that's clearly Francis, right?",
   "prereq": "Working on Postscripta",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Olive Oil x5",
    "Sunflower Oil x5"
   ],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Burnt Food x1",
     "depth": 1
    },
    {
     "text": "Questionable Meal x1",
     "depth": 1
    },
    {
     "text": "Old Shoe x1",
     "depth": 1
    },
    {
     "text": "Household Glue x1",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "welcome-aboard",
   "title": "Welcome Aboard",
   "number": "",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "",
   "prereq": "",
   "location": "Barkensheim Creek",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "sticky-fingers"
   ],
   "next": [
    "sea-master-2000"
   ],
   "objectives": [
    {
     "text": "Welcome your new passenger.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "barkensheim-creek",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "wells-fartgo-co",
   "title": "Wells Fartgo & CO",
   "number": "",
   "type": "Requests",
   "giver": "Jackie",
   "spirit": "jackie",
   "description": "I've received a letter from Jackie. I should read it!",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-slop-shop"
   ],
   "next": [
    "advanced-snackology"
   ],
   "objectives": [
    {
     "text": "Read A Letter From Jackie.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "woodwork",
   "title": "Woodwork",
   "number": "1204",
   "type": "Requests",
   "giver": "Atul",
   "spirit": "atul",
   "description": "Atul thinks my boat is empty without a sawmill. The more, the merrier, right?",
   "prereq": "",
   "location": "Stella's Boat",
   "onBoat": true,
   "rewards": [],
   "repeatable": false,
   "prev": [
    "the-drawing-board"
   ],
   "next": [
    "measure-twice-cut-once"
   ],
   "objectives": [
    {
     "text": "Build a Sawmill.",
     "depth": 1
    }
   ],
   "notes": [
    "Completing this quest will give Atul a mood boost (+2) because he’s excited about the new sawmill."
   ],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "working-dummies",
   "title": "Working Dummies",
   "number": "",
   "type": "Shenanigans",
   "giver": "Overbrook Kitchen Staff",
   "spirit": null,
   "description": "At this point, I'm afraid to ask what kind of dummies they will make!",
   "prereq": "Three's Company",
   "location": "Hoseki Quarry",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Find the materials for the chef in Hoseki Quarry.",
     "depth": 1
    },
    {
     "text": "Maple Log (0/7)",
     "depth": 2
    },
    {
     "text": "Linen Fabric (0/7)",
     "depth": 2
    },
    {
     "text": "Carrot (0/7)",
     "depth": 2
    }
   ],
   "notes": [],
   "waypoints": [
    {
     "kind": "island",
     "ref": "hoseki-quarry",
     "step": 0,
     "why": "Quest location",
     "role": "single"
    }
   ],
   "image": "",
   "spoiler": false
  },
  {
   "id": "youve-got-mail",
   "title": "You've Got Mail!",
   "number": "9007",
   "type": "Shenanigans",
   "giver": "Albert The Shipwright",
   "spirit": null,
   "description": "I should have letters waiting for me in my new mailbox.",
   "prereq": "Build the Mailbox.",
   "location": "",
   "onBoat": false,
   "rewards": [],
   "repeatable": false,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Check your newly built mailbox.",
     "depth": 1
    },
    {
     "text": "A Letter from Albert (0/1)",
     "depth": 2
    },
    {
     "text": "Read your first letter.",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  },
  {
   "id": "zip-away",
   "title": "Zip & Away",
   "number": "9116",
   "type": "Errands",
   "giver": "Francis",
   "spirit": null,
   "description": "",
   "prereq": "",
   "location": "",
   "onBoat": false,
   "rewards": [
    "Metal Rope x5"
   ],
   "repeatable": true,
   "prev": [],
   "next": [],
   "objectives": [
    {
     "text": "Wool Thread x10",
     "depth": 1
    },
    {
     "text": "Linen Thread x10",
     "depth": 1
    }
   ],
   "notes": [],
   "waypoints": [],
   "image": "",
   "spoiler": false
  }
 ]
}
SPIRITFARER_EOF

cat > "public/icon.svg" << 'SPIRITFARER_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <radialGradient id="sea" cx="50%" cy="55%" r="70%">
      <stop offset="0%" stop-color="#1c3f5a"/>
      <stop offset="65%" stop-color="#14304a"/>
      <stop offset="100%" stop-color="#0b1622"/>
    </radialGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#fff4d6"/>
      <stop offset="30%" stop-color="#f6a76b" stop-opacity="0.85"/>
      <stop offset="100%" stop-color="#c2410c" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="512" height="512" fill="url(#sea)"/>
  <circle cx="256" cy="232" r="150" fill="url(#glow)"/>
  <circle cx="256" cy="232" r="46" fill="#fff7e6" stroke="#f97316" stroke-width="10"/>
  <path d="M96 352 Q136 336 176 352 T256 352 T336 352 T416 352" fill="none" stroke="#9ec9e0" stroke-opacity="0.45" stroke-width="10" stroke-linecap="round"/>
  <path d="M136 396 Q176 380 216 396 T296 396 T376 396" fill="none" stroke="#9ec9e0" stroke-opacity="0.25" stroke-width="10" stroke-linecap="round"/>
  <path d="M188 318 L324 318 L304 346 L208 346 Z" fill="#e9d8b4" stroke="#0b1622" stroke-width="6" stroke-linejoin="round"/>
  <path d="M256 318 L256 250 L296 304 Z" fill="#fdf6e3" stroke="#0b1622" stroke-width="5" stroke-linejoin="round"/>
</svg>
SPIRITFARER_EOF

cat > "public/manifest.webmanifest" << 'SPIRITFARER_EOF'
{
  "name": "Spiritfarer — Everlight Atlas",
  "short_name": "Everlight Atlas",
  "description": "Unofficial interactive island map and quest log for Spiritfarer.",
  "id": "./",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "orientation": "any",
  "background_color": "#0b1622",
  "theme_color": "#132a3e",
  "categories": ["games", "utilities"],
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" },
    { "src": "icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any" }
  ]
}
SPIRITFARER_EOF

cat > "public/sw.js" << 'SPIRITFARER_EOF'
// Everlight Atlas service worker: makes the installed app work offline.
// - The app itself (one self-contained index.html) is network-first, so updates arrive as soon as you're online.
// - Fonts and wiki artwork are cache-first after the first view, so islands you've browsed keep their pictures offline.
const VERSION = "v1.1.1";
const SHELL = `atlas-shell-${VERSION}`;
// Bumped in v1.1.1 to drop the "No image" placeholders cached while requests still carried a Referer.
const RUNTIME = "atlas-runtime-2";
const SHELL_FILES = ["./", "./manifest.webmanifest", "./icon.svg", "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png"];
const RUNTIME_MAX = 400;

self.addEventListener("install", e => {
  e.waitUntil(caches.open(SHELL).then(c => c.addAll(SHELL_FILES)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => (k.startsWith("atlas-shell-") && k !== SHELL) || (k.startsWith("atlas-runtime") && k !== RUNTIME)).map(k => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

async function trim(cache) {
  const keys = await cache.keys();
  for (const k of keys.slice(0, Math.max(0, keys.length - RUNTIME_MAX))) await cache.delete(k);
}

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  // App shell: network first, fall back to the cached copy when offline.
  if (req.mode === "navigate" || url.origin === location.origin) {
    e.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) { const copy = res.clone(); caches.open(SHELL).then(c => c.put(req.mode === "navigate" ? "./" : req, copy)); }
          return res;
        })
        .catch(() => caches.match(req.mode === "navigate" ? "./" : req, { ignoreSearch: true })),
    );
    return;
  }

  // Fonts and wiki images: cache first, then network (opaque cross-origin responses are fine to cache).
  if (/fonts\.(googleapis|gstatic)\.com$|(^|\.)(wikia\.nocookie\.net|fandom\.com)$/.test(url.hostname) || req.destination === "image") {
    e.respondWith(
      caches.open(RUNTIME).then(async cache => {
        const hit = await cache.match(req);
        if (hit) return hit;
        const res = await fetch(req);
        if (res.ok || res.type === "opaque") { cache.put(req, res.clone()); trim(cache); }
        return res;
      }),
    );
  }
});
SPIRITFARER_EOF

# ── Install & Build ───────────────────────────────────────────────────────────
echo "📦  Installing project dependencies..."
npm install 2>/dev/null

echo ""
echo "🔨  Building..."
npm run build 2>/dev/null

OUTPUT="$PROJECT_DIR/dist/index.html"
if [ ! -f "$OUTPUT" ]; then
  echo "❌  Build failed — dist/index.html not found. Run 'npm run build' in $PROJECT_DIR to see why."
  exit 1
fi

echo ""
echo "✅  Build complete!"
echo ""

# ── Launch in a standalone GUI window ────────────────────────────────────────
APP_TITLE="Spiritfarer — Everlight Atlas"
FILE_URI="file://$OUTPUT"

launch_chromium_app() {
  local bin=$1
  "$bin" --app="$FILE_URI" --name="$APP_TITLE" \
    --no-first-run --no-default-browser-check \
    --disable-extensions --disable-translate --disable-infobars \
    --window-size=1500,950 2>/dev/null &
}

launch_gtk_window() {
  local py="$PROJECT_DIR/launcher.py"
  cat > "$py" << 'PYEOF'
#!/usr/bin/env python3
import gi, sys, os
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk, WebKit2
win = Gtk.Window()
win.set_title("Spiritfarer — Everlight Atlas")
win.set_default_size(1500, 950)
win.set_position(Gtk.WindowPosition.CENTER)
try: win.set_icon_name("applications-games")
except: pass
win.connect("destroy", Gtk.main_quit)
webview = WebKit2.WebView()
settings = webview.get_settings()
settings.set_enable_javascript(True)
webview.load_uri("file://" + os.path.abspath(sys.argv[1]))
win.add(webview)
win.show_all()
Gtk.main()
PYEOF
  python3 "$py" "$OUTPUT" 2>/dev/null &
}

echo "🖥️   Launching standalone GUI window..."

if command -v chromium-browser &>/dev/null; then launch_chromium_app "chromium-browser"
elif command -v chromium &>/dev/null; then launch_chromium_app "chromium"
elif command -v google-chrome &>/dev/null; then launch_chromium_app "google-chrome"
elif command -v google-chrome-stable &>/dev/null; then launch_chromium_app "google-chrome-stable"
elif python3 -c "import gi; gi.require_version('WebKit2','4.0'); from gi.repository import WebKit2" 2>/dev/null; then launch_gtk_window
elif command -v firefox &>/dev/null; then firefox "$FILE_URI" 2>/dev/null &
elif flatpak info org.mozilla.firefox &>/dev/null; then flatpak run --filesystem="$PROJECT_DIR/dist:ro" org.mozilla.firefox "$FILE_URI" 2>/dev/null &
elif command -v xdg-open &>/dev/null; then xdg-open "$OUTPUT" 2>/dev/null &
else echo "⚠️   No browser found. Open manually: $OUTPUT"
fi

echo "✅  Done!"
