import { useCallback, useEffect, useState } from "react";
import type { Progress, QuestStatus } from "./types";
import { questById } from "./data";

const PROGRESS_KEY = "spiritfarer-map:progress";
const SETTINGS_KEY = "spiritfarer-map:settings";

const emptyProgress = (): Progress => ({ version: 1, quests: {}, islands: {} });

function load<T>(key: string, fallback: T): T {
  try {
    const v = localStorage.getItem(key);
    return v ? { ...fallback, ...JSON.parse(v) } : fallback;
  } catch {
    return fallback;
  }
}
function save(key: string, value: unknown) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* storage unavailable */ }
}

export function useProgress() {
  const [progress, setProgress] = useState<Progress>(() => load(PROGRESS_KEY, emptyProgress()));
  useEffect(() => save(PROGRESS_KEY, progress), [progress]);

  const questStatus = useCallback((id: string): QuestStatus => progress.quests[id]?.status ?? "todo", [progress]);
  const questSteps = useCallback((id: string) => progress.quests[id]?.steps ?? [], [progress]);

  const setQuestStatus = useCallback((id: string, status: QuestStatus) => {
    setProgress(p => {
      const steps = status === "done" ? (questById.get(id)?.objectives.map((_, i) => i) ?? []) : (p.quests[id]?.steps ?? []);
      return { ...p, quests: { ...p.quests, [id]: { status, steps: status === "todo" ? [] : steps } } };
    });
  }, []);

  const toggleStep = useCallback((id: string, step: number) => {
    setProgress(p => {
      const cur = p.quests[id] ?? { status: "todo" as QuestStatus, steps: [] };
      const steps = cur.steps.includes(step) ? cur.steps.filter(s => s !== step) : [...cur.steps, step];
      const total = questById.get(id)?.objectives.length ?? 0;
      const status: QuestStatus = total > 0 && steps.length >= total ? "done" : steps.length > 0 ? "active" : cur.status === "done" ? "active" : cur.status;
      return { ...p, quests: { ...p.quests, [id]: { status, steps } } };
    });
  }, []);

  const updateIsland = useCallback((id: string, patch: Progress["islands"][string]) => {
    setProgress(p => ({ ...p, islands: { ...p.islands, [id]: { ...p.islands[id], ...patch } } }));
  }, []);

  const toggleChest = useCallback((id: string, n: number) => {
    setProgress(p => {
      const cur = p.islands[id]?.chests ?? [];
      const chests = cur.includes(n) ? cur.filter(c => c !== n) : [...cur, n];
      return { ...p, islands: { ...p.islands, [id]: { ...p.islands[id], chests } } };
    });
  }, []);

  const exportJson = useCallback(() => JSON.stringify({ app: "spiritfarer-map", exportedAt: new Date().toISOString(), ...progress }, null, 2), [progress]);

  const importJson = useCallback((text: string): string | null => {
    try {
      const parsed = JSON.parse(text);
      if (typeof parsed !== "object" || !parsed || typeof parsed.quests !== "object" || typeof parsed.islands !== "object") {
        return "That file doesn't look like a Spiritfarer Map progress export.";
      }
      setProgress({ version: 1, quests: parsed.quests, islands: parsed.islands });
      return null;
    } catch {
      return "Couldn't read that file as JSON.";
    }
  }, []);

  const reset = useCallback(() => setProgress(emptyProgress()), []);

  return { progress, questStatus, questSteps, setQuestStatus, toggleStep, updateIsland, toggleChest, exportJson, importJson, reset };
}
export type ProgressApi = ReturnType<typeof useProgress>;

export interface Settings {
  background: "chart" | "wiki";
  showSpoilers: boolean;
  layers: { islands: boolean; labels: boolean; events: boolean; busStops: boolean; treasures: boolean; shrines: boolean; activeQuests: boolean; grid: boolean };
  dimDone: boolean;
}
const defaultSettings: Settings = {
  background: "chart",
  showSpoilers: false,
  layers: { islands: true, labels: true, events: true, busStops: false, treasures: false, shrines: true, activeQuests: true, grid: true },
  dimDone: true,
};

export function useSettings() {
  const [settings, setSettings] = useState<Settings>(() => {
    const s = load(SETTINGS_KEY, defaultSettings);
    return { ...s, layers: { ...defaultSettings.layers, ...s.layers } };
  });
  useEffect(() => save(SETTINGS_KEY, settings), [settings]);
  return [settings, setSettings] as const;
}
