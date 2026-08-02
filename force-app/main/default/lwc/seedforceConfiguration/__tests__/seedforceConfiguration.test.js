import { createElement } from 'lwc';
import SeedforceConfiguration from 'c/seedforceConfiguration';
import getConfiguration from '@salesforce/apex/SeedforceConfigurationController.getConfiguration';
import saveConfiguration from '@salesforce/apex/SeedforceConfigurationController.saveConfiguration';

jest.mock('@salesforce/apex/SeedforceConfigurationController.getConfiguration', () => ({ default: jest.fn() }), {
    virtual: true,
});
jest.mock('@salesforce/apex/SeedforceConfigurationController.saveConfiguration', () => ({ default: jest.fn() }), {
    virtual: true,
});

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const configuration = {
    generators: [{ id: null, key: 'TEXT', label: 'Words', active: true, sortOrder: 10 }],
    rules: [],
};

describe('c-seedforce-configuration', () => {
    beforeEach(() => {
        getConfiguration.mockResolvedValue(configuration);
        saveConfiguration.mockResolvedValue(configuration);
    });
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
        jest.clearAllMocks();
    });

    it('loads the generator catalog and adds recommendation rules', async () => {
        const element = createElement('c-seedforce-configuration', { is: SeedforceConfiguration });
        document.body.appendChild(element);
        await flush();
        expect(element.shadowRoot.querySelector('code').textContent).toBe('TEXT');
        [...element.shadowRoot.querySelectorAll('lightning-button')].find((item) => item.label === 'Add Rule').click();
        await flush();
        expect(element.shadowRoot.querySelectorAll('lightning-button-icon')).toHaveLength(1);
    });

    it('saves generator activation changes', async () => {
        const element = createElement('c-seedforce-configuration', { is: SeedforceConfiguration });
        document.body.appendChild(element);
        await flush();
        const active = [...element.shadowRoot.querySelectorAll('lightning-input')].find(
            (item) => item.label === 'Active',
        );
        active.checked = false;
        active.dispatchEvent(new CustomEvent('change'));
        await flush();
        [...element.shadowRoot.querySelectorAll('lightning-button')]
            .find((item) => item.label === 'Save Configuration')
            .click();
        await flush();
        expect(saveConfiguration).toHaveBeenCalledWith({
            request: expect.objectContaining({ generators: [expect.objectContaining({ key: 'TEXT', active: false })] }),
        });
    });
});
