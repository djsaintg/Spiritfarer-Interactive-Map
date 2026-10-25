export type Region = "Everdoor" | "Hummingberg" | "Furogawa" | "Industrial District" | "Oxbury" | "Crow's End";

export interface Chest { text: string; needs: string[] }
export interface Section { heading: string; lines: string[] }

export interface Island {
  id: string; name: string; region: Region;
  x: number; y: number; bus: [number, number] | null;
  requirements: string[]; spirits: string[];
  resources: string[]; shop: string[]; other: string[];
  intro: string[]; chests: Chest[]; sections: Section[];
  image: string; spoiler: boolean;
}

export interface Spirit {
  id: string; name: string; species: string;
  origin: string | null; originText: string;
  house: string; event: string; favouriteFood: string;
  likes: string; dislikes: string; skills: string; flower: string;
  firstQuest: string; lastQuest: string;
  about: string[]; life: string[]; everdoor: string[];
  image: string; dlc: boolean; quests: string[];
}

export interface EventPoint { x: number; y: number; label: string }
export interface SeaEvent {
  id: string; name: string; spirit: string | null;
  resource: string; duration: string; requires: string; house: string;
  trigger: "sea" | "island" | "manual"; island: string | null;
  points: EventPoint[]; approx: boolean; regionText: string;
  details: string[]; image: string;
}

export type WaypointRole = "start" | "mid" | "end" | "single";
export interface Waypoint {
  kind: "island" | "point";
  ref: string | [number, number];
  step: number; why: string; role: WaypointRole;
}
export interface Objective { text: string; depth: number }
export type QuestType = "Requests" | "Shenanigans" | "Errands";
export interface Quest {
  id: string; title: string; number: string; type: QuestType;
  giver: string; spirit: string | null;
  description: string; prereq: string; location: string; onBoat: boolean;
  rewards: string[]; repeatable: boolean;
  prev: string[]; next: string[];
  objectives: Objective[]; notes: string[];
  waypoints: Waypoint[]; image: string; spoiler: boolean;
}

export interface Ability { name: string; island: string | null; unlock: string; controls: string; details: string[] }
export interface Treasure { x: number; y: number; source: string; reward: string }
export interface BusStop { x: number; y: number; near: string[] }

export interface GameData {
  source: string; imageBase: string;
  worldMap: { url: string; bounds: { x0: number; x1: number; yTop: number; yBottom: number } };
  regions: Region[];
  islands: Island[]; spirits: Spirit[]; abilities: Ability[];
  treasures: Treasure[]; busStops: BusStop[];
  events: SeaEvent[]; quests: Quest[];
}

export type QuestStatus = "todo" | "active" | "done";
export interface Progress {
  version: 1;
  quests: Record<string, { status: QuestStatus; steps: number[] }>;
  islands: Record<string, { visited?: boolean; chests?: number[]; notes?: string }>;
}

export type Selection =
  | { kind: "island"; id: string }
  | { kind: "quest"; id: string }
  | { kind: "event"; id: string }
  | { kind: "spirit"; id: string }
  | null;

export type Tab = "islands" | "quests" | "events" | "spirits" | "progress";
