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
