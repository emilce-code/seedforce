public inherited sharing class SeedforceDtos {
    public class ObjectOption {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
    }

    public class FieldOption {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String dataType { get; set; }
        @AuraEnabled
        public Boolean required { get; set; }
        @AuraEnabled
        public Integer length { get; set; }
        @AuraEnabled
        public Integer precision { get; set; }
        @AuraEnabled
        public Integer scale { get; set; }
        @AuraEnabled
        public List<String> picklistValues { get; set; }
        @AuraEnabled
        public String recommendedGenerator { get; set; }
    }

    public class ObjectConfiguration {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public List<FieldOption> fields { get; set; }
        @AuraEnabled
        public List<String> blockers { get; set; }
        @AuraEnabled
        public Boolean canGenerate { get; set; }
    }

    public class GenerationRequest {
        @AuraEnabled
        public String objectApiName { get; set; }
        @AuraEnabled
        public Integer recordCount { get; set; }
        @AuraEnabled
        public List<Map<String, Object>> records { get; set; }
    }

    public class RowResult {
        @AuraEnabled
        public Integer rowNumber { get; set; }
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String recordId { get; set; }
        @AuraEnabled
        public List<String> messages { get; set; }
    }

    public class GenerationResult {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public Integer requested { get; set; }
        @AuraEnabled
        public Integer inserted { get; set; }
        @AuraEnabled
        public Integer failed { get; set; }
        @AuraEnabled
        public List<RowResult> rows { get; set; }
        @AuraEnabled
        public List<String> messages { get; set; }
    }

    public class GeneratorSetting {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String key { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public Boolean active { get; set; }
        @AuraEnabled
        public Integer sortOrder { get; set; }
    }

    public class RecommendationRule {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Boolean active { get; set; }
        @AuraEnabled
        public String fieldType { get; set; }
        @AuraEnabled
        public String fieldNamePattern { get; set; }
        @AuraEnabled
        public String generatorKey { get; set; }
        @AuraEnabled
        public Integer priority { get; set; }
        @AuraEnabled
        public Integer minimumLength { get; set; }
        @AuraEnabled
        public Integer maximumLength { get; set; }
    }

    public class SeedforceConfiguration {
        @AuraEnabled
        public List<GeneratorSetting> generators { get; set; }
        @AuraEnabled
        public List<RecommendationRule> rules { get; set; }
    }

    public class ConfigurationSaveRequest {
        @AuraEnabled
        public List<GeneratorSetting> generators { get; set; }
        @AuraEnabled
        public List<RecommendationRule> rules { get; set; }
        @AuraEnabled
        public List<String> deletedRuleIds { get; set; }
    }
}
