# Seedforce Deployment Guide

## Prerequisites

- Salesforce CLI
- An authenticated target org
- Node.js 20+ only when rebuilding Faker or running local Jest/lint checks

## Build and verify locally

```bash
npm install
npm run build:faker
npm run verify:faker
npm run test:unit
npm run lint
npm run format:check
```

## Validate and deploy

Use the explicit manifest so configuration objects, permissions, LWCs, Apex, Faker, and branding resources remain synchronized.

The manifest intentionally excludes `Address.settings`. Deploying retrieved address settings could overwrite the target org's State and Country/Territory Picklist configuration. Seedforce reads the target org's active values dynamically.

```bash
sf project deploy validate \
  --manifest manifest/package.xml \
  --target-org <org-alias> \
  --test-level RunLocalTests \
  --wait 30

sf project deploy start \
  --manifest manifest/package.xml \
  --target-org <org-alias> \
  --wait 30
```

## Assign permissions

```bash
sf org assign permset --name Seedforce_User --target-org <org-alias>
sf org assign permset --name Seedforce_Administrator --target-org <org-alias>
```

- Assign `Seedforce_User` to everyone using the wizard.
- Assign `Seedforce_Administrator` only to configuration managers.
- Administrators using both surfaces need both permission sets.
- Grant target-object CRUD/FLS through the organization’s existing security model.

## Configure Lightning pages

1. Add **Seedforce Data Generator** to an App Page, Home Page, or Lightning tab.
2. Add **Seedforce Configuration** to an administrator-only page or tab.
3. Activate the pages for the intended apps and profiles.
4. Open Configuration and save only when overrides are desired; empty configuration already uses packaged defaults.

## Post-deployment checks

1. Confirm both Seedforce headers display the logo.
2. Search for a createable object in the lookup.
3. Configure required fields and generate a one-record preview in each required locale.
4. Insert the record and verify the Record ID link opens its Lightning record page.
5. Disable a nonessential generator in Configuration, reload the wizard, and confirm it no longer appears.
6. Add a low-priority test recommendation rule and confirm it changes the recommended generator.

Salesforce can cache static resources and Lightning bundles after deployment. Use a hard browser refresh if an old Faker bundle or logo remains visible.
