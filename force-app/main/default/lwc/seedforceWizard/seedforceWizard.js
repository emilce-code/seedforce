import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import FAKER_RESOURCE from '@salesforce/resourceUrl/seedforceFaker';
import SEEDFORCE_LOGO from '@salesforce/resourceUrl/seedforceLogo';
import getSupportedObjects from '@salesforce/apex/SeedforceController.getSupportedObjects';
import getObjectConfiguration from '@salesforce/apex/SeedforceController.getObjectConfiguration';
import getGeneratorConfiguration from '@salesforce/apex/SeedforceController.getGeneratorConfiguration';
import generateRecords from '@salesforce/apex/SeedforceController.generateRecords';
import { createGeneratorRegistry } from './generatorRegistry';

const STEPS = Object.freeze({
    OBJECT: '1',
    FIELDS: '2',
    PREVIEW: '3',
    GENERATE: '4',
});
const LOCALES = [
    { label: 'English', value: 'en' },
    { label: 'Español', value: 'es' },
    { label: 'Português (Brasil)', value: 'pt_BR' },
];

export default class SeedforceWizard extends LightningElement {
    currentStep = STEPS.OBJECT;
    objectOptions = [];
    selectedObject = '';
    objectSearch = '';
    objectDropdownOpen = false;
    configuration;
    configuredFields = [];
    recordCount = 10;
    locale = 'en';
    previewRows = [];
    previewFields = [];
    generationResult;
    busy = false;
    confirmOpen = false;
    faker;
    registry = createGeneratorRegistry();
    runtimeConfiguration;
    logoUrl = SEEDFORCE_LOGO;

    @wire(getSupportedObjects)
    wiredObjects({ data, error }) {
        if (data)
            this.objectOptions = data.map((item) => ({
                label: `${item.label} (${item.apiName})`,
                value: item.apiName,
            }));
        else if (error) this.toast('Unable to load objects', this.errorMessage(error), 'error');
    }

    @wire(getGeneratorConfiguration)
    wiredGeneratorConfiguration({ data, error }) {
        if (data) this.runtimeConfiguration = data;
        else if (error) this.toast('Unable to load generator settings', this.errorMessage(error), 'error');
    }

    connectedCallback() {
        loadScript(this, FAKER_RESOURCE)
            .then(() => {
                this.faker = window.SeedforceFaker.create(this.locale);
            })
            .catch((error) => this.toast('Unable to load Faker', this.errorMessage(error), 'error'));
    }

