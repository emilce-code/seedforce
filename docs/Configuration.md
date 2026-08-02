# Seedforce Configuration Guide

## Access

Assign `Seedforce_Administrator` to configuration managers. Administrators who also use the generation wizard need `Seedforce_User` and normal target-object CRUD/FLS.

Add **Seedforce Configuration** to an administrator-only Lightning App Page, Home Page, or Lightning tab.

## Generator options

The Generator Options section lists every registered Faker strategy. Administrators can configure:

- **Active:** whether the generator appears in field comboboxes and may be recommended.
- **Display label:** the user-facing combobox label.
- **Order:** ascending display order.

The immutable key identifies the code strategy and cannot be changed. Saving the page initializes or updates one unique org-wide setting per generator. If no records exist, all packaged generators are active with default labels and ordering.

## Recommendation rules

Rules override built-in recommendations. Lower priority numbers are evaluated first.

| Setting            | Behavior                                                 |
| ------------------ | -------------------------------------------------------- |
| Active             | Enables or disables the rule without deleting it.        |
| Name               | Administrator-facing description.                        |
| Field type         | Salesforce Describe type or Any field type.              |
| Field name pattern | Optional exact API name or wildcard pattern.             |
| Generator          | Strategy recommended when the rule matches.              |
| Priority           | Evaluation order; lower numbers run first.               |
| Min/Max length     | Optional constraints against the described field length. |

Pattern examples:

- `Email` matches exactly `Email`.
- `*Email*` matches any field API name containing `Email`.
- `Billing*` matches fields starting with `Billing`.
- `*Description` matches fields ending with `Description`.

Inactive generators are never recommended, even when referenced by a rule. When no custom rule matches, Seedforce uses its built-in semantic recommendation and then a compatible primitive fallback.

## Safe administration

- Keep at least the primitive generators used by required fields active.
- Use small priority gaps such as 10, 20, and 30 to make later insertions easier.
- Test new rules against representative standard and custom objects before broad rollout.
- Use length constraints for text versus textarea recommendations.
- Prefer Picklist Value for every Salesforce picklist so generated values remain valid for the target org.
