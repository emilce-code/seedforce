public inherited sharing class SeedforceConfigurationService {
    public SeedforceDtos.SeedforceConfiguration getConfiguration() {
        Map<String, Seedforce_Generator_Option__c> storedByKey = new Map<String, Seedforce_Generator_Option__c>();
        for (Seedforce_Generator_Option__c stored : [
            SELECT Id, Name, Generator_Key__c, Active__c, Display_Label__c, Sort_Order__c
            FROM Seedforce_Generator_Option__c
        ])
            storedByKey.put(stored.Generator_Key__c, stored);
        List<SeedforceDtos.GeneratorSetting> generators = SeedforceGeneratorCatalog.defaults();
        for (SeedforceDtos.GeneratorSetting setting : generators) {
            Seedforce_Generator_Option__c stored = storedByKey.get(setting.key);
            if (stored == null)
                continue;
            setting.id = stored.Id;
            setting.active = stored.Active__c;
            if (String.isNotBlank(stored.Display_Label__c))
                setting.label = stored.Display_Label__c;
            if (stored.Sort_Order__c != null)
                setting.sortOrder = stored.Sort_Order__c.intValue();
        }
        generators.sort(new GeneratorComparator());
        SeedforceDtos.SeedforceConfiguration configuration = new SeedforceDtos.SeedforceConfiguration();
        configuration.generators = generators;
        configuration.rules = getRules();
        return configuration;
    }

    public List<SeedforceDtos.RecommendationRule> getRules() {
        List<SeedforceDtos.RecommendationRule> result = new List<SeedforceDtos.RecommendationRule>();
        for (Seedforce_Recommendation_Rule__c stored : [
            SELECT
                Id,
                Name,
                Active__c,
                Field_Type__c,
                Field_Name_Pattern__c,
                Generator_Key__c,
                Priority__c,
                Minimum_Length__c,
                Maximum_Length__c
            FROM Seedforce_Recommendation_Rule__c
            ORDER BY Priority__c ASC NULLS LAST, Name ASC
        ])
            result.add(toDto(stored));
        return result;
    }

    public String recommend(
        Schema.DescribeFieldResult field,
        String fallback,
        List<SeedforceDtos.RecommendationRule> rules,
        Set<String> activeKeys
    ) {
        for (SeedforceDtos.RecommendationRule rule : rules) {
            if (!rule.active || !activeKeys.contains(rule.generatorKey) || !matches(rule, field))
                continue;
            return rule.generatorKey;
        }
        return activeKeys.contains(fallback) ? fallback : compatibleFallback(field, activeKeys);
    }

    public SeedforceDtos.SeedforceConfiguration save(SeedforceDtos.ConfigurationSaveRequest request) {
        if (request == null)
            throw new SeedforceException('Configuration is required.');
        assertCanSave(request.deletedRuleIds);
        validate(request);
        Map<String, Id> optionIds = new Map<String, Id>();
        for (Seedforce_Generator_Option__c record : [SELECT Id, Generator_Key__c FROM Seedforce_Generator_Option__c])
            optionIds.put(record.Generator_Key__c, record.Id);
        List<Seedforce_Generator_Option__c> options = new List<Seedforce_Generator_Option__c>();
        for (SeedforceDtos.GeneratorSetting setting : request.generators)
            options.add(
                new Seedforce_Generator_Option__c(
                    Id = optionIds.get(setting.key),
                    Name = setting.key,
                    Generator_Key__c = setting.key,
                    Active__c = setting.active,
                    Display_Label__c = setting.label,
                    Sort_Order__c = setting.sortOrder
                )
            );
        upsert options;
        List<Seedforce_Recommendation_Rule__c> rules = new List<Seedforce_Recommendation_Rule__c>();
        for (SeedforceDtos.RecommendationRule rule : request.rules)
            rules.add(
                new Seedforce_Recommendation_Rule__c(
                    Id = String.isBlank(rule.id) ? null : Id.valueOf(rule.id),
                    Name = rule.name,
                    Active__c = rule.active,
                    Field_Type__c = rule.fieldType,
                    Field_Name_Pattern__c = rule.fieldNamePattern,
                    Generator_Key__c = rule.generatorKey,
                    Priority__c = rule.priority,
                    Minimum_Length__c = rule.minimumLength,
                    Maximum_Length__c = rule.maximumLength
                )
            );
        upsert rules;
        if (request.deletedRuleIds != null && !request.deletedRuleIds.isEmpty())
            delete [SELECT Id FROM Seedforce_Recommendation_Rule__c WHERE Id IN :request.deletedRuleIds];
        return getConfiguration();
    }

    private static void validate(SeedforceDtos.ConfigurationSaveRequest request) {
        Set<String> keys = SeedforceGeneratorCatalog.keys();
        if (request.generators == null || request.rules == null)
            throw new SeedforceException('Generators and rules are required.');
        for (SeedforceDtos.GeneratorSetting setting : request.generators)
            if (!keys.contains(setting.key) || String.isBlank(setting.label))
                throw new SeedforceException('Generator configuration contains an invalid key or label.');
        for (SeedforceDtos.RecommendationRule rule : request.rules) {
            if (String.isBlank(rule.name) || String.isBlank(rule.fieldType) || !keys.contains(rule.generatorKey))
                throw new SeedforceException('Every rule requires a name, field type, and valid generator.');
            if (rule.minimumLength != null && rule.maximumLength != null && rule.minimumLength > rule.maximumLength)
                throw new SeedforceException('A rule minimum length cannot exceed its maximum length.');
        }
    }

    private static void assertCanSave(List<String> deletedRuleIds) {
        Schema.DescribeSObjectResult generatorAccess = Seedforce_Generator_Option__c.SObjectType.getDescribe();
        Schema.DescribeSObjectResult ruleAccess = Seedforce_Recommendation_Rule__c.SObjectType.getDescribe();
        if (
            !generatorAccess.isCreateable() ||
            !generatorAccess.isUpdateable() ||
            !ruleAccess.isCreateable() ||
            !ruleAccess.isUpdateable()
        )
            throw new SeedforceException(
                'You need the Seedforce Administrator permission set to change configuration.'
            );
        if (deletedRuleIds != null && !deletedRuleIds.isEmpty() && !ruleAccess.isDeletable())
            throw new SeedforceException('You do not have permission to remove recommendation rules.');
    }

    private static Boolean matches(SeedforceDtos.RecommendationRule rule, Schema.DescribeFieldResult field) {
        String typeName = String.valueOf(field.getType()).toUpperCase();
        if (rule.fieldType != 'ANY' && rule.fieldType.toUpperCase() != typeName)
            return false;
        Integer length = field.getLength();
        if (rule.minimumLength != null && length < rule.minimumLength)
            return false;
        if (rule.maximumLength != null && length > rule.maximumLength)
            return false;
        if (String.isBlank(rule.fieldNamePattern))
            return true;
        String pattern = rule.fieldNamePattern.toLowerCase();
        String fieldName = field.getName().toLowerCase();
        Boolean startsWildcard = pattern.startsWith('*');
        Boolean endsWildcard = pattern.endsWith('*');
        pattern = pattern.replace('*', '');
        if (startsWildcard && endsWildcard)
            return fieldName.contains(pattern);
        if (startsWildcard)
            return fieldName.endsWith(pattern);
        if (endsWildcard)
            return fieldName.startsWith(pattern);
        return fieldName == pattern;
    }

    private static String compatibleFallback(Schema.DescribeFieldResult field, Set<String> activeKeys) {
        Map<Schema.DisplayType, String> fallbacks = new Map<Schema.DisplayType, String>{
            Schema.DisplayType.Boolean => 'BOOLEAN',
            Schema.DisplayType.Integer => 'INTEGER',
            Schema.DisplayType.Double => 'DECIMAL',
            Schema.DisplayType.Currency => 'DECIMAL',
            Schema.DisplayType.Percent => 'DECIMAL',
            Schema.DisplayType.Date => 'DATE',
            Schema.DisplayType.DateTime => 'DATETIME',
            Schema.DisplayType.Picklist => 'PICKLIST',
            Schema.DisplayType.MultiPicklist => 'MULTI_PICKLIST'
        };
        String candidate = fallbacks.get(field.getType());
        if (candidate != null && activeKeys.contains(candidate))
            return candidate;
        return activeKeys.contains('TEXT') ? 'TEXT' : null;
    }

    private static SeedforceDtos.RecommendationRule toDto(Seedforce_Recommendation_Rule__c stored) {
        SeedforceDtos.RecommendationRule rule = new SeedforceDtos.RecommendationRule();
        rule.id = stored.Id;
        rule.name = stored.Name;
        rule.active = stored.Active__c;
        rule.fieldType = stored.Field_Type__c;
        rule.fieldNamePattern = stored.Field_Name_Pattern__c;
        rule.generatorKey = stored.Generator_Key__c;
        rule.priority = stored.Priority__c == null ? 100 : stored.Priority__c.intValue();
        rule.minimumLength = stored.Minimum_Length__c == null ? null : stored.Minimum_Length__c.intValue();
        rule.maximumLength = stored.Maximum_Length__c == null ? null : stored.Maximum_Length__c.intValue();
        return rule;
    }

    private class GeneratorComparator implements Comparator<SeedforceDtos.GeneratorSetting> {
        public Integer compare(SeedforceDtos.GeneratorSetting left, SeedforceDtos.GeneratorSetting right) {
            return left.sortOrder - right.sortOrder;
        }
    }
}
