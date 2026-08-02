import { createElement } from 'lwc';
import SeedforceWizard from 'c/seedforceWizard';
import getSupportedObjects from '@salesforce/apex/SeedforceController.getSupportedObjects';
import getObjectConfiguration from '@salesforce/apex/SeedforceController.getObjectConfiguration';
import getGeneratorConfiguration from '@salesforce/apex/SeedforceController.getGeneratorConfiguration';
import generateRecords from '@salesforce/apex/SeedforceController.generateRecords';

jest.mock(
    '@salesforce/apex/SeedforceController.getSupportedObjects',
    () => {
        const { createApexTestWireAdapter } = jest.requireActual('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true },
);
jest.mock('@salesforce/apex/SeedforceController.getObjectConfiguration', () => ({ default: jest.fn() }), {
    virtual: true,
});
jest.mock(
    '@salesforce/apex/SeedforceController.getGeneratorConfiguration',
    () => {
        const { createApexTestWireAdapter } = jest.requireActual('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true },
);
jest.mock('@salesforce/apex/SeedforceController.generateRecords', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('lightning/platformResourceLoader', () => ({ loadScript: jest.fn(() => Promise.resolve()) }), {
    virtual: true,
});

// Jest's Apex wire adapter and LWC render queue settle on the next task.
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const button = (element, label) =>
    [...element.shadowRoot.querySelectorAll('lightning-button')].find((item) => item.label === label);
const selectObject = async (element, apiName = 'Account') => {
    getSupportedObjects.emit([{ apiName: 'Account', label: 'Account' }]);
    getGeneratorConfiguration.emit({
        generators: [
            { key: 'COMPANY_NAME', label: 'Company name', active: true, sortOrder: 10 },
            { key: 'PHONE', label: 'Phone', active: true, sortOrder: 20 },
            { key: 'COUNTRY', label: 'Country', active: true, sortOrder: 30 },
            { key: 'PICKLIST', label: 'Picklist value', active: true, sortOrder: 40 },
        ],
        rules: [],
    });
    await flush();
    const lookup = [...element.shadowRoot.querySelectorAll('lightning-input')].find(
        (item) => item.label === 'Salesforce object',
    );
    lookup.dispatchEvent(new CustomEvent('focus'));
    await flush();
    element.shadowRoot.querySelector(`button[data-value="${apiName}"]`).click();
    await flush();
};
const config = {
    apiName: 'Account',
    label: 'Account',
    blockers: [],
    canGenerate: true,
    fields: [
        {
            apiName: 'Name',
            label: 'Account Name',
            dataType: 'STRING',
            required: true,
            length: 80,
            scale: 0,
            picklistValues: [],
            recommendedGenerator: 'COMPANY_NAME',
        },
    ],
};

describe('c-seedforce-wizard', () => {
    beforeEach(() => {
        window.SeedforceFaker = {
            create: () => ({ company: { name: () => 'Acme' } }),
        };
        getObjectConfiguration.mockResolvedValue(config);
        generateRecords.mockResolvedValue({
            success: true,
            requested: 1,
            inserted: 1,
            failed: 0,
            rows: [{ rowNumber: 1, success: true, recordId: '001xx', messages: [] }],
        });
    });
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
        jest.clearAllMocks();
    });

    it('loads object metadata and advances to field configuration', async () => {
        const element = createElement('c-seedforce-wizard', {
            is: SeedforceWizard,
        });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        expect(getObjectConfiguration).toHaveBeenCalledWith({
            objectApiName: 'Account',
        });
        expect(element.shadowRoot.querySelector('table')).not.toBeNull();
    });

    it('generates preview rows with the loaded Faker resource', async () => {
        const element = createElement('c-seedforce-wizard', { is: SeedforceWizard });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        button(element, 'Preview Records').click();
        await flush();

        const preview = element.shadowRoot.querySelector('lightning-datatable');
        expect(preview).not.toBeNull();
        expect(preview.data).toHaveLength(10);
        expect(preview.data[0].Name).toBe('Acme');
    });

    it('normalizes generator failures into a preview toast', async () => {
        getObjectConfiguration.mockResolvedValueOnce({
            ...config,
            fields: [{ ...config.fields[0], recommendedGenerator: 'NOT_REGISTERED' }],
        });
        const element = createElement('c-seedforce-wizard', { is: SeedforceWizard });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        const toast = jest.fn();
        element.addEventListener('lightning__showtoast', toast);
        button(element, 'Preview Records').click();
        await flush();

        expect(toast).toHaveBeenCalledWith(
            expect.objectContaining({ detail: expect.objectContaining({ title: 'Preview generation failed' }) }),
        );
    });

    it('omits address text components when their code components are selected', async () => {
        getObjectConfiguration.mockResolvedValueOnce({
            ...config,
            fields: [
                config.fields[0],
                {
                    apiName: 'BillingCountry',
                    label: 'Billing Country',
                    dataType: 'STRING',
                    required: true,
                    length: 80,
                    picklistValues: [],
                    recommendedGenerator: 'COUNTRY',
                },
                {
                    apiName: 'BillingCountryCode',
                    label: 'Billing Country Code',
                    dataType: 'PICKLIST',
                    required: true,
                    length: 2,
                    picklistValues: ['US', 'ES', 'BR'],
                    recommendedGenerator: 'PICKLIST',
                },
            ],
        });
        const element = createElement('c-seedforce-wizard', { is: SeedforceWizard });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        button(element, 'Preview Records').click();
        await flush();

        const row = element.shadowRoot.querySelector('lightning-datatable').data[0];
        expect(row.BillingCountryCode).toBe('US');
        expect(row.BillingCountry).toBeUndefined();
    });

    it('rejects an out-of-range count on the client', async () => {
        const element = createElement('c-seedforce-wizard', {
            is: SeedforceWizard,
        });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        const toast = jest.fn();
        element.addEventListener('lightning__showtoast', toast);
        const count = [...element.shadowRoot.querySelectorAll('lightning-input')].find(
            (item) => item.type === 'number',
        );
        count.dispatchEvent(new CustomEvent('change', { detail: { value: '201' } }));
        button(element, 'Preview Records').click();
        await flush();
        expect(toast).toHaveBeenCalled();
    });

    it('selects all optional fields and preserves required fields', async () => {
        getObjectConfiguration.mockResolvedValueOnce({
            ...config,
            fields: [
                config.fields[0],
                {
                    apiName: 'Phone',
                    label: 'Phone',
                    dataType: 'PHONE',
                    required: false,
                    length: 40,
                    picklistValues: [],
                    recommendedGenerator: 'PHONE',
                },
            ],
        });
        const element = createElement('c-seedforce-wizard', { is: SeedforceWizard });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();

        const selectAll = [...element.shadowRoot.querySelectorAll('lightning-input')].find(
            (item) => item.label === 'Select all fields',
        );
        selectAll.checked = true;
        selectAll.dispatchEvent(new CustomEvent('change'));
        await flush();
        const fieldCheckboxes = [...element.shadowRoot.querySelectorAll('lightning-input')].filter(
            (item) => item.label === 'Include',
        );
        expect(fieldCheckboxes).toHaveLength(2);
        expect(fieldCheckboxes.every((item) => item.checked)).toBe(true);

        selectAll.checked = false;
        selectAll.dispatchEvent(new CustomEvent('change'));
        await flush();
        const updatedCheckboxes = [...element.shadowRoot.querySelectorAll('lightning-input')].filter(
            (item) => item.label === 'Include',
        );
        expect(updatedCheckboxes[0].checked).toBe(true);
        expect(updatedCheckboxes[1].checked).toBe(false);
    });

    it('renders record IDs as links and colors result statuses', async () => {
        const element = createElement('c-seedforce-wizard', { is: SeedforceWizard });
        document.body.appendChild(element);
        await flush();
        await selectObject(element);
        button(element, 'Configure Fields').click();
        await flush();
        button(element, 'Preview Records').click();
        await flush();
        button(element, 'Generate Records').click();
        await flush();
        button(element, 'Insert').click();
        await flush();

        const resultTable = element.shadowRoot.querySelector('lightning-datatable');
        const recordColumn = resultTable.columns.find((column) => column.label === 'Record ID');
        const statusColumn = resultTable.columns.find((column) => column.label === 'Status');
        const rowColumn = resultTable.columns.find((column) => column.label === 'Row');
        expect(rowColumn.initialWidth).toBe(80);
        expect(statusColumn.initialWidth).toBe(110);
        expect(recordColumn.type).toBe('url');
        expect(recordColumn.typeAttributes.target).toBe('_blank');
        expect(statusColumn.cellAttributes.class.fieldName).toBe('statusClass');
        expect(resultTable.data[0].recordUrl).toBe('/lightning/r/Account/001xx/view');
        expect(resultTable.data[0].statusClass).toContain('slds-text-color_success');
    });
});
