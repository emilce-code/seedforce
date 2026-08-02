public inherited sharing class SeedforceGeneratorRecommendations {
    private static final Map<String, String> EXACT_RECOMMENDATIONS = new Map<String, String>{
        'ACCOUNT.NAME' => 'COMPANY_NAME',
        'CONTACT.FIRSTNAME' => 'FIRST_NAME',
        'CONTACT.LASTNAME' => 'LAST_NAME',
        'CONTACT.EMAIL' => 'EMAIL',
        'LEAD.COMPANY' => 'COMPANY_NAME'
    };

    public static String recommend(String objectName, Schema.DescribeFieldResult field) {
        String qualified = (objectName + '.' + field.getName()).toUpperCase();
        if (EXACT_RECOMMENDATIONS.containsKey(qualified))
            return EXACT_RECOMMENDATIONS.get(qualified);
        String name = field.getName().toLowerCase();
        Schema.DisplayType type = field.getType();
        // Picklist generators must use active Describe values. This takes precedence
        // over semantic address recommendations such as CountryCode and StateCode.
        if (type == Schema.DisplayType.Picklist)
            return 'PICKLIST';
        if (type == Schema.DisplayType.MultiPicklist)
            return 'MULTI_PICKLIST';
        if (name == 'title' || name.endsWith('title__c') || name.endsWith('title__s'))
            return 'PERSON_PREFIX';
        if (
            type == Schema.DisplayType.Date &&
            (name.contains('birthdate') ||
            name.contains('birthday') ||
            name == 'dob' ||
            name.endsWith('dob__c'))
        )
            return 'BIRTHDAY';
        if (name.contains('description') && type == Schema.DisplayType.TextArea)
            return field.getLength() > 255 ? 'LOREM_PARAGRAPH' : 'LOREM_TEXT';
        if (name.contains('email'))
            return 'EMAIL';
        if (name.contains('phone') || name.contains('mobile') || name.contains('fax'))
            return 'PHONE';
        if (name.contains('url') || name.contains('website'))
            return 'URL';
        if (name.contains('geocodeaccuracy') || name.endsWith('accuracy'))
            return 'PICKLIST';
        if (name.contains('countrycode'))
            return 'COUNTRY_CODE';
        if (name.contains('statecode'))
            return 'STATE_CODE';
        if (name.contains('postalcode') || name.contains('zipcode') || name.contains('zip'))
            return 'POSTAL_CODE';
        if (name.contains('latitude'))
            return 'LATITUDE';
        if (name.contains('longitude'))
            return 'LONGITUDE';
        if (name.contains('city'))
            return 'CITY';
        if (name.contains('country'))
            return 'COUNTRY';
        if (name.contains('state') || name.contains('province'))
            return 'STATE';
        if (name.contains('street'))
            return 'STREET_ADDRESS';
        if (type == Schema.DisplayType.Boolean)
            return 'BOOLEAN';
        if (type == Schema.DisplayType.Date)
            return 'DATE';
        if (type == Schema.DisplayType.DateTime)
            return 'DATETIME';
        if (type == Schema.DisplayType.Integer)
            return 'INTEGER';
        if (
            type == Schema.DisplayType.Double ||
            type == Schema.DisplayType.Currency ||
            type == Schema.DisplayType.Percent
        )
            return 'DECIMAL';
        return 'TEXT';
    }
}
