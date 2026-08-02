class GeneratorRegistry {
    strategies = new Map();
    register(strategy) {
        if (!strategy?.id || typeof strategy.generate !== 'function')
            throw new Error('A generator must expose an id and generate(context).');
        this.strategies.set(strategy.id, strategy);
        return this;
    }
    get(id) {
        const strategy = this.strategies.get(id);
        if (!strategy) throw new Error(`Generator ${id} is not registered.`);
        return strategy;
    }
    has(id) {
        return this.strategies.has(id);
    }
    options() {
        return [...this.strategies.values()].map(({ id, label }) => ({
            label,
            value: id,
        }));
    }
}

const strategy = (id, label, generate) => Object.freeze({ id, label, generate });
const truncate = (value, field) => String(value).slice(0, field.length || 255);
const LOCALE_COUNTRY_CODES = Object.freeze({ en: 'US', es: 'ES', pt_BR: 'BR' });
const LOCALE_STATE_CODES = Object.freeze({
    en: ['CA', 'NY', 'TX', 'FL', 'WA'],
    es: ['M', 'B', 'V', 'SE', 'Z'],
    pt_BR: ['SP', 'RJ', 'MG', 'PR', 'RS'],
});
const constrainedPicklist = (candidate, faker, field) => {
    if (!field.picklistValues?.length || field.picklistValues.includes(candidate)) return candidate;
    return faker.helpers.arrayElement(field.picklistValues);
};
const coordinate = (value, field) => Number(value.toFixed(Math.min(field.scale ?? 6, 10)));
const picklistValue = ({ faker, field, locale }) => {
    const fieldName = field.apiName.toLowerCase();
    if (fieldName.includes('countrycode')) {
        const countryCode = LOCALE_COUNTRY_CODES[locale] || LOCALE_COUNTRY_CODES.en;
        if (field.picklistValues.includes(countryCode)) return countryCode;
        throw new Error(`Country code ${countryCode} is not active for the selected Faker locale.`);
    }
    if (fieldName.includes('statecode')) {
        const preferredCodes = LOCALE_STATE_CODES[locale] || LOCALE_STATE_CODES.en;
        const activeCodes = preferredCodes.filter((code) => field.picklistValues.includes(code));
        if (activeCodes.length) return faker.helpers.arrayElement(activeCodes);
        throw new Error(`No state codes for ${LOCALE_COUNTRY_CODES[locale] || LOCALE_COUNTRY_CODES.en} are active.`);
    }
    return faker.helpers.arrayElement(field.picklistValues);
};

export function createGeneratorRegistry() {
    return new GeneratorRegistry()
        .register(strategy('TEXT', 'Words', ({ faker, field }) => truncate(faker.lorem.words(3), field)))
        .register(strategy('COMPANY_NAME', 'Company name', ({ faker, field }) => truncate(faker.company.name(), field)))
        .register(strategy('FIRST_NAME', 'First name', ({ faker, field }) => truncate(faker.person.firstName(), field)))
        .register(strategy('LAST_NAME', 'Last name', ({ faker, field }) => truncate(faker.person.lastName(), field)))
        .register(
            strategy('PERSON_PREFIX', 'Person prefix', ({ faker, field }) => truncate(faker.person.prefix(), field)),
        )
        .register(strategy('EMAIL', 'Email', ({ faker, field }) => truncate(faker.internet.email(), field)))
        .register(strategy('PHONE', 'Phone', ({ faker, field }) => truncate(faker.phone.number(), field)))
        .register(strategy('URL', 'URL', ({ faker, field }) => truncate(faker.internet.url(), field)))
        .register(strategy('CITY', 'City', ({ faker, field }) => truncate(faker.location.city(), field)))
        .register(strategy('COUNTRY', 'Country', ({ faker, field }) => truncate(faker.location.country(), field)))
        .register(strategy('STATE', 'State / province', ({ faker, field }) => truncate(faker.location.state(), field)))
        .register(
            strategy('POSTAL_CODE', 'Postal code', ({ faker, field }) => truncate(faker.location.zipCode(), field)),
        )
        .register(
            strategy('COUNTRY_CODE', 'Country code', ({ faker, field }) =>
                constrainedPicklist(faker.location.countryCode('alpha-2'), faker, field),
            ),
        )
        .register(
            strategy('STATE_CODE', 'State / province code', ({ faker, field }) =>
                constrainedPicklist(faker.location.state({ abbreviated: true }), faker, field),
            ),
        )
        .register(
            strategy('STREET_ADDRESS', 'Street address', ({ faker, field }) =>
                truncate(faker.location.streetAddress(), field),
            ),
        )
        .register(strategy('LATITUDE', 'Latitude', ({ faker, field }) => coordinate(faker.location.latitude(), field)))
        .register(
            strategy('LONGITUDE', 'Longitude', ({ faker, field }) => coordinate(faker.location.longitude(), field)),
        )
        .register(strategy('BOOLEAN', 'Boolean', ({ faker }) => faker.datatype.boolean()))
        .register(strategy('LOREM_TEXT', 'Lorem text', ({ faker, field }) => truncate(faker.lorem.sentence(), field)))
        .register(
            strategy('LOREM_PARAGRAPH', 'Lorem paragraph', ({ faker, field }) =>
                truncate(
                    faker.lorem.paragraphs(Math.max(1, Math.min(5, Math.ceil((field.length || 255) / 500)))),
                    field,
                ),
            ),
        )
        .register(strategy('INTEGER', 'Integer', ({ faker }) => faker.number.int({ min: 0, max: 10000 })))
        .register(
            strategy('SMALL_INTEGER', 'Small integer (0–100)', ({ faker }) => faker.number.int({ min: 0, max: 100 })),
        )
        .register(
            strategy('DECIMAL', 'Decimal', ({ faker, field }) =>
                faker.number.float({
                    min: 0,
                    max: 10000,
                    fractionDigits: Math.min(field.scale || 0, 6),
                }),
            ),
        )
        .register(
            strategy('DATE', 'Recent date', ({ faker }) => faker.date.recent({ days: 365 }).toISOString().slice(0, 10)),
        )
        .register(
            strategy('BIRTHDAY', 'Birthday', ({ faker }) =>
                faker.date.birthdate({ min: 18, max: 80, mode: 'age' }).toISOString().slice(0, 10),
            ),
        )
        .register(
            strategy('DATETIME', 'Recent date/time', ({ faker }) => faker.date.recent({ days: 365 }).toISOString()),
        )
        .register(strategy('PICKLIST', 'Picklist value', (context) => picklistValue(context)))
        .register(
            strategy('MULTI_PICKLIST', 'Multi-picklist values', ({ faker, field }) =>
                faker.helpers
                    .arrayElements(field.picklistValues, {
                        min: 1,
                        max: Math.min(2, field.picklistValues.length),
                    })
                    .join(';'),
            ),
        );
}
