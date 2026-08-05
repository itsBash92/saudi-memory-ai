# Security and Privacy

## Reporting a vulnerability

Do not publish vulnerability details in a public issue. Contact the repository owner privately with reproduction steps and expected impact, without including real user data.

## Baseline controls

- Service credentials remain server-side and never use the `NEXT_PUBLIC_` prefix.
- PostgreSQL data is protected with Row Level Security.
- Uploaded media is scanned and sensitive EXIF metadata is removed before publication.
- Upload URLs are temporary and constrained by content type and size.
- Changes to verified content are recorded in an audit trail.
- Facial recognition is explicitly outside the project scope.
- Precise coordinates for sensitive places are not displayed publicly.

## Personal data

Users are not required to publish their real names. Before a public launch, the product must provide deletion, export, consent withdrawal, and a documented retention policy.
