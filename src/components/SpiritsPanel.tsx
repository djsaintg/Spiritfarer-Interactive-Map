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
