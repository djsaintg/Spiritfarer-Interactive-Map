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
