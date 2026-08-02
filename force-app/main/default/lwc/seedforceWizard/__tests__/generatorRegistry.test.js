import { createGeneratorRegistry } from '../generatorRegistry';

const faker = {
    location: {
        streetAddress: jest.fn(() => '123 Main Street'),
        city: jest.fn(() => 'Austin'),
        state: jest.fn(({ abbreviated } = {}) => (abbreviated ? 'TX' : 'Texas')),
        zipCode: jest.fn(() => '78701'),
        country: jest.fn(() => 'United States'),
        countryCode: jest.fn(() => 'US'),
        latitude: jest.fn(() => 30.267153),
        longitude: jest.fn(() => -97.743057),
    },
    helpers: { arrayElement: jest.fn((values) => values[0]) },
    number: { int: jest.fn(() => 7) },
    person: {
        prefix: jest.fn(() => 'Dr.'),
    },
    date: { birthdate: jest.fn(() => new Date('1990-04-15T00:00:00.000Z')) },
    lorem: {
        sentence: jest.fn(() => 'Short lorem sentence.'),
        paragraphs: jest.fn(() => 'A long lorem paragraph for a Salesforce textarea field.'),
    },
};

describe('Seedforce address generators', () => {
    const registry = createGeneratorRegistry();
    const field = { length: 255, scale: 3, picklistValues: [] };

    it.each([
        ['STREET_ADDRESS', '123 Main Street'],
        ['CITY', 'Austin'],
        ['STATE', 'Texas'],
        ['POSTAL_CODE', '78701'],
        ['COUNTRY', 'United States'],
        ['COUNTRY_CODE', 'US'],
        ['STATE_CODE', 'TX'],
        ['LATITUDE', 30.267],
        ['LONGITUDE', -97.743],
    ])('generates %s component data', (generatorId, expected) => {
        expect(registry.get(generatorId).generate({ faker, field })).toBe(expected);
    });

    it('rejects a locale whose country code is not active in Salesforce', () => {
        expect(() =>
            registry.get('PICKLIST').generate({
                faker,
                locale: 'es',
                field: { ...field, apiName: 'BillingCountryCode', picklistValues: ['CA', 'BR'] },
            }),
        ).toThrow('Country code ES is not active');
    });

    it.each([
        ['en', 'US'],
        ['es', 'ES'],
        ['pt_BR', 'BR'],
    ])('uses the locale country for a %s country-code picklist', (locale, expected) => {
        expect(
            registry.get('PICKLIST').generate({
                faker,
                locale,
                field: { ...field, apiName: 'BillingCountryCode', picklistValues: ['US', 'ES', 'BR'] },
            }),
        ).toBe(expected);
    });

    it('uses the same locale state dataset for a state-code picklist', () => {
        expect(
            registry.get('PICKLIST').generate({
                faker,
                locale: 'en',
                field: { ...field, apiName: 'BillingStateCode', picklistValues: ['TX', 'CA'] },
            }),
        ).toBe('CA');
    });

    it('generates bounded small integers', () => {
        expect(registry.get('SMALL_INTEGER').generate({ faker, field })).toBe(7);
        expect(faker.number.int).toHaveBeenCalledWith({ min: 0, max: 100 });
    });

    it('generates a Faker person prefix for Title fields', () => {
        expect(registry.get('PERSON_PREFIX').generate({ faker, field: { ...field, length: 40 } })).toBe('Dr.');
    });

    it('generates an adult birthday in Salesforce Date format', () => {
        expect(registry.get('BIRTHDAY').generate({ faker, field })).toBe('1990-04-15');
        expect(faker.date.birthdate).toHaveBeenCalledWith({ min: 18, max: 80, mode: 'age' });
    });

    it('generates length-safe lorem text for Description fields', () => {
        expect(registry.get('LOREM_TEXT').generate({ faker, field: { ...field, length: 10 } })).toBe('Short lore');
        expect(registry.get('LOREM_PARAGRAPH').generate({ faker, field: { ...field, length: 20 } })).toBe(
            'A long lorem paragra',
        );
    });
});
