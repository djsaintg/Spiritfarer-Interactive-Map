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
