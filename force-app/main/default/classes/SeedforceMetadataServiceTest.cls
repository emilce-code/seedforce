@IsTest
private class SeedforceMetadataServiceTest {
    @IsTest
    static void listsOnlyCreateableObjectsAndDescribesSupportedFields() {
        Test.startTest();
        List<SeedforceDtos.ObjectOption> objects = new SeedforceMetadataService().getSupportedObjects();
        SeedforceDtos.ObjectConfiguration configuration = new SeedforceMetadataService().getConfiguration('Account');
        Test.stopTest();
        System.assert(!objects.isEmpty(), 'At least one createable object should be available.');
        System.assertEquals('Account', configuration.apiName);
        System.assert(configuration.canGenerate);
        Boolean foundName = false;
        for (SeedforceDtos.FieldOption field : configuration.fields) {
            if (field.apiName == 'Name') {
                foundName = true;
                System.assertEquals('COMPANY_NAME', field.recommendedGenerator);
                System.assert(field.required);
            }
            System.assertNotEquals('REFERENCE', field.dataType);
        }
        System.assert(foundName, 'Account Name must be configurable.');
    }

    @IsTest
    static void rejectsUnknownObject() {
        try {
            new SeedforceMetadataService().getConfiguration('NotARealObject__c');
            System.assert(false, 'Expected a domain exception.');
        } catch (SeedforceException error) {
            System.assert(error.getMessage().contains('does not exist'));
        }
    }

    @IsTest
    static void recommendsGeneratorsForCompoundAddressComponents() {
        SeedforceDtos.ObjectConfiguration configuration = new SeedforceMetadataService().getConfiguration('Contact');
        Map<String, String> recommendations = new Map<String, String>();
        for (SeedforceDtos.FieldOption field : configuration.fields) {
            recommendations.put(field.apiName, field.recommendedGenerator);
        }

        System.assertEquals('STREET_ADDRESS', recommendations.get('MailingStreet'));
        System.assertEquals('CITY', recommendations.get('MailingCity'));
        System.assertEquals('STATE', recommendations.get('MailingState'));
        System.assertEquals('POSTAL_CODE', recommendations.get('MailingPostalCode'));
        System.assertEquals('COUNTRY', recommendations.get('MailingCountry'));
        System.assertEquals('LATITUDE', recommendations.get('MailingLatitude'));
        System.assertEquals('LONGITUDE', recommendations.get('MailingLongitude'));
        System.assertEquals('PICKLIST', recommendations.get('MailingGeocodeAccuracy'));

        if (recommendations.containsKey('MailingCountryCode'))
            System.assertEquals('PICKLIST', recommendations.get('MailingCountryCode'));
        if (recommendations.containsKey('MailingStateCode'))
            System.assertEquals('PICKLIST', recommendations.get('MailingStateCode'));
    }

    @IsTest
    static void recommendsPrefixAndLengthAwareDescriptionGenerators() {
        SeedforceDtos.ObjectConfiguration contactConfiguration = new SeedforceMetadataService()
            .getConfiguration('Contact');
        SeedforceDtos.ObjectConfiguration caseConfiguration = new SeedforceMetadataService().getConfiguration('Case');
        Map<String, String> recommendations = new Map<String, String>();
        for (SeedforceDtos.FieldOption field : contactConfiguration.fields)
            recommendations.put('Contact.' + field.apiName, field.recommendedGenerator);
        for (SeedforceDtos.FieldOption field : caseConfiguration.fields)
            recommendations.put('Case.' + field.apiName, field.recommendedGenerator);

        System.assertEquals('PERSON_PREFIX', recommendations.get('Contact.Title'));
        System.assertEquals('BIRTHDAY', recommendations.get('Contact.Birthdate'));
        System.assertEquals('LOREM_PARAGRAPH', recommendations.get('Case.Description'));
    }
}
