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
        href={img(data.worldMap.url)} x={B.x0} y={-B.yTop} width={B.x1 - B.x0} height={B.yTop - B.yBottom}
        preserveAspectRatio="none" onError={() => setBgFailed(true)}
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
