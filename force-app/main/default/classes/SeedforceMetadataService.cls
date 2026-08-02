public inherited sharing class SeedforceMetadataService {
    private static final Set<Schema.DisplayType> SUPPORTED_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.String,
        Schema.DisplayType.TextArea,
        Schema.DisplayType.Email,
        Schema.DisplayType.Phone,
        Schema.DisplayType.Url,
        Schema.DisplayType.Boolean,
        Schema.DisplayType.Integer,
        Schema.DisplayType.Double,
        Schema.DisplayType.Currency,
        Schema.DisplayType.Percent,
        Schema.DisplayType.Date,
        Schema.DisplayType.DateTime,
        Schema.DisplayType.Picklist,
        Schema.DisplayType.MultiPicklist
    };

    public virtual List<SeedforceDtos.ObjectOption> getSupportedObjects() {
        List<SeedforceDtos.ObjectOption> result = new List<SeedforceDtos.ObjectOption>();
        for (Schema.SObjectType typeToken : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult describe = typeToken.getDescribe();
            if (!isSupportedObject(describe))
                continue;
            SeedforceDtos.ObjectOption option = new SeedforceDtos.ObjectOption();
            option.apiName = describe.getName();
            option.label = describe.getLabel();
            result.add(option);
        }
        result.sort(new ObjectOptionComparator());
        return result;
    }

    public virtual SeedforceDtos.ObjectConfiguration getConfiguration(String objectApiName) {
        Schema.SObjectType typeToken = resolveType(objectApiName);
        Schema.DescribeSObjectResult objectDescribe = typeToken.getDescribe();
        if (!isSupportedObject(objectDescribe))
            throw new SeedforceException('This object is not supported for record generation.');
        SeedforceDtos.ObjectConfiguration configuration = new SeedforceDtos.ObjectConfiguration();
        configuration.apiName = objectDescribe.getName();
        configuration.label = objectDescribe.getLabel();
        configuration.fields = new List<SeedforceDtos.FieldOption>();
        configuration.blockers = new List<String>();
        SeedforceConfigurationService configurationService = new SeedforceConfigurationService();
        SeedforceDtos.SeedforceConfiguration runtimeConfiguration = configurationService.getConfiguration();
        Set<String> activeGeneratorKeys = new Set<String>();
        for (SeedforceDtos.GeneratorSetting setting : runtimeConfiguration.generators)
            if (setting.active)
                activeGeneratorKeys.add(setting.key);
        for (Schema.SObjectField token : objectDescribe.fields.getMap().values()) {
            Schema.DescribeFieldResult field = token.getDescribe();
            if (!field.isCreateable() || field.isCalculated() || field.isAutoNumber())
                continue;
            if (SUPPORTED_TYPES.contains(field.getType()))
                configuration.fields.add(
                    toOption(
                        field,
                        configurationService.recommend(
                            field,
                            SeedforceGeneratorRecommendations.recommend(objectDescribe.getName(), field),
                            runtimeConfiguration.rules,
                            activeGeneratorKeys
                        )
                    )
                );
            else if (!field.isNillable() && !field.isDefaultedOnCreate()) {
                configuration.blockers.add(
                    field.getLabel() +
                        ' (' +
                        field.getName() +
                        ') is required but its ' +
                        String.valueOf(field.getType()) +
                        ' type is not supported in the MVP.'
                );
            }
        }
        configuration.canGenerate = configuration.blockers.isEmpty();
        return configuration;
    }

    public virtual Schema.SObjectType resolveType(String objectApiName) {
        if (String.isBlank(objectApiName))
            throw new SeedforceException('Select an object.');
        Schema.SObjectType token = Schema.getGlobalDescribe().get(objectApiName);
        if (token == null)
            throw new SeedforceException('The selected object does not exist or is not accessible.');
        return token;
    }

    private static Boolean isSupportedObject(Schema.DescribeSObjectResult d) {
        String name = d.getName().toLowerCase();
        return d.isCreateable() &&
            !d.isDeprecatedAndHidden() &&
            !name.endsWith('__e') &&
            !name.endsWith('__mdt') &&
            !name.endsWith('__history') &&
            !name.endsWith('history') &&
            !name.endsWith('share') &&
            !name.endsWith('feed') &&
            !name.endsWith('changeevent');
    }

    private static SeedforceDtos.FieldOption toOption(Schema.DescribeFieldResult field, String recommendedGenerator) {
        SeedforceDtos.FieldOption option = new SeedforceDtos.FieldOption();
        option.apiName = field.getName();
        option.label = field.getLabel();
        option.dataType = String.valueOf(field.getType());
        option.required = !field.isNillable() && !field.isDefaultedOnCreate();
        option.length = field.getLength();
        option.precision = field.getPrecision();
        option.scale = field.getScale();
        option.picklistValues = new List<String>();
        for (Schema.PicklistEntry entry : field.getPicklistValues())
            if (entry.isActive())
                option.picklistValues.add(entry.getValue());
        option.recommendedGenerator = recommendedGenerator;
        return option;
    }

    private class ObjectOptionComparator implements Comparator<SeedforceDtos.ObjectOption> {
        public Integer compare(SeedforceDtos.ObjectOption left, SeedforceDtos.ObjectOption right) {
            return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        }
    }
}
