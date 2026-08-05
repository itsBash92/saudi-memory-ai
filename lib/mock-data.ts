import type { MemoryPreview, PlacePreview } from "@/lib/types";

export const places: PlacePreview[] = [
  {
    id: "al-masmak",
    name: "Al Masmak Palace",
    city: "Riyadh",
    region: "Riyadh Province",
    era: "1865",
    summary:
      "A clay and mud-brick fortress in central Riyadh, tied to defining moments in the unification of Saudi Arabia and to generations of local memories.",
    memoriesCount: 128,
    confidence: 0.97,
    accent: "green",
    tags: ["History", "Najdi architecture", "Old Riyadh"],
  },
  {
    id: "jeddah-al-balad",
    name: "Historic Jeddah",
    city: "Jeddah",
    region: "Makkah Province",
    era: "7th century",
    summary:
      "A living urban fabric shaped around the gateway to the Two Holy Mosques, with Roshan houses, markets, and memories of sailors, pilgrims, and merchants.",
    memoriesCount: 214,
    confidence: 0.95,
    accent: "blue",
    tags: ["Roshan", "Red Sea", "World Heritage"],
  },
  {
    id: "alula-old-town",
    name: "AlUla Old Town",
    city: "AlUla",
    region: "Madinah Province",
    era: "12th century",
    summary:
      "A maze of mud-brick homes and narrow passageways preserving the memory of a community shaped for centuries by pilgrimage and trade routes.",
    memoriesCount: 91,
    confidence: 0.94,
    accent: "gold",
    tags: ["Oasis", "Mud-brick", "Pilgrimage route"],
  },
];

export const memories: MemoryPreview[] = [
  {
    id: "memory-1",
    placeId: "al-masmak",
    title: "Eid morning at Al Masmak",
    excerpt:
      "After Eid prayer, my father would take us to the square, point to the palace gates, and tell us how much smaller Riyadh once was.",
    approximateYear: 1987,
    contributor: "Umm Khalid",
    status: "verified",
    evidenceCount: 3,
  },
  {
    id: "memory-2",
    placeId: "jeddah-al-balad",
    title: "The vendors beneath the Roshan windows",
    excerpt:
      "By late afternoon the market changed its voice; vendors' calls mixed with the smell of bread and sea, and my grandmother knew every shop by its old name.",
    approximateYear: 1974,
    contributor: "Salem Al-Harbi",
    status: "verified",
    evidenceCount: 2,
  },
  {
    id: "memory-3",
    placeId: "alula-old-town",
    title: "The key to the mud-brick house",
    excerpt:
      "My grandfather kept a small wooden key until the end of his life. He said every scratch brought back a door, a face, and a story from the old town.",
    approximateYear: 1962,
    contributor: "Noura Al-Alawi",
    status: "pending",
    evidenceCount: 1,
  },
];
