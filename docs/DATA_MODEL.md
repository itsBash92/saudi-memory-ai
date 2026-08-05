# Data Model and Trust

## Core entities

| Entity | Purpose |
| --- | --- |
| `profiles` | Public-safe display name and avatar only |
| `profile_roles` | Private reviewer and administrator authorization |
| `places` | Place identity, coordinates, story, and publication state |
| `memories` | Personal account connected to a place and contributor |
| `media_assets` | Media, rights confirmation, and privacy-processing state |
| `sources` | Moderated official, research, archival, or otherwise traceable references |
| `memory_sources` | Evidence links between contributions and references |
| `ai_reviews` | Model, decision, reasons, and confidence from automated checks |
| `moderation_reviews` | Append-only reviewer decisions and previous states |
| `points_ledger` | Append-only point events |
| `badges` and `user_badges` | Badge definitions and awards |
| `redemptions` | Reward requests when a partner integration is enabled |

Point balances, contribution counts, and badge counts are derived from their source tables through `get_my_profile_stats()` instead of being duplicated on public profiles.

## Content states

- `draft`: visible only to its contributor and authorized reviewers.
- `pending`: undergoing automated or human review.
- `verified`: reviewed and eligible for publication.
- `needs_context`: requires a source or clarification.
- `rejected`: does not meet policy, with an appealable reason.

## Confidence score

A value from `0` to `1` combines independent signals such as:

- visual similarity to a known place;
- plausible spatial and temporal context;
- source quality and independence;
- consistency with verified information;
- contributor reliability based on earlier reviews, without allowing points to purchase credibility.

The score supports ranking and routing; it is not proof on its own.

## Mutation and access rules

- Public reads include only verified places, memories, and sources.
- Contributors can read and edit their own drafts and pending submissions, but cannot write review status, confidence, verification, points, or privacy-processing fields.
- Reviewers use narrowly scoped database functions for place, memory, source, and media decisions.
- Points and badges are awarded through reviewer-only functions; the points ledger is append-only to browser roles.
- Media belongs to exactly one place or memory, and AI reviews target exactly one place, memory, or media asset.
- Coordinates are either fully absent or supplied as a valid latitude/longitude pair.
