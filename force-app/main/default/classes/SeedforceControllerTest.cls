@IsTest
private class SeedforceControllerTest {
    @IsTest
    static void controllerReturnsMetadata() {
        Test.startTest();
        List<SeedforceDtos.ObjectOption> objects = SeedforceController.getSupportedObjects();
        SeedforceDtos.ObjectConfiguration config = SeedforceController.getObjectConfiguration('Account');
        Test.stopTest();
        System.assert(!objects.isEmpty());
        System.assertEquals('Account', config.apiName);
    }

    @IsTest
    static void controllerNormalizesErrors() {
        try {
            SeedforceController.getObjectConfiguration('Nope__c');
            System.assert(false, 'Expected handled error.');
        } catch (AuraHandledException error) {
            System.assert(error.getMessage().contains('does not exist'));
        }
    }
}
