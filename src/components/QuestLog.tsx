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
