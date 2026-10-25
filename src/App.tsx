import { useCallback, useEffect, useRef, useState } from "react";
import { BookOpen, Compass, Eye, EyeOff, Layers, Map as MapIcon, ScrollText, Sparkles, Users } from "lucide-react";
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
    const close =(e: MouseEvent) => { if (!layersRef.current?.contains(e.target as Node)) setLayersOpen(false); };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, []);

  const idFor = (k: NonNullable<Selection>["kind"]) => (selection?.kind === k ? selection.id : null);
  // Going "back" in a panel clears the selection but stays on that tab.
  const panelSelect = (s: Selection, fly?: boolean) => (s ? select(s, fly) : setSelection(null));

  return (
    <SpoilerContext.Provider value={settings.showSpoilers}>
      <div className="flex h-screen flex-col bg-[#0b1622] text-slate-100">
        <header className="flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-white/10 bg-gradient-to-r from-[#132a3e] via-[#1a2f45] to-[#2a2440] px-4 py-2.5">
          <div className="flex items-baseline gap-2">
            <h1 className="font-display text-xl font-semibold tracking-wide text-amber-100">Spiritfarer</h1>
            <span className="font-hand text-lg text-amber-200/70">Everlight Atlas</span>
          </div>
          <div className="ml-auto flex flex-wrap items-center gap-2">
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
              {settings.showSpoilers ? <Eye size={14} /> : <EyeOff size={14} />} Spoilers {settings.showSpoilers ? "shown" : "hidden"}
            </button>
          </div>
        </header>

        <div className="flex min-h-0 flex-1 flex-col md:flex-row">
          <main className="relative h-[55vh] min-h-0 md:h-auto md:flex-1">
            <WorldMap settings={settings} api={api} selection={selection} onSelect={s => select(s)} focusKey={focusKey} />
          </main>
          <aside className="flex min-h-0 flex-1 flex-col border-t border-white/10 bg-[#101f2e] md:w-[430px] md:flex-none md:border-l md:border-t-0">
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
            <footer className="flex items-center gap-1.5 border-t border-white/5 px-4 py-1.5 text-[10px] text-slate-500">
              <MapIcon size={11} /> Unofficial fan tool · data: Spiritfarer Fandom Wiki (CC-BY-SA) · Spiritfarer © Thunder Lotus Games
            </footer>
          </aside>
        </div>
      </div>
    </SpoilerContext.Provider>
  );
}