    get localeOptions() {
        return LOCALES;
    }
    get filteredObjectOptions() {
        const query = this.objectSearch.trim().toLowerCase();
        return this.objectOptions
            .filter(
                (option) =>
                    !query || option.label.toLowerCase().includes(query) || option.value.toLowerCase().includes(query),
            )
            .slice(0, 50);
    }
    get showObjectDropdown() {
        return this.objectDropdownOpen && this.filteredObjectOptions.length > 0;
    }
    get generatorOptions() {
        if (!this.runtimeConfiguration) return this.registry.options();
        return this.runtimeConfiguration.generators
            .filter((setting) => setting.active && this.registry.has(setting.key))
            .map((setting) => ({ label: setting.label, value: setting.key }));
    }
    get isObjectStep() {
        return this.currentStep === STEPS.OBJECT;
    }
    get isFieldsStep() {
        return this.currentStep === STEPS.FIELDS;
    }
    get isPreviewStep() {
        return this.currentStep === STEPS.PREVIEW;
    }
    get isGenerateStep() {
        return this.currentStep === STEPS.GENERATE;
    }
    get hasBlockers() {
        return Boolean(this.configuration?.blockers?.length);
    }
    get allFieldsSelected() {
        return this.configuredFields.length > 0 && this.configuredFields.every((field) => field.selected);
    }
    get nextDisabled() {
        return !this.selectedObject || this.busy;
    }
    get previewColumns() {
        return [
            { label: '#', fieldName: '_row', type: 'number', initialWidth: 70 },
            ...this.previewFields.map((field) => ({ label: field.label, fieldName: field.apiName, type: 'text' })),
        ];
    }
    get resultColumns() {
        return [
            { label: 'Row', fieldName: 'rowNumber', type: 'number', initialWidth: 80 },
            {
                label: 'Status',
                fieldName: 'status',
                type: 'text',
                initialWidth: 110,
                cellAttributes: { class: { fieldName: 'statusClass' } },
            },
            {
                label: 'Record ID',
                fieldName: 'recordUrl',
                type: 'url',
                typeAttributes: { label: { fieldName: 'recordId' }, target: '_blank' },
            },
            { label: 'Messages', fieldName: 'message', wrapText: true },
        ];
    }
    get resultRows() {
        return (this.generationResult?.rows || []).map((row) => ({
            ...row,
            status: row.success ? 'Inserted' : 'Failed',
            statusClass: row.success
                ? 'slds-text-color_success slds-text-title_bold'
                : 'slds-text-color_error slds-text-title_bold',
            recordUrl: row.recordId ? `/lightning/r/${this.selectedObject}/${row.recordId}/view` : null,
            message: (row.messages || []).join(' '),
        }));
    }
    get summary() {
        if (!this.generationResult) return '';
        return `${this.generationResult.inserted} inserted, ${this.generationResult.failed} failed.`;
    }

    handleObjectSearch(event) {
        this.objectSearch = event.target.value;
        this.selectedObject = '';
        this.configuration = undefined;
        this.objectDropdownOpen = true;
    }
    handleObjectFocus() {
        this.objectDropdownOpen = true;
    }
    handleObjectSelect(event) {
        const apiName = event.currentTarget.dataset.value;
        const selected = this.objectOptions.find((option) => option.value === apiName);
        this.selectedObject = apiName;
        this.objectSearch = selected?.label || apiName;
        this.configuration = undefined;
        this.objectDropdownOpen = false;
    }
    handleCountChange(event) {
        this.recordCount = Number(event.detail.value);
    }
    handleLocaleChange(event) {
        this.locale = event.detail.value;
        if (window.SeedforceFaker) this.faker = window.SeedforceFaker.create(this.locale);
    }
    handleFieldToggle(event) {
        this.updateField(event.target.dataset.field, {
            selected: event.target.checked,
        });
    }
    handleSelectAllFields(event) {
        const selected = event.target.checked;
        this.configuredFields = this.configuredFields.map((field) => ({
            ...field,
            selected: selected || field.required,
        }));
    }
    handleGeneratorChange(event) {
        this.updateField(event.target.dataset.field, {
            generator: event.detail.value,
        });
    }
    updateField(apiName, changes) {
        this.configuredFields = this.configuredFields.map((field) => {
            return field.apiName === apiName ? { ...field, ...changes } : field;
        });
    }

    async nextFromObject() {
        this.busy = true;
        try {
            this.configuration = await getObjectConfiguration({
                objectApiName: this.selectedObject,
            });
            this.objectDropdownOpen = false;
            this.configuredFields = this.configuration.fields.map((field) => ({
                ...field,
                selected: field.required,
                generator: field.recommendedGenerator,
            }));
            this.currentStep = STEPS.FIELDS;
        } catch (error) {
            this.toast('Object unavailable', this.errorMessage(error), 'error');
        } finally {
            this.busy = false;
        }
    }

    showPreview() {
        if (!this.validateConfiguration()) return;
        try {
            this.previewFields = this.fieldsForPreview();
            this.previewRows = Array.from({ length: this.recordCount }, (_, index) => {
                const row = { _row: index + 1 };
                this.previewFields.forEach((field) => {
                    row[field.apiName] = this.registry
                        .get(field.generator)
                        .generate({ faker: this.faker, field, locale: this.locale });
                });
                return row;
            });
            this.currentStep = STEPS.PREVIEW;
        } catch (error) {
            this.previewRows = [];
            this.toast('Preview generation failed', this.errorMessage(error), 'error');
        }
    }

