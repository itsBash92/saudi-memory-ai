export type ContentStatus =
  | "draft"
  | "pending"
  | "verified"
  | "needs_context"
  | "rejected";

export interface PlacePreview {
  id: string;
  name: string;
  city: string;
  region: string;
  era: string;
  summary: string;
  memoriesCount: number;
  confidence: number;
  accent: "green" | "gold" | "blue";
  tags: string[];
  isIllustrative: boolean;
}

export interface MemoryPreview {
  id: string;
  placeId: string;
  title: string;
  excerpt: string;
  approximateYear: number;
  contributor: string;
  status: ContentStatus;
  evidenceCount: number;
  isIllustrative: boolean;
}
