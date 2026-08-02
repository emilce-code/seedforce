import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SEEDFORCE_LOGO_SMALL from '@salesforce/resourceUrl/seedforceLogoSmall';
import getConfiguration from '@salesforce/apex/SeedforceConfigurationController.getConfiguration';
import saveConfiguration from '@salesforce/apex/SeedforceConfigurationController.saveConfiguration';

const FIELD_TYPES = [
    'ANY',
    'STRING',
    'TEXTAREA',
    'EMAIL',
    'PHONE',
    'URL',
    'BOOLEAN',
    'INTEGER',
    'DOUBLE',
    'CURRENCY',
    'PERCENT',
    'DATE',
    'DATETIME',
    'PICKLIST',
    'MULTIPICKLIST',
].map((value) => ({ label: value === 'ANY' ? 'Any field type' : value, value }));

export default class SeedforceConfiguration extends LightningElement {
    generators = [];
    rules = [];
    deletedRuleIds = [];
    busy = false;
    sequence = 0;
    logoUrl = SEEDFORCE_LOGO_SMALL;

    connectedCallback() {
        this.load();
    }

    get fieldTypeOptions() {
        return FIELD_TYPES;
    }
    get generatorOptions() {
        return this.generators.map((item) => ({ label: item.label, value: item.key }));
    }
    get hasRules() {
        return this.rules.length > 0;
    }

    async load() {
        this.busy = true;
        try {
            this.applyConfiguration(await getConfiguration());
        } catch (error) {
            this.toast('Unable to load configuration', this.errorMessage(error), 'error');
        } finally {
            this.busy = false;
        }
    }

    applyConfiguration(configuration) {
        this.generators = (configuration.generators || []).map((item) => ({ ...item }));
        this.rules = (configuration.rules || []).map((item) => ({ ...item, localKey: item.id }));
        this.deletedRuleIds = [];
    }

    updateGenerator(event) {
        const key = event.target.dataset.key;
        const property = event.target.dataset.property;
        const value =
            property === 'active'
                ? event.target.checked
                : property === 'sortOrder'
                  ? Number(event.target.value)
                  : event.target.value;
        this.generators = this.generators.map((item) => (item.key === key ? { ...item, [property]: value } : item));
    }

    updateRule(event) {
        const localKey = event.target.dataset.key;
        const property = event.target.dataset.property;
        let value = property === 'active' ? event.target.checked : (event.detail?.value ?? event.target.value);
        if (['priority', 'minimumLength', 'maximumLength'].includes(property))
            value = value === '' ? null : Number(value);
        this.rules = this.rules.map((item) => (item.localKey === localKey ? { ...item, [property]: value } : item));
    }

    addRule() {
        this.sequence += 1;
        this.rules = [
            ...this.rules,
            {
                localKey: `new-${this.sequence}`,
                name: `Rule ${this.rules.length + 1}`,
                active: true,
                fieldType: 'STRING',
                fieldNamePattern: '',
                generatorKey: 'TEXT',
                priority: 100,
                minimumLength: null,
                maximumLength: null,
            },
        ];
    }

    removeRule(event) {
        const localKey = event.currentTarget.dataset.key;
        const removed = this.rules.find((item) => item.localKey === localKey);
        if (removed?.id) this.deletedRuleIds = [...this.deletedRuleIds, removed.id];
        this.rules = this.rules.filter((item) => item.localKey !== localKey);
    }

    async save() {
        this.busy = true;
        try {
            const request = {
                generators: this.generators.map(({ id, key, label, active, sortOrder }) => ({
                    id,
                    key,
                    label,
                    active,
                    sortOrder,
                })),
                rules: this.rules.map((rule) =>
                    Object.fromEntries(Object.entries(rule).filter(([property]) => property !== 'localKey')),
                ),
                deletedRuleIds: this.deletedRuleIds,
            };
            this.applyConfiguration(await saveConfiguration({ request }));
            this.toast(
                'Configuration saved',
                'Seedforce generator options and recommendation rules are active.',
                'success',
            );
        } catch (error) {
            this.toast('Unable to save configuration', this.errorMessage(error), 'error');
        } finally {
            this.busy = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    errorMessage(error) {
        return error?.body?.message || error?.message || 'An unexpected error occurred.';
    }
}
