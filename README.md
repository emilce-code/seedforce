# Seedforce

![Seedforce logo](img/seedforce-logo-master.png)

Seedforce is a Salesforce-native application for generating realistic, configurable mock data directly inside Salesforce. Developers and administrators can select one supported object, configure its fields, preview 1–200 localized records, and insert them with normalized row-level results.

> **Because Empty Orgs Are Boring.**

## Current capabilities

- Searchable Salesforce-object lookup powered by dynamic Schema Describe
- Supported-field discovery with required unsupported-field explanations
- Select-all field configuration while preserving required fields
- Local Faker bundle with `en`, `es`, and `pt_BR` locale fallback chains
- 28 plug-in generators, including names, contact details, company data, addresses, numbers, dates, birthdays, picklists, and length-aware lorem content
- Intelligent recommendations based on field semantics, type, length, and administrator rules
- State/Country dependent-picklist safeguards and compound-address component handling
- Preview and confirmation before DML
- Dynamic `SObject` insertion through `Database.insert(records, false)`
- Row-level success/failure results with colored statuses and record-page links
- Org-wide administrator configuration for generator activation, labels, ordering, and recommendations
- Responsive SLDS interfaces with toasts, spinners, datatables, and accessible modal behavior

## Security and validation

The browser is never trusted as the authorization or validation boundary. Apex revalidates object CRUD, field createability, required fields, picklist values, lengths, numeric precision and scale, Boolean/date types, record count, and DML results. Raw Apex exceptions are normalized before crossing the controller boundary.

Seedforce does not grant access to target Salesforce objects. Users still require their normal profile or permission-set CRUD/FLS.

## Local development

Requirements: Node.js 20+, Salesforce CLI (`sf`), and an authenticated Salesforce org.

```bash
npm install
npm run build:faker
npm run verify:faker
npm run test:unit
npm run lint
npm run format:check
```

Faker is committed as `seedforceFaker.js`; production deployments never load JavaScript from a CDN.

## Deploy

```bash
sf project deploy start --manifest manifest/package.xml --target-org <org-alias>
sf apex run test --test-level RunLocalTests --target-org <org-alias> --wait 30
sf org assign permset --name Seedforce_User --target-org <org-alias>
sf org assign permset --name Seedforce_Administrator --target-org <org-alias>
```

Add **Seedforce Data Generator** to a Lightning App Page, Home Page, or Lightning tab. Add **Seedforce Configuration** to an administrator-only page or tab. Administrators who also generate records need both permission sets.

## Package layout

```text
force-app/main/default/
├── classes/          Controllers, application/domain services, validation, metadata, DTOs, and tests
├── lwc/              Generation wizard, configuration UI, registries, and Jest tests
├── objects/          Org-wide generator settings and recommendation-rule schema
├── permissionsets/   Seedforce user and administrator access
├── settings/         Reference address settings; intentionally excluded from the deployment manifest
└── staticresources/  Faker bundle and optimized Seedforce logo assets
manifest/package.xml  Explicit deployment manifest
img/                  Source and master branding assets
```

## Documentation

- [Architecture](docs/Architecture.md)
- [Configuration guide](docs/Configuration.md)
- [Deployment guide](docs/Deployment.md)
- [Future roadmap](docs/FutureRoadmap.md)
