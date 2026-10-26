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
