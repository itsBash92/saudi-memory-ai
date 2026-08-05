# Security and Privacy

## Reporting a vulnerability

Do not publish vulnerability details in a public issue. Use GitHub's **Report a vulnerability** form in this repository's Security tab. Include reproduction steps and expected impact, but never include real credentials or personal data.

If private vulnerability reporting is temporarily unavailable, wait for it to be restored rather than disclosing the issue publicly.

## Current prototype boundary

The checked-in web experience uses local illustrative data. It does not authenticate users, upload media, call an AI provider, or connect to a production database. The Supabase migration is a security-first starting schema for the later backend milestone; it is not evidence that a production service is currently operating.

## Baseline controls

- Service credentials remain server-side and never use the `NEXT_PUBLIC_` prefix.
- PostgreSQL tables enable Row Level Security and grant only the columns required for each client operation.
- Reviewer roles are stored separately from public profiles and reviewer decisions go through audited database functions.
- The media bucket is private, constrains content type and size, and isolates each contributor's upload path.
- Production media processing must scan content and remove sensitive EXIF metadata before publication.
- Production download and preview URLs must be short-lived and scoped.
- Changes to verified content must remain attributable through review records and database audit logs.
- Facial recognition is explicitly outside the project scope.
- Precise coordinates for sensitive places are not displayed publicly.

## Personal data

Users are not required to publish their real names. Before a public launch, the product must provide deletion, export, consent withdrawal, and a documented retention policy.
