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
