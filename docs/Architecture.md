# Seedforce Architecture

## Design goals

Seedforce is a package-oriented, Salesforce-native application. It uses Lightning Web Components, Apex, SLDS, dynamic Schema Describe, partial-success DML, locally bundled Faker, Apex tests, and Jest. No runtime asset is loaded from a CDN, and application logic does not hardcode a package namespace.

The MVP intentionally supports one object and 1–200 records per run. Its service and registry boundaries leave room for relationships, templates, schedules, masking, cross-org transport, and AI generators without coupling those features to the current wizard.

## Runtime flow

```text
seedforceWizard
  → SeedforceController
  → SeedforceApplicationService
  → SeedforceGenerationService
  → SeedforceValidationService
  → SeedforceMetadataService
  → Salesforce Schema API / Database.insert(records, false)

SeedforceConfiguration
  → SeedforceConfigurationController
  → SeedforceConfigurationService
  → Generator settings / Recommendation rules
```

The wizard owns presentation, interaction, and Faker preview generation. Apex owns metadata policy, recommendation resolution, security validation, dynamic-record construction, and DML orchestration. Controllers are small Aura boundaries that normalize exceptions into stable user-facing messages.

## Metadata policy

Objects are discovered dynamically and must be createable and non-deprecated. Platform events, custom metadata, history, share, feed, and change-event objects are excluded.

Supported field types are:

- Text and Text Area
- Email, Phone, and URL
- Boolean
- Integer, Double, Currency, and Percent
- Date and DateTime
- Picklist and Multi-Select Picklist

Calculated, autonumber, relationship, polymorphic, binary, and compound container fields are excluded. When an unsupported field is non-nullable and has no creation default, Seedforce reports it as an object blocker.

## Generator Strategy and Registry

`generatorRegistry.js` is the browser composition root for independent Faker strategies. Each strategy exposes an identifier, label, and `generate(context)` function. The registry performs lookup and option enumeration without branching on generator identifiers.

The Apex `SeedforceGeneratorCatalog` mirrors the public strategy catalog for administrator configuration. A new generator requires:

1. A strategy implementation and registration in the LWC composition root.
2. A catalog registration in Apex.
3. Optional built-in or configurable recommendation rules.
4. Focused Jest and Apex behavior tests.

Faker is constructed with locale fallback chains:

- `en → base`
- `es → en → base`
- `pt_BR → en → base`

The committed static-resource verification exercises locale-sensitive address and birthday APIs against the real bundle.

## Recommendation resolution

Built-in recommendations combine field API names, types, and described lengths. Examples include names, email, phone, addresses, birthday dates, person prefixes for Title, and length-aware lorem content for Description textareas.

Administrator rules run before built-ins in ascending priority order. A rule may constrain:

- Field type or any type
- Exact field API name or a leading/trailing `*` wildcard pattern
- Minimum and maximum described length
- Target generator

Inactive rules and rules targeting inactive generators are skipped. If a built-in recommendation is inactive, Seedforce selects a compatible primitive fallback when possible.

## Compound addresses and dependent picklists

The compound Address container is excluded, while its createable components are supported: Street, City, State, Postal Code, Country, CountryCode, StateCode, Latitude, Longitude, and Geocode Accuracy.

Picklist components always default to the Picklist Value strategy. CountryCode and StateCode generation uses locale-compatible country/state sets. Selecting StateCode requires the corresponding CountryCode. Code components are authoritative: when a code is present, the corresponding Country or State text component is omitted in both preview and Apex, allowing Salesforce to derive its configured display and integration value.

The repository contains retrieved `Address.settings` as a development reference, but the deployment manifest intentionally excludes it. State and Country/Territory Picklists are org-wide settings, and Seedforce must adapt to the target org rather than overwrite its country visibility, integration values, or defaults.

## Configuration persistence

`Seedforce_Generator_Option__c` stores org-wide activation, label, and ordering overrides for the immutable catalog. `Generator_Key__c` is a unique external identifier, preventing duplicate generator settings.

`Seedforce_Recommendation_Rule__c` stores ordered recommendation rules. Configuration uses custom-object data instead of Custom Metadata so the administrator LWC can save synchronously and return transactional validation errors. Empty configuration preserves all packaged defaults.

## Validation and DML

Client validation provides immediate usability feedback. Apex independently verifies:

- Record count and payload count
- Object create permission
- Field create permission
- Required fields
- Active picklist values
- Text length
- Numeric precision and scale
- Boolean, Date, and DateTime conversion
- Unknown or manipulated field names
- Address scalar/code normalization
- Per-record DML outcomes

Only validated dynamic records reach `Database.insert(records, false)`. Results are normalized into requested, inserted, failed, messages, and per-row status DTOs. Raw exceptions are never returned.

## Security and permissions

- Controllers use `with sharing`; services use inherited sharing.
- `Seedforce_User` grants Apex access and read-only configuration access.
- `Seedforce_Administrator` grants configuration-controller access and configuration-object CRUD.
- Neither permission set grants target-object CRUD/FLS.
- Configuration writes revalidate object CRUD in Apex.
- Required configuration fields rely on object permission and therefore do not appear as explicit permission-set field entries.
