public inherited sharing class SeedforceApplicationService {
    private final SeedforceMetadataService metadataService;
    private final SeedforceGenerationService generationService;

    public SeedforceApplicationService() {
        metadataService = new SeedforceMetadataService();
        generationService = new SeedforceGenerationService();
    }

    public List<SeedforceDtos.ObjectOption> listObjects() {
        return metadataService.getSupportedObjects();
    }
    public SeedforceDtos.ObjectConfiguration describeObject(String objectApiName) {
        return metadataService.getConfiguration(objectApiName);
    }
    public SeedforceDtos.GenerationResult generate(SeedforceDtos.GenerationRequest request) {
        return generationService.generate(request);
    }
}
