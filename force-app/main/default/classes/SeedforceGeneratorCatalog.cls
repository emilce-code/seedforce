public inherited sharing class SeedforceGeneratorCatalog {
    private static final List<List<String>> DEFINITIONS = new List<List<String>>{
        new List<String>{ 'TEXT', 'Words' },
        new List<String>{ 'COMPANY_NAME', 'Company name' },
        new List<String>{ 'FIRST_NAME', 'First name' },
        new List<String>{ 'LAST_NAME', 'Last name' },
        new List<String>{ 'PERSON_PREFIX', 'Person prefix' },
        new List<String>{ 'EMAIL', 'Email' },
        new List<String>{ 'PHONE', 'Phone' },
        new List<String>{ 'URL', 'URL' },
        new List<String>{ 'CITY', 'City' },
        new List<String>{ 'COUNTRY', 'Country' },
        new List<String>{ 'STATE', 'State / province' },
        new List<String>{ 'POSTAL_CODE', 'Postal code' },
        new List<String>{ 'COUNTRY_CODE', 'Country code' },
        new List<String>{ 'STATE_CODE', 'State / province code' },
        new List<String>{ 'STREET_ADDRESS', 'Street address' },
        new List<String>{ 'LATITUDE', 'Latitude' },
        new List<String>{ 'LONGITUDE', 'Longitude' },
        new List<String>{ 'BOOLEAN', 'Boolean' },
        new List<String>{ 'LOREM_TEXT', 'Lorem text' },
        new List<String>{ 'LOREM_PARAGRAPH', 'Lorem paragraph' },
        new List<String>{ 'INTEGER', 'Integer' },
        new List<String>{ 'SMALL_INTEGER', 'Small integer (0–100)' },
        new List<String>{ 'DECIMAL', 'Decimal' },
        new List<String>{ 'DATE', 'Recent date' },
        new List<String>{ 'BIRTHDAY', 'Birthday' },
        new List<String>{ 'DATETIME', 'Recent date/time' },
        new List<String>{ 'PICKLIST', 'Picklist value' },
        new List<String>{ 'MULTI_PICKLIST', 'Multi-picklist values' }
    };

    public static List<SeedforceDtos.GeneratorSetting> defaults() {
        List<SeedforceDtos.GeneratorSetting> result = new List<SeedforceDtos.GeneratorSetting>();
        Integer position = 10;
        for (List<String> definition : DEFINITIONS) {
            SeedforceDtos.GeneratorSetting setting = new SeedforceDtos.GeneratorSetting();
            setting.key = definition[0];
            setting.label = definition[1];
            setting.active = true;
            setting.sortOrder = position;
            result.add(setting);
            position += 10;
        }
        return result;
    }

    public static Set<String> keys() {
        Set<String> result = new Set<String>();
        for (List<String> definition : DEFINITIONS)
            result.add(definition[0]);
        return result;
    }
}
