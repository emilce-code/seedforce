public with sharing class SeedforceConfigurationController {
    @AuraEnabled(cacheable=true)
    public static SeedforceDtos.SeedforceConfiguration getConfiguration() {
        try {
            return new SeedforceConfigurationService().getConfiguration();
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    @AuraEnabled
    public static SeedforceDtos.SeedforceConfiguration saveConfiguration(
        SeedforceDtos.ConfigurationSaveRequest request
    ) {
        try {
            return new SeedforceConfigurationService().save(request);
        } catch (Exception error) {
            throw normalized(error);
        }
    }

    private static AuraHandledException normalized(Exception error) {
        String message = error instanceof SeedforceException
            ? error.getMessage()
            : 'Seedforce could not save the configuration.';
        AuraHandledException handled = new AuraHandledException(message);
        handled.setMessage(message);
        return handled;
    }
}
