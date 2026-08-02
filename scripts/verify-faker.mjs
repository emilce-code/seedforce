import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const source = await readFile('force-app/main/default/staticresources/seedforceFaker.js', 'utf8');
const browserWindow = {};
const context = vm.createContext({ window: browserWindow });
vm.runInContext(source, context);

if (typeof browserWindow.SeedforceFaker?.create !== 'function') {
    throw new Error('The static resource did not export SeedforceFaker.create() on window.');
}

for (const locale of ['en', 'es', 'pt_BR']) {
    const faker = browserWindow.SeedforceFaker.create(locale);
    const values = [
        faker.location.streetAddress(),
        faker.location.city(),
        faker.location.state(),
        faker.location.state({ abbreviated: true }),
        faker.location.zipCode(),
        faker.location.country(),
        faker.location.countryCode('alpha-2'),
        faker.location.latitude(),
        faker.location.longitude(),
        faker.date.birthdate({ min: 18, max: 80, mode: 'age' }).toISOString().slice(0, 10),
    ];
    if (values.some((value) => value === null || value === undefined || value === '')) {
        throw new Error(`Faker returned an empty address component for ${locale}.`);
    }
}

console.log('Faker static resource passed address generation for en, es, and pt_BR.');
