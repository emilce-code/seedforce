import { Faker, base, en, es, pt_BR } from '@faker-js/faker';

const locales = { en, es, pt_BR };
const create = (locale = 'en') => {
    const selectedLocale = locales[locale] || en;
    return new Faker({ locale: selectedLocale === en ? [en, base] : [selectedLocale, en, base] });
};

// Static-resource scripts execute outside the LWC module graph. Assigning the API
// explicitly is reliable under Lightning Web Security; an IIFE `var` declaration is not.
window.SeedforceFaker = Object.freeze({ create });
