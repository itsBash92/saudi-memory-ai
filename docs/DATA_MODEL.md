# Data Model and Trust

## Core entities

| Entity | Purpose |
| --- | --- |
| `profiles` | User profile, role, and aggregate points |
| `places` | Place identity, coordinates, story, and publication state |
| `memories` | Personal account connected to a place and contributor |
| `media_assets` | Media, rights confirmation, and privacy-processing state |
| `sources` | Official, research, archival, or otherwise traceable references |
| `memory_sources` | Evidence links between contributions and references |
| `ai_reviews` | Model, decision, reasons, and confidence from automated checks |
| `points_ledger` | Append-only point events |
| `badges` and `user_badges` | Badge definitions and awards |
| `redemptions` | Reward requests when a partner integration is enabled |

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
