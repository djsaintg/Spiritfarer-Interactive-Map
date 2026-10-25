import raw from "./data/spiritfarer.json";
import type { GameData, Island, Quest, Region, SeaEvent, Spirit, Waypoint } from "./types";

export const data = raw as unknown as GameData;

export const islandById = new Map<string, Island>(data.islands.map(i => [i.id, i]));
export const questById = new Map<string, Quest>(data.quests.map(q => [q.id, q]));
export const spiritById = new Map<string, Spirit>(data.spirits.map(s => [s.id, s]));
export const eventById = new Map<string, SeaEvent>(data.events.map(e => [e.id, e]));
export const spiritByName = new Map<string, Spirit>(data.spirits.map(s => [s.name, s]));

export const img = (path: string) => (path ? data.imageBase + path : "");

export const REGION_COLORS: Record<Region, string> = {
  "Everdoor": "#f0a868",
  "Hummingberg": "#7fb7a4",
  "Furogawa": "#e08a7a",
  "Industrial District": "#9aa3c7",
  "Oxbury": "#d9b25f",
  "Crow's End": "#a98bc9",
};

export const ROLE_COLORS = { start: "#4ade80", mid: "#fbbf24", end: "#f87171", single: "#38bdf8" } as const;
export const ROLE_LABEL = { start: "Start", mid: "Waypoint", end: "Finish", single: "Start & finish" } as const;

/** Game coordinates (y up) for a waypoint. */
export function waypointPos(w: Waypoint): { x: number; y: number; label: string } {
  if (w.kind === "island") {
    const i = islandById.get(w.ref as string);
    return i ? { x: i.x, y: i.y, label: i.name } : { x: 0, y: 0, label: String(w.ref) };
  }
  const [x, y] = w.ref as [number, number];
  return { x, y, label: `Coordinates ${x}, ${y}` };
}

/** Quests that pass through an island, with the role the island plays in each. */
export const questsByIsland = new Map<string, { quest: Quest; roles: Waypoint["role"][] }[]>();
for (const q of data.quests) {
  const seen = new Map<string, Waypoint["role"][]>();
  for (const w of q.waypoints) {
    if (w.kind !== "island") continue;
    const id = w.ref as string;
    seen.set(id, [...(seen.get(id) ?? []), w.role]);
  }
  for (const [id, roles] of seen) {
    questsByIsland.set(id, [...(questsByIsland.get(id) ?? []), { quest: q, roles }]);
  }
}

/** Events whose points sit at or near an island (within `r` map units). */
export function eventsNear(i: Island, r = 30): SeaEvent[] {
  return data.events.filter(e => e.island === i.id ||
    (!e.approx && e.points.some(p => Math.hypot(p.x - i.x, p.y - i.y) <= r)));
}

export const abilityAt = (islandId: string) => data.abilities.filter(a => a.island === islandId);

/** Islands that can't be found without a treasure map or special unlock. */
export const SECRET_ISLANDS = new Set(["lost-shrine", "hidden-shrine"]);

export const QUEST_GROUPS: { id: string; label: string; filter: (q: Quest) => boolean }[] = [
  ...data.spirits.map(s => ({ id: s.id, label: s.name, filter: (q: Quest) => q.spirit === s.id })),
  { id: "shenanigans", label: "Shenanigans", filter: (q: Quest) => q.type === "Shenanigans" && !q.spirit },
  { id: "errands", label: "Francis's Errands", filter: (q: Quest) => q.type === "Errands" && !q.spirit },
  { id: "other", label: "Other", filter: (q: Quest) => q.type === "Requests" && !q.spirit },
];
