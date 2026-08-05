# Contributing

Contributions are welcome when they improve the product or help preserve Saudi local memory responsibly.

## Before you start

1. Open an issue describing the problem or proposed capability.
2. Use a focused branch name such as `feature/place-recognition` or `fix/memory-card`.
3. Never commit secrets, API keys, private location data, or personal media without permission.
4. Install the locked dependency set with `npm ci`.
5. Run `npm run check` before opening a pull request.

## Content standards

- Cite a source whenever a claim is historical or independently verifiable.
- Keep personal accounts distinct from historical facts.
- Respect image rights and the privacy of people visible in media.
- Do not submit abusive content or disclose sensitive people or locations.
- Keep fixture and prototype content clearly labelled as illustrative; do not use plausible real contributor identities.

## Definition of done

- The interface works on mobile and desktop.
- Loading, error, and empty states are covered.
- English copy is clear and accessible; future Arabic surfaces must preserve correct RTL behavior.
- Sensitive changes include permission and privacy testing.
- Database changes preserve least-privilege grants, Row Level Security, and reviewer-only mutation paths.
- Documentation is updated when behavior or data models change.
