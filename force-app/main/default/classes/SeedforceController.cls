public with sharing class SeedforceController {
    @AuraEnabled(cacheable=true)
    public static List<SeedforceDtos.ObjectOption> getSupportedObjects() {
        try {
            return new SeedforceApplicationService().listObjects();
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    @AuraEnabled(cacheable=true)
    public static SeedforceDtos.ObjectConfiguration getObjectConfiguration(String objectApiName) {
        try {
            return new SeedforceApplicationService().describeObject(objectApiName);
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    @AuraEnabled(cacheable=true)
    public static SeedforceDtos.SeedforceConfiguration getGeneratorConfiguration() {
        try {
            return new SeedforceConfigurationService().getConfiguration();
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    @AuraEnabled
    public static SeedforceDtos.GenerationResult generateRecords(SeedforceDtos.GenerationRequest request) {
        try {
            return new SeedforceApplicationService().generate(request);
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    private static AuraHandledException normalized(Exception error) {
        String message = error instanceof SeedforceException
            ? error.getMessage()
            : 'Seedforce could not complete the request. Contact your Salesforce administrator.';
        AuraHandledException handled = new AuraHandledException(message);
        handled.setMessage(message);
        return handled;
    }
}
