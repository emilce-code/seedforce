@IsTest
private class SeedforceGenerationServiceTest {
    @IsTest
    static void insertsValidRowsAndReturnsValidationErrorsPerRow() {
        SeedforceDtos.GenerationRequest request = new SeedforceDtos.GenerationRequest();
        request.objectApiName = 'Account';
        request.recordCount = 2;
        request.records = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Name' => 'Seedforce Alpha', 'NumberOfEmployees' => 42 },
            new Map<String, Object>{ 'Name' => '' }
        };
        Test.startTest();
        SeedforceDtos.GenerationResult result = new SeedforceGenerationService().generate(request);
        Test.stopTest();
        System.assertEquals(2, result.requested);
        System.assertEquals(1, result.inserted);
        System.assertEquals(1, result.failed);
        System.assertEquals(false, result.success);
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Name = 'Seedforce Alpha']);
    }

    @IsTest
    static void validatesCountAndFieldNames() {
        SeedforceDtos.GenerationRequest badCount = new SeedforceDtos.GenerationRequest();
        badCount.objectApiName = 'Account';
        badCount.recordCount = 201;
        badCount.records = new List<Map<String, Object>>();
        try {
            new SeedforceGenerationService().generate(badCount);
            System.assert(false, 'Expected count validation.');
        } catch (SeedforceException error) {
            System.assert(error.getMessage().contains('between 1 and 200'));
        }

        SeedforceDtos.GenerationRequest unknownField = new SeedforceDtos.GenerationRequest();
        unknownField.objectApiName = 'Account';
        unknownField.recordCount = 1;
        unknownField.records = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Name' => 'Safe', 'Bogus__c' => 'x' }
        };
        SeedforceDtos.GenerationResult result = new SeedforceGenerationService().generate(unknownField);
        System.assertEquals(0, result.inserted);
        System.assertEquals(1, result.failed);
        System.assert(result.rows[0].messages[0].contains('Unknown field'));
    }

    @IsTest
    static void validatesPicklistsAndLengths() {
        SeedforceDtos.GenerationRequest request = new SeedforceDtos.GenerationRequest();
        request.objectApiName = 'Account';
        request.recordCount = 1;
        request.records = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Name' => 'Safe', 'Type' => 'Definitely invalid' }
        };
        SeedforceDtos.GenerationResult result = new SeedforceGenerationService().generate(request);
        System.assertEquals(1, result.failed);
        System.assert(result.rows[0].messages[0].contains('invalid'));
    }

    @IsTest
    static void codeComponentsMakeAddressTextComponentsDerived() {
        Set<String> derivedFields = SeedforceValidationService.getDerivedAddressFields(
            new Map<String, Object>{
                'BillingCountry' => 'Brazil',
                'BillingCountryCode' => 'US',
                'BillingState' => 'São Paulo',
                'BillingStateCode' => 'CA'
            }
        );

        System.assertEquals(new Set<String>{ 'BillingCountry', 'BillingState' }, derivedFields);
    }
}
