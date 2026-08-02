public inherited sharing class SeedforceValidationService {
    public class ValidationOutcome {
        public List<SObject> validRecords = new List<SObject>();
        public Map<Integer, List<String>> rowErrors = new Map<Integer, List<String>>();
        public List<Integer> sourceRows = new List<Integer>();
    }

    public virtual ValidationOutcome validate(SeedforceDtos.GenerationRequest request, Schema.SObjectType typeToken) {
        if (request == null)
            throw new SeedforceException('Generation request is required.');
        if (request.recordCount == null || request.recordCount < 1 || request.recordCount > 200)
            throw new SeedforceException('Record count must be between 1 and 200.');
        if (request.records == null || request.records.size() != request.recordCount)
            throw new SeedforceException('Record count must match the number of preview records.');
        Schema.DescribeSObjectResult objectDescribe = typeToken.getDescribe();
        if (!objectDescribe.isCreateable())
            throw new SeedforceException('You do not have permission to create this object.');
        Map<String, Schema.SObjectField> fields = objectDescribe.fields.getMap();
        ValidationOutcome outcome = new ValidationOutcome();
        for (Integer rowIndex = 0; rowIndex < request.records.size(); rowIndex++) {
            Map<String, Object> source = request.records[rowIndex];
            SObject target = typeToken.newSObject();
            List<String> errors = new List<String>();
            if (source == null)
                source = new Map<String, Object>();
            Set<String> derivedAddressFields = getDerivedAddressFields(source);
            for (String fieldName : source.keySet()) {
                if (derivedAddressFields.contains(fieldName))
                    continue;
                Schema.SObjectField fieldToken = fields.get(fieldName);
                if (fieldToken == null) {
                    errors.add('Unknown field: ' + fieldName + '.');
                    continue;
                }
                Schema.DescribeFieldResult field = fieldToken.getDescribe();
                if (!field.isCreateable()) {
                    errors.add('No create access to ' + field.getLabel() + '.');
                    continue;
                }
                try {
                    target.put(fieldName, coerce(source.get(fieldName), field));
                } catch (Exception ignored) {
                    errors.add(field.getLabel() + ' has an invalid ' + String.valueOf(field.getType()) + ' value.');
                }
            }
            validateRequired(fields, target, errors);
            if (errors.isEmpty()) {
                outcome.validRecords.add(target);
                outcome.sourceRows.add(rowIndex);
            } else
                outcome.rowErrors.put(rowIndex, errors);
        }
        return outcome;
    }

    @TestVisible
    private static Set<String> getDerivedAddressFields(Map<String, Object> source) {
        Map<String, String> namesByLowercase = new Map<String, String>();
        for (String fieldName : source.keySet())
            namesByLowercase.put(fieldName.toLowerCase(), fieldName);

        Set<String> derivedFields = new Set<String>();
        for (String lowercaseName : namesByLowercase.keySet()) {
            String scalarName;
            if (lowercaseName.contains('countrycode'))
                scalarName = lowercaseName.replace('countrycode', 'country');
            else if (lowercaseName.contains('statecode'))
                scalarName = lowercaseName.replace('statecode', 'state');
            if (scalarName != null && namesByLowercase.containsKey(scalarName))
                derivedFields.add(namesByLowercase.get(scalarName));
        }
        return derivedFields;
    }

    private static Object coerce(Object raw, Schema.DescribeFieldResult field) {
        if (raw == null || String.isBlank(String.valueOf(raw)))
            return null;
        String value = String.valueOf(raw);
        Schema.DisplayType type = field.getType();
        if (
            type == Schema.DisplayType.String ||
            type == Schema.DisplayType.TextArea ||
            type == Schema.DisplayType.Email ||
            type == Schema.DisplayType.Phone ||
            type == Schema.DisplayType.Url
        ) {
            if (value.length() > field.getLength())
                throw new SeedforceException('Value is too long.');
            return value;
        }
        if (type == Schema.DisplayType.Boolean) {
            if (value.toLowerCase() != 'true' && value.toLowerCase() != 'false') {
                throw new SeedforceException('Invalid Boolean value.');
            }
            return Boolean.valueOf(value);
        }
        if (type == Schema.DisplayType.Integer)
            return Integer.valueOf(value);
        if (
            type == Schema.DisplayType.Double ||
            type == Schema.DisplayType.Currency ||
            type == Schema.DisplayType.Percent
        ) {
            Decimal numberValue = Decimal.valueOf(value);
            if (numberValue.scale() > field.getScale() || numberValue.precision() > field.getPrecision())
                throw new SeedforceException('Precision or scale exceeded.');
            return numberValue;
        }
        if (type == Schema.DisplayType.Date)
            return Date.valueOf(value);
        if (type == Schema.DisplayType.DateTime)
            return (Datetime) JSON.deserialize(JSON.serialize(value), Datetime.class);
        if (type == Schema.DisplayType.Picklist) {
            validatePicklist(value, field, false);
            return value;
        }
        if (type == Schema.DisplayType.MultiPicklist) {
            validatePicklist(value, field, true);
            return value;
        }
        throw new SeedforceException('Unsupported field type.');
    }

    private static void validatePicklist(String value, Schema.DescribeFieldResult field, Boolean multiple) {
        Set<String> allowed = new Set<String>();
        for (Schema.PicklistEntry entry : field.getPicklistValues())
            if (entry.isActive())
                allowed.add(entry.getValue());
        List<String> values = multiple ? value.split(';') : new List<String>{ value };
        for (String candidate : values)
            if (!allowed.contains(candidate))
                throw new SeedforceException('Invalid picklist value.');
    }

    private static void validateRequired(Map<String, Schema.SObjectField> fields, SObject record, List<String> errors) {
        for (Schema.SObjectField token : fields.values()) {
            Schema.DescribeFieldResult field = token.getDescribe();
            if (
                field.isCreateable() &&
                !field.isNillable() &&
                !field.isDefaultedOnCreate() &&
                !field.isCalculated() &&
                !field.isAutoNumber() &&
                record.get(field.getName()) == null
            ) {
                errors.add(field.getLabel() + ' is required.');
            }
        }
    }
}
