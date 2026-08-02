# Future Roadmap

## Foundation hardening

- Add AppExchange security-review automation, accessibility audits, translations, telemetry hooks, and feature flags.
- Add a compatibility matrix so configuration prevents assigning semantically incompatible generators to field types.
- Add configuration import/export and packaged default recommendation templates.
- Evaluate protected Custom Metadata for the immutable catalog while retaining synchronous subscriber overrides in custom objects.
- Add Queueable execution for volumes beyond the synchronous 200-record boundary.

## Saved templates and run history

Persist versioned generation templates, selected fields, generator choices, locale, ownership, and immutable execution snapshots. Add run history, retention policies, and rerun behavior without coupling templates to UI DTOs.

## Relationship-aware generation

Introduce a generation-plan aggregate containing object nodes and relationship edges. A topological planner can generate parents before children, retain synthetic row keys, and resolve inserted IDs while preserving the current single-object service.

## Scheduled generation

Use Scheduled Apex to enqueue immutable template snapshots. Include idempotency keys, concurrency controls, failure notifications, and auditable run results.

## Cross-org seeding

Add a transport port with Named Credential implementations. Keep generation planning independent from destination authentication, API-version negotiation, Composite API, and Bulk API adapters.

## Data masking

Add reversible and irreversible masking strategies behind a separate registry. Policies should classify fields, preserve referential integrity, and support deterministic transforms where stable joins are required.

## AI-assisted generation

Add an opt-in provider interface behind Named Credentials. Prompts, output validation, grounding, PII policy, cost controls, and audit trails must remain isolated from deterministic Faker strategies. AI output must pass through the same Apex validation boundary before DML.