    fieldsForPreview() {
        const selected = this.configuredFields.filter((field) => field.selected);
        const selectedNames = new Set(selected.map((field) => field.apiName.toLowerCase()));
        return selected.filter((field) => {
            const fieldName = field.apiName.toLowerCase();
            const codeCounterpart = fieldName.includes('country')
                ? fieldName.replace('country', 'countrycode')
                : fieldName.replace('state', 'statecode');
            const isScalarAddressComponent =
                (fieldName.includes('country') && !fieldName.includes('countrycode')) ||
                (fieldName.includes('state') && !fieldName.includes('statecode'));
            return !isScalarAddressComponent || !selectedNames.has(codeCounterpart);
        });
    }

    validateConfiguration() {
        if (this.hasBlockers) {
            this.toast(
                'Unsupported required fields',
                'This object cannot be generated until its required unsupported fields are handled.',
                'error',
            );
            return false;
        }
        if (!Number.isInteger(this.recordCount) || this.recordCount < 1 || this.recordCount > 200) {
            this.toast('Invalid record count', 'Enter a whole number from 1 through 200.', 'error');
            return false;
        }
        if (!this.faker) {
            this.toast('Faker is loading', 'Wait a moment and try again.', 'warning');
            return false;
        }
        const selected = this.configuredFields.filter((field) => field.selected);
        if (!selected.length || this.configuredFields.some((field) => field.required && !field.selected)) {
            this.toast('Required fields missing', 'Select every required field and at least one field.', 'error');
            return false;
        }
        const selectedNames = new Set(selected.map((field) => field.apiName.toLowerCase()));
        const unpairedStateCode = selected.find((field) => {
            const fieldName = field.apiName.toLowerCase();
            return fieldName.includes('statecode') && !selectedNames.has(fieldName.replace('statecode', 'countrycode'));
        });
        if (unpairedStateCode) {
            this.toast(
                'Country code required',
                `${unpairedStateCode.label} is a dependent picklist. Include its matching Country Code field to generate valid address combinations.`,
                'error',
            );
            return false;
        }
        return true;
    }

    regenerate() {
        this.showPreview();
    }
    requestGenerate() {
        this.confirmOpen = true;
    }
    closeConfirm() {
        this.confirmOpen = false;
    }
    backToObject() {
        this.currentStep = STEPS.OBJECT;
        this.selectedObject = '';
        this.objectSearch = '';
        this.objectDropdownOpen = false;
    }
    backToFields() {
        this.currentStep = STEPS.FIELDS;
    }

    async confirmGenerate() {
        this.confirmOpen = false;
        this.busy = true;
        const records = this.previewRows.map((row) =>
            Object.fromEntries(Object.entries(row).filter(([key]) => key !== '_row')),
        );
        try {
            this.generationResult = await generateRecords({
                request: {
                    objectApiName: this.selectedObject,
                    recordCount: this.recordCount,
                    records,
                },
            });
            this.currentStep = STEPS.GENERATE;
            this.toast(
                this.generationResult.success ? 'Records generated' : 'Generation completed with errors',
                `${this.generationResult.inserted} of ${this.generationResult.requested} records inserted.`,
                this.generationResult.success ? 'success' : 'warning',
            );
        } catch (error) {
            this.toast('Generation failed', this.errorMessage(error), 'error');
        } finally {
            this.busy = false;
        }
    }

    startOver() {
        this.currentStep = STEPS.OBJECT;
        this.configuration = undefined;
        this.configuredFields = [];
        this.previewRows = [];
        this.previewFields = [];
        this.generationResult = undefined;
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    errorMessage(error) {
        return error?.body?.message || error?.message || 'An unexpected error occurred.';
    }
}
