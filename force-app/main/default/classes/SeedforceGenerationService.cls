public inherited sharing class SeedforceGenerationService {
    private final SeedforceMetadataService metadataService;
    private final SeedforceValidationService validationService;

    public SeedforceGenerationService() {
        this(new SeedforceMetadataService(), new SeedforceValidationService());
    }

    @TestVisible
    private SeedforceGenerationService(
        SeedforceMetadataService metadataService,
        SeedforceValidationService validationService
    ) {
        this.metadataService = metadataService;
        this.validationService = validationService;
    }

    public SeedforceDtos.GenerationResult generate(SeedforceDtos.GenerationRequest request) {
        Schema.SObjectType typeToken = metadataService.resolveType(request == null ? null : request.objectApiName);
        SeedforceValidationService.ValidationOutcome validation = validationService.validate(request, typeToken);
        SeedforceDtos.GenerationResult result = initializeResult(request.recordCount);
        for (Integer rowNumber : validation.rowErrors.keySet())
            result.rows.add(rowResult(rowNumber, false, null, validation.rowErrors.get(rowNumber)));
        if (!validation.validRecords.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(validation.validRecords, false);
            for (Integer index = 0; index < saveResults.size(); index++) {
                Database.SaveResult saveResult = saveResults[index];
                List<String> messages = new List<String>();
                if (!saveResult.isSuccess())
                    for (Database.Error error : saveResult.getErrors())
                        messages.add(error.getMessage());
                result.rows.add(
                    rowResult(
                        validation.sourceRows[index],
                        saveResult.isSuccess(),
                        saveResult.isSuccess() ? saveResult.getId() : null,
                        messages
                    )
                );
            }
        }
        for (SeedforceDtos.RowResult row : result.rows) {
            if (row.success)
                result.inserted++;
            else
                result.failed++;
        }
        result.success = result.failed == 0;
        if (result.failed > 0)
            result.messages.add(result.failed + ' record(s) could not be inserted. Review the row results.');
        return result;
    }

    private static SeedforceDtos.GenerationResult initializeResult(Integer requested) {
        SeedforceDtos.GenerationResult result = new SeedforceDtos.GenerationResult();
        result.success = false;
        result.requested = requested;
        result.inserted = 0;
        result.failed = 0;
        result.rows = new List<SeedforceDtos.RowResult>();
        result.messages = new List<String>();
        return result;
    }

    private static SeedforceDtos.RowResult rowResult(
        Integer zeroBasedRow,
        Boolean success,
        Id recordId,
        List<String> messages
    ) {
        SeedforceDtos.RowResult row = new SeedforceDtos.RowResult();
        row.rowNumber = zeroBasedRow + 1;
        row.success = success;
        row.recordId = recordId;
        row.messages = messages;
        return row;
    }
}
