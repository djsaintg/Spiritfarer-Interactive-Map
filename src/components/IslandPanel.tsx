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
