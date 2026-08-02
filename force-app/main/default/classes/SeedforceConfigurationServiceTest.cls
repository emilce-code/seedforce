@IsTest
private class SeedforceConfigurationServiceTest {
    @IsTest
    static void defaultsCatalogAndAppliesStoredOverrides() {
        insert new Seedforce_Generator_Option__c(
            Name = 'EMAIL',
            Generator_Key__c = 'EMAIL',
            Active__c = false,
            Display_Label__c = 'Disabled email',
            Sort_Order__c = 1
        );
        SeedforceDtos.SeedforceConfiguration configuration = new SeedforceConfigurationService().getConfiguration();
        System.assertEquals(28, configuration.generators.size());
        System.assertEquals('EMAIL', configuration.generators[0].key);
        System.assertEquals(false, configuration.generators[0].active);
        System.assertEquals('Disabled email', configuration.generators[0].label);
    }

    @IsTest
    static void prioritizedRuleOverridesBuiltInRecommendation() {
        insert new Seedforce_Recommendation_Rule__c(
            Name = 'All strings use words',
            Active__c = true,
            Field_Type__c = 'STRING',
            Field_Name_Pattern__c = 'Title',
            Generator_Key__c = 'TEXT',
            Priority__c = 1
        );
        SeedforceDtos.ObjectConfiguration configuration = new SeedforceMetadataService().getConfiguration('Contact');
        for (SeedforceDtos.FieldOption field : configuration.fields)
            if (field.apiName == 'Title')
                System.assertEquals('TEXT', field.recommendedGenerator);
    }

    @IsTest
    static void savesValidatedConfiguration() {
        SeedforceDtos.ConfigurationSaveRequest request = new SeedforceDtos.ConfigurationSaveRequest();
        request.generators = SeedforceGeneratorCatalog.defaults();
        request.rules = new List<SeedforceDtos.RecommendationRule>();
        request.deletedRuleIds = new List<String>();
        request.generators[0].active = false;
        Test.startTest();
        SeedforceDtos.SeedforceConfiguration saved = SeedforceConfigurationController.saveConfiguration(request);
        Test.stopTest();
        System.assertEquals(28, [SELECT COUNT() FROM Seedforce_Generator_Option__c]);
        System.assertEquals(false, saved.generators[0].active);
    }
}
