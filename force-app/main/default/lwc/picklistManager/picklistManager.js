import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import picklistManagerCustomStyling from '@salesforce/resourceUrl/picklistManagerCustomStyling';

import getObjects from '@salesforce/apex/PicklistManagerController.getObjectOptions';
import createField from '@salesforce/apex/PicklistManagerController.createPicklistField';
import updateField from '@salesforce/apex/PicklistManagerController.updatePicklistField';
import getSelectedObject from '@salesforce/apex/PicklistManagerController.getSelectedObjectDetails';
import additionalInfo from '@salesforce/apex/PicklistManagerController.getAdditionalDetailsForPicklist';
import getGlobalValueSetDetail from '@salesforce/apex/PicklistManagerController.getGlobalValueSetDetail';

const generalColumns = [
    { label: 'Label', fieldName: 'label', editable: true },
    { label: 'Value', fieldName: 'fullName', editable: true },
    { label: 'Default', fieldName: 'default_x', type: 'boolean', editable: true }
];

const operationOptions = [
    { label: 'Create A New Picklist Field', value: 'create' },
    { label: 'Add Values To An Existing Picklist Field', value: 'update' }
];

const picklistTypeOptions = [
    { label: 'Single-Select', value: 'Picklist' },
    { label: 'Multi-Select', value: 'MultiselectPicklist' }
];

const picklistValueTypeOptions = [
    { label: 'Use global picklist value set', value: 'global' },
    { label: 'Enter values, with each value separated by a new line', value: 'values' }
];

const businessProcessControlledPicklists = [
    'Case.Status', 'Lead.Status', 'Solution.Status', 'Opportunity.StageName'
];

const genericErrorMessage =
    'Something went wrong, please try again later. If the issue persists, please contact the developer.';

export default class PicklistManager extends LightningElement {
    selectedOperation;
    selectedObject;
    selectedPicklistField;
    existingFieldNames;
    picklistValueType = 'global';
    activeSection = 'operationSelection';
    fieldNamePatternMismatch = 'This field can only contain alphanumeric characters, must begin with a letter, cannot end with an underscore or contain two consecutive underscore characters, and must be unique across all fields of the selected object.';

    operationSelectionError = false;
    objectSelectionError = false;
    picklistSelectionSectionError = false;
    displayButtons = false;
    showSpinner = false;
    userDefaultError = false;
    displayObjectSelectionSection = false;
    displayPicklistSelectionSection = false;
    displayFieldDetailsSection = false;
    displayAddNewPicklistValueSection = false;
    displayValueEditSection = false;
    displayRTOrBPOptionsSection = false;
    displayFLSSection = false;

    rtInfo;
    businessProcessInfo;
    globalValueSetOptions;
    additionalRecordTypesToDisplay;
    draftValues = [];
    valueDetails = [];
    objectOptions = [];
    newPicklistValues = [];
    columns = generalColumns;
    existingPicklistFields = [];
    existingPicklistValues = [];
    operationOptions = operationOptions;
    picklistTypeOptions = picklistTypeOptions;
    picklistValueTypeOptions = picklistValueTypeOptions;

    otherFieldDetail = { isSorted: false, isRestricted: false };
    standardValueSetMap;

    @track recordTypeOrBusinessProcessInfo;
    @track data;
    @track fieldDetail = {
        label: null, name: null, visibleLines: null, type_x: 'Picklist',
        required: false, description: null, inlineHelpText: null
    };
    @track dtErrors = { rows: {} };
    @track profileFLSDetails;

    fieldLevelHelp = {
        fieldLabel: 'Enter a label to be used on displays, page layouts, reports, and list views.',
        fieldName: 'The Field Name is an internal reference and is used for integration purposes such as custom links, custom s-controls, and the API.',
        inlineHelpText: 'This text displays on detail and edit pages when users hover over the Info icon next to this field.',
        isSorted: 'Display values alphabetically, not in the order entered.',
        isRestricted: 'Enforce data integrity with restricted picklists. This setting limits the field to accept values only from your picklist, even if the field is updated through the API.'
    };

    constructor() {
        super();
        loadStyle(this, picklistManagerCustomStyling);
    }

    get operationSelectionLabel() {
        return 'Select an Operation' + (
            this.selectedOperation ?
                (' - ' + this.operationOptions.find(option => option.value === this.selectedOperation).label) : ''
        );
    }

    get objectSelectionLabel() {
        return 'Object Selection' + (
            this.selectedObject ?
                (' - ' + this.objectOptions.find(option => option.value === this.selectedObject).label) : ''
        );
    }

    get picklistSelectionSectionLabel() {
        return 'Picklist Selection' + (
            this.selectedPicklistField ? (' - ' + this.existingPicklistFields.find(
                option => option.value === this.selectedPicklistField
            ).label) : ''
        );
    }

    get rtOrBPOptionSectionLabel() {
        return businessProcessControlledPicklists.indexOf(this.selectedObject + this.selectedPicklistField) !== -1 ?
            'Set Business Process Option(s)' : 'Set Record Type Option(s)'
    }

    get displayDefultForRTOrBP() {
        return this.selectedOperation === 'create' || (
            this.selectedObject + '.' + this.selectedPicklistField !== 'Opportunity.StageName' &&
            this.selectedPicklistField !== 'TeamMemberRole'
        );
    }

    get dtHelptextContent() {
        let baseMessage = 'Hover over the cells and click on the pencil icon to edit the value.';
        let fieldName = this.selectedObject + '.' + this.selectedPicklistField;
        let stageMessage = baseMessage + ' To mark a stage as Closed/Won, check both the Closed and Won checkboxes';
        stageMessage += ' or to mark a stage as Closed/Lost, check only the Closed checkbox.';
        stageMessage += ' Forecast Category and Probability fields are mandatory for every stage.';

        return (this.selectedOperation === 'create' || fieldName !== 'Opportunity.StageName') ? baseMessage : stageMessage;
    }

    get displayVisibleLines() {
        return this.fieldDetail && this.fieldDetail.type_x === 'MultiselectPicklist';
    }

    get requiredFieldSize() {
        return this.displayVisibleLines ? '12' : '6';
    }

    get displayGlobalOptions() {
        return this.selectedOperation === 'create' && this.picklistValueType === 'global' && this.globalValueSetOptions;
    }

    get displayNewFieldValueOptions() {
        return this.selectedOperation === 'create' && (this.picklistValueType === 'values' || !this.globalValueSetOptions);
    }

    get buttonLabelSaveOrNext() {
        let buttonLabel = 'Next';

        switch (this.activeSection) {
            case 'fieldDetails':
                if (!this.rtInfo && (this.fieldDetail.required || !this.profileFLSDetails)) {
                    buttonLabel = 'Save';
                }
                break;
            case 'valueEdit':
                if (
                    (this.selectedOperation === 'create' && (this.fieldDetail.required || !this.profileFLSDetails))
                    ||
                    (!this.rtInfo && !this.businessProcessInfo && !this.additionalRecordTypesToDisplay)
                ) {
                    buttonLabel = 'Save';
                }
                break;
            case 'rtOrBPOptions':
                if (this.selectedOperation === 'update' || (this.fieldDetail.required || !this.profileFLSDetails)) {
                    buttonLabel = 'Save';
                }
                break;
            case 'FLSSection':
                buttonLabel = 'Save';
                break;
        }

        return buttonLabel;
    }

    get displayPreviousButton() {
        return this.activeSection !== 'operationSelection';
    }

    resetAllValues() {
        this.showSpinner = false;
        this.activeSection = 'operationSelection';
        this.selectedOperation = null;
        this.globalValueSetOptions = null;
        this.objectOptions = [];
        this.displayObjectSelectionSection = false;
        this.operationSelectionError = false;

        this.resetObjectAndBelowSectionDetails();
    }

    resetObjectAndBelowSectionDetails() {
        this.displayPicklistSelectionSection = false;
        this.displayFieldDetailsSection = false;
        this.selectedObject = null;
        this.rtInfo = null;
        this.businessProcessInfo = null;
        this.existingFieldNames = null;
        this.existingPicklistFields = [];
        this.profileFLSDetails = null;
        this.displayFLSSection = false;
        this.objectSelectionError = false;

        this.resetPicklistSelectionAndBelowSectionDetails();
        this.resetFieldDetailsAndBelowSectionDetails();
    }

    resetPicklistSelectionAndBelowSectionDetails() {
        this.displayButtons = false;
        this.picklistSelectionSectionError = false;
        this.displayAddNewPicklistValueSection = false;
        this.selectedPicklistField = null;
        this.existingPicklistValues = [];
        this.columns = generalColumns;
        this.additionalRecordTypesToDisplay = null;

        let newPicklistValuesElem = this.template.querySelector('.newPicklistValues');
        if (newPicklistValuesElem) {
            newPicklistValuesElem.value = null;
        }

        this.resetDatatableAndBelowSectionDetails();
    }

    resetFieldDetailsAndBelowSectionDetails() {
        this.displayButtons = false;
        this.columns = generalColumns;
        this.picklistValueType = 'global';
        this.newPicklistValues = [];
        this.valueSetName = null;
        this.draftValues = [];
        this.valueSetName = null;
        if (this.fieldDetail.name && this.existingFieldNames && this.existingFieldNames.indexOf(';' + this.fieldDetail.name + ';') == -1) {
            this.existingFieldNames += this.fieldDetail.name + ';';
        }
        this.fieldDetail = {
            label: null, name: null, visibleLines: null, type_x: 'Picklist',
            required: false, description: null, inlineHelpText: null
        };
        this.otherFieldDetail = { isSorted: false, isRestricted: false };

        let newPicklistValuesElem = this.template.querySelector('.newPicklistValues');
        if (newPicklistValuesElem) {
            newPicklistValuesElem.value = null;
        }
        this.userDefaultError = false;

        this.resetDatatableAndBelowSectionDetails();
    }

    resetDatatableAndBelowSectionDetails() {
        this.data = null;
        this.valueDetails = [];
        this.dtErrors = { rows: {} };
        this.displayValueEditSection = false;
        this.resetRTOrBPSectionDetails();
    }

    resetRTOrBPSectionDetails() {
        this.displayRTOrBPOptionsSection = false;
        this.recordTypeOrBusinessProcessInfo = null;

        if (this.profileFLSDetails) {
            this.profileFLSDetails.forEach(eachProfile => {
                eachProfile.readable = true;
                eachProfile.readOnly = false;
            });
        }
    }

    handleToggleSection(event) {
        this.activeSection = event.detail.openSections;
    }

    handleOperationChange(event) {
        this.resetAllValues();
        this.selectedOperation = event.detail.value;
        this.getObjectDetails();
    }

    handleObjectChange(event) {
        this.resetObjectAndBelowSectionDetails();
        this.selectedObject = event.detail.value;
        this.getSpecificObjectDetails();
    }

    handlePicklistFieldChange(event) {
        this.resetPicklistSelectionAndBelowSectionDetails();
        this.selectedPicklistField = event.detail.value;
        this.getAdditionalInfo();
    }

    handleFieldDetailChange(event) {
        this.fieldDetail[event.target.dataset.type] = event.detail.checked || event.detail.value;
        let type = event.target.dataset.type;

        if (type === 'name') {
            this.checkNameValidity();
        }
        else if (type === 'type_x') {
            this.fieldDetail['visibleLines'] = null;
        }
        else if (type === 'required') {
            this.displayFLSSection = this.fieldDetail.required ? false :
                (((this.displayRTOrBPOptionsSection || this.valueSetName) && this.profileFLSDetails) ? true : false);
        }
    }

    handlePicklistValueTypeChange(event) {
        this.picklistValueType = event.detail.value;
        this.valueSetName = null;
        this.newPicklistValues = [];
        this.otherFieldDetail["isRestricted"] = event.detail.value === 'global';
    }

    handleGlobalPicklistValueSetChange(event) {
        this.valueSetName = event.detail.value;
    }

    handleOtherFieldDetailChange(event) {
        this.otherFieldDetail[event.target.dataset.type] = event.detail.checked;
    }

    handleLabelBlur() {
        let label = this.fieldDetail.label;
        let fieldLabel = this.template.querySelector('.fieldLabel');
        let isValid = fieldLabel.checkValidity();
        fieldLabel.reportValidity();

        if (isValid && !this.fieldDetail.name) {
            let charArrray = label.split('');
            let apiName = [''];
            let charCode = charArrray[0].charCodeAt();

            if (!((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122))) {
                apiName = ['X'];
            }

            charArrray.forEach(eachChar => {
                charCode = eachChar.charCodeAt();
                apiName.push((
                    (charCode >= 48 && charCode <= 57) ||
                    (charCode >= 65 && charCode <= 90) ||
                    (charCode >= 97 && charCode <= 122)
                ) ? eachChar : (apiName[apiName.length - 1] != '_' ? '_' : ''));
            });

            if (apiName[apiName.length - 1] === '_') {
                apiName = apiName.slice(0, apiName.length - 1);
            }

            let name = apiName.join('').slice(0, 40).replaceAll(/_+/g, '_');
            if (this.existingFieldNames.indexOf(';' + name.toLowerCase() + ';') === -1) {
                this.fieldDetail.name = name;
            }
        }
    }

    handleNewPicklistValueChange(event) {
        let newPicklistValues = this.template.querySelector('.newPicklistValues');
        newPicklistValues.setCustomValidity('');
        let isValid = newPicklistValues.checkValidity();
        newPicklistValues.reportValidity();

        if (isValid) {
            let value = event.detail.value;
            this.newPicklistValues = (value ? value.trim().split('\n') : []);

            this.newPicklistValues.forEach(eachValue => {
                let dups = this.newPicklistValues.filter(
                    val => val.toLowerCase() === eachValue.toLowerCase()
                ).concat(
                    this.existingPicklistValues.filter(
                        existingVal => existingVal.label.toLowerCase() === eachValue.toLowerCase() ||
                            existingVal.value.toLowerCase() === eachValue.toLowerCase()
                    )
                );
                if (!eachValue || dups.length > 1) {
                    newPicklistValues.setCustomValidity(
                        'The list can\'t contain any duplicate values or blank value(s)' +
                        (this.selectedOperation === 'update' ? ' or any existing picklist value(s).' : '.')
                    );
                    newPicklistValues.reportValidity();
                }
            });
        }
    }

    handleValueEditSaveOrNext() {
        this.checkForDTErrors();
        let isValid = this.userDefaultError ? !this.userDefaultError : JSON.stringify(this.dtErrors.rows) == "{}";

        if (isValid) {
            this.resetRTOrBPSectionDetails();

            if (this.rtInfo || this.businessProcessInfo || this.additionalRecordTypesToDisplay) {
                let newPicklistValues = this.template.querySelector('.newPicklistValues');

                if (newPicklistValues) {
                    let newValues = this.valueDetails.map(value => value.label);
                    this.template.querySelector('.newPicklistValues').value = newValues.join('\n');
                    this.newPicklistValues = newValues;
                }

                this.displayRTOrBPOptionsSection = true;

                if (this.selectedOperation === 'create') {
                    this.displayFieldDetailsSection = true;
                    this.recordTypeOrBusinessProcessInfo = this.rtInfo;
                }
                else {
                    let fieldName = this.selectedObject + '.' + this.selectedPicklistField;
                    this.recordTypeOrBusinessProcessInfo =
                        businessProcessControlledPicklists.indexOf(fieldName) !== -1 ?
                            this.businessProcessInfo : (this.additionalRecordTypesToDisplay || this.rtInfo);
                }

                let self = this;
                setTimeout(() => {
                    self.activeSection = 'rtOrBPOptions';
                    let rtOrBPDualListBox = self.template.querySelectorAll('.rtOrBPDualListBox');
                    if (rtOrBPDualListBox) {
                        rtOrBPDualListBox.forEach(eachList => {
                            eachList.required = this.selectedOperation === 'create';
                        });
                    }
                }, 100);
            }
            else {
                if (this.selectedOperation === 'create') {
                    this.createPicklistField();
                }
                else {
                    this.updatePicklistField();
                }
            }
        }
        else {
            this.showToast(
                '',
                this.userDefaultError ? 'Please select a default value.' : 'Please rectify all the errors to proceed.',
                'error'
            );
        }
    }

    handleCellChange(event) {
        let draftValues = event.detail.draftValues;
        let valueDetails = JSON.parse(JSON.stringify(this.valueDetails));
        let defaultValueRow;

        valueDetails.forEach(eachValue => {
            if (eachValue.rowNumber == draftValues[0].rowNumber) {
                Object.keys(draftValues[0]).forEach(eachKey => {
                    if (eachKey !== 'rowNumber') {
                        eachValue.value = eachValue.fullName;
                        eachValue[eachKey] = draftValues[0][eachKey];

                        if (eachKey === 'won' && eachValue[eachKey]) {
                            eachValue.closed = true;
                            eachValue.default_x = false;
                        }
                        else if (
                            (eachKey === 'closed' || eachKey === 'converted') &&
                            eachValue.default_x && eachValue[eachKey]
                        ) {
                            eachValue.default_x = false;
                        }
                        else if (eachKey === 'default_x' && eachValue[eachKey]) {
                            eachValue.closed = false;
                            eachValue.converted = false;
                        }
                    }

                    if (eachKey === 'default_x' && eachValue.default_x) {
                        defaultValueRow = eachValue.rowNumber;
                    }
                });
            }
        });

        if (defaultValueRow || defaultValueRow === '0') {
            valueDetails.forEach(eachValue => {
                if (eachValue.rowNumber !== defaultValueRow) {
                    eachValue.default_x = false;
                }
            });
        }

        this.valueDetails = valueDetails;
        this.data = valueDetails;
        this.draftValues = [];
    }

    handleRTOrBPSaveOrNext() {
        if (this.checkRTInfoValidity()) {
            if (this.selectedOperation === 'create') {
                if (this.profileFLSDetails && !this.fieldDetail.required) {
                    this.displayFLSSection = true;
                    let self = this;

                    setTimeout(() => {
                        self.activeSection = 'FLSSection';
                    }, 200);
                }
                else {
                    this.createPicklistField();
                }
            }
            else {
                this.updatePicklistField();
            }
        }
    }

    handleFieldDetailNext() {
        let isValid = true;

        let fieldDetail = this.template.querySelectorAll('.fieldDetail');
        if (fieldDetail && fieldDetail.length) {
            fieldDetail.forEach(eachField => {
                isValid = isValid ? eachField.checkValidity() : isValid;
                eachField.reportValidity();
            });
        }

        let newPicklistValues = this.template.querySelector('.newPicklistValues');
        if (newPicklistValues) {
            isValid = isValid ? newPicklistValues.checkValidity() : isValid;
            newPicklistValues.reportValidity();
        }

        if (isValid) {
            this.resetDatatableAndBelowSectionDetails();
            let self = this;
            let data = [];
            let counter = -1;

            if (newPicklistValues) {
                this.newPicklistValues.forEach(eachValue => {
                    ++counter;
                    data.push({
                        label: eachValue, value: eachValue, fullName: eachValue,
                        default_x: counter == 0 && this.selectedOperation === 'create' ? true : false,
                        rowNumber: counter + '',
                        allowEmail: false, closed: false, converted: false, cssExposed: false,
                        forecastCategory: null, highPriority: false, probability: null,
                        reverseRole: null, reviewed: false, won: false
                    });
                });

                this.data = data;
                this.valueDetails = data;
                this.displayValueEditSection = true;

                setTimeout(() => {
                    self.activeSection = 'valueEdit';
                }, 200);
            }
            else {
                if (this.rtInfo) {
                    this.getGlobalValueSetValues();
                }
                else if (!this.fieldDetail.required && this.profileFLSDetails) {
                    this.displayFLSSection = true;
                    setTimeout(() => {
                        self.activeSection = 'FLSSection';
                    }, 200);
                }
                else {
                    this.createPicklistField();
                }
            }
        }
    }

    handleRTOrBPInfoChange(event) {
        let value = event.detail.value;
        let name = event.target.dataset.name;
        let recordTypeOrBusinessProcessInfo = JSON.parse(JSON.stringify(this.recordTypeOrBusinessProcessInfo));

        recordTypeOrBusinessProcessInfo.forEach(eachRTOrBP => {
            if (eachRTOrBP.value === name) {
                let selectedValues = [{ label: '--None--', value: '' }];
                value.forEach(eachValue => {
                    let item = this.data.find(eachOption => eachOption.value === eachValue);
                    if (!item.closed && !item.converted) {
                        selectedValues.push({
                            label: this.data.find(eachOption => eachOption.value === eachValue).label,
                            value: eachValue
                        });
                    }
                });
                eachRTOrBP.selectedValues = selectedValues;
                if (!selectedValues.find(eachValue => { eachValue.value === eachRTOrBP.defaultValue })) {
                    eachRTOrBP.defaultValue = '';
                }
            }
        });

        this.recordTypeOrBusinessProcessInfo = recordTypeOrBusinessProcessInfo;
    }

    handleRTOrBPDefaultChange(event) {
        let value = event.detail.value;
        let name = event.target.dataset.name;
        let recordTypeOrBusinessProcessInfo = JSON.parse(JSON.stringify(this.recordTypeOrBusinessProcessInfo));

        recordTypeOrBusinessProcessInfo.forEach(eachRTOrBP => {
            if (eachRTOrBP.value === name) {
                eachRTOrBP.defaultValue = value;
            }
        });
        this.recordTypeOrBusinessProcessInfo = recordTypeOrBusinessProcessInfo;
    }

    handlePicklistChanged(event) {
        let dataRecieved = event.detail.data;
        this.data.forEach(eachEntry => {
            if (eachEntry.value === dataRecieved.stageValue) {
                eachEntry.forecastCategory = dataRecieved.value.replaceAll(' ', '');
            }
        });
        this.valueDetails = this.data;
    }

    handleStageDescChanged(event) {
        let dataRecieved = event.detail.data;
        this.data.forEach(eachEntry => {
            if (eachEntry.value === dataRecieved.stageValue) {
                eachEntry.description = dataRecieved.value;
            }
        });
        this.valueDetails = this.data;
    }

    handleFLSChange(event) {
        let name = event.target.dataset.name;
        let type = event.target.dataset.type;
        let value = event.target.dataset.value;
        let checked = event.detail.checked;
        let profileFLSDetails = JSON.parse(JSON.stringify(this.profileFLSDetails));

        if (name) {
            if (name === 'readableToAll') {
                profileFLSDetails.forEach(eachProfile => {
                    eachProfile.readable = checked;
                });

                if (!checked) {
                    profileFLSDetails.forEach(eachProfile => {
                        eachProfile.readOnly = false;
                    });
                }
            }
            else {
                profileFLSDetails.forEach(eachProfile => {
                    eachProfile.readOnly = checked;

                    if (checked) {
                        eachProfile.readable = checked;
                    }
                });
            }
        }
        else if (type && value) {
            profileFLSDetails.forEach(eachProfile => {
                if (eachProfile.value === value) {
                    eachProfile[type] = checked;

                    if (type === 'readable' && !eachProfile.readable) {
                        eachProfile.readOnly = false;
                    }
                    else if (type === 'readOnly' && eachProfile.readOnly) {
                        eachProfile.readable = true;
                    }
                }
            });
        }

        this.profileFLSDetails = profileFLSDetails;
        this.updateTopLevelCheckboxes();
    }

    handlePreviousClick() {
        if (this.activeSection === 'objectSelection') {
            this.activeSection = 'operationSelection';
        }
        else if (this.activeSection === 'fieldDetails' || this.activeSection === 'picklistSelectionSection') {
            this.activeSection = 'objectSelection';
        }
        else if (this.activeSection === 'addNewPicklistValue') {
            this.activeSection = 'picklistSelectionSection';
        }
        else if (this.activeSection === 'valueEdit') {
            this.activeSection = this.selectedOperation === 'create' ? 'fieldDetails' : 'addNewPicklistValue';
        }
        else if (this.activeSection === 'rtOrBPOptions') {
            this.activeSection = this.displayGlobalOptions ? 'fieldDetails' : 'valueEdit';
        }
        else if (this.activeSection === 'FLSSection') {
            this.activeSection = this.recordTypeOrBusinessProcessInfo ? 'rtOrBPOptions' : (
                this.displayGlobalOptions ? 'fieldDetails' : 'valueEdit'
            );
        }
    }

    handleSaveOrNext() {
        if (this.activeSection === 'operationSelection' && !this.operationSelectionError) {
            this.activeSection = 'objectSelection';
        }
        else if (this.activeSection === 'objectSelection' && !this.objectSelectionError) {
            this.activeSection = this.selectedOperation === 'create' ? 'fieldDetails' : 'picklistSelectionSection';
        }
        else if (this.activeSection === 'picklistSelectionSection' && !this.picklistSelectionSectionError) {
            this.activeSection = 'addNewPicklistValue';
        }
        else if (this.activeSection === 'fieldDetails' || this.activeSection === 'addNewPicklistValue') {
            this.handleFieldDetailNext();
        }
        else if (this.activeSection === 'valueEdit') {
            this.handleValueEditSaveOrNext();
        }
        else if (this.activeSection === 'rtOrBPOptions') {
            this.handleRTOrBPSaveOrNext();
        }
        else if (this.activeSection === 'FLSSection') {
            this.createPicklistField();
        }
    }

    getObjectDetails() {
        this.showSpinner = true;

        getObjects({ selectedOperation: this.selectedOperation }).then(response => {
            if (response && response.objectOptions && response.objectOptions.length) {
                this.objectOptions = response.objectOptions;
                this.standardValueSetMap = response.standardValueSetMap;
                this.globalValueSetOptions = response.globalValueSetOptions;
                this.displayObjectSelectionSection = true;
                this.operationSelectionError = false;
                let self = this;

                setTimeout(() => {
                    self.showSpinner = false;
                    self.activeSection = 'objectSelection';
                }, 200);
            }
            else {
                this.showSpinner = false;
                this.operationSelectionError = true;
                this.showToast('', genericErrorMessage, 'error', null, 'sticky');
            }
        });
    }

    getSpecificObjectDetails() {
        this.showSpinner = true;

        getSelectedObject({ selectedObject: this.selectedObject }).then(response => {
            if (response) {
                let details = JSON.parse(JSON.stringify(response));
                this.existingFieldNames = details.existingFieldNames;
                this.existingPicklistFields = details.existingPicklistFields;
                this.objectSelectionError = false;
                let activeSection = this.selectedOperation === 'create' ?
                    'fieldDetails' : 'picklistSelectionSection';
                let self = this;

                if (details.rtInfo.length) {
                    let rtInfo = details.rtInfo;

                    rtInfo.forEach(eachRT => {
                        eachRT.selectedValues = [{ label: '--None--', value: '' }];
                        eachRT.defaultValue = '';
                    });

                    this.rtInfo = rtInfo;
                }

                if (details.businessProcessInfo.length) {
                    let businessProcessInfo = details.businessProcessInfo;

                    businessProcessInfo.forEach(eachRT => {
                        eachRT.selectedValues = [{ label: '--None--', value: '' }];
                        eachRT.defaultValue = '';
                    });

                    this.businessProcessInfo = businessProcessInfo;
                }

                if (this.selectedOperation === 'create') {
                    this.displayFieldDetailsSection = true;
                    this.displayButtons = true;

                    if (details.eligibleProfiles.length) {
                        this.profileFLSDetails = details.eligibleProfiles;
                    }
                }
                else {
                    this.displayButtons = false;
                    this.displayPicklistSelectionSection = true;
                }

                setTimeout(() => {
                    self.showSpinner = false;
                    self.activeSection = activeSection;
                }, 200);
            }
            else{
                this.showSpinner = false;
                this.objectSelectionError = true;
                this.showToast('', genericErrorMessage, 'error', null, 'sticky');
            }
        });
    }

    getAdditionalInfo() {
        this.showSpinner = true;
        let fieldName = this.selectedObject + '.' + this.selectedPicklistField;
        let standardValueSetName = this.standardValueSetMap[fieldName];
        let recordTypeOrBusinessProcessInfo =
            businessProcessControlledPicklists.indexOf(fieldName) !== -1 ? this.businessProcessInfo : this.rtInfo;

        additionalInfo({
            masterLabel: standardValueSetName,
            selectedObject: this.selectedObject,
            fieldAPIName: this.selectedPicklistField
        }).then(response => {
            if (response && !response.globalValueSetName) {
                this.displayButtons = true;
                this.existingPicklistValues = response.existingPicklistValues;
                this.displayAddNewPicklistValueSection = true;
                this.picklistSelectionSectionError = false;
                let self = this;

                if (standardValueSetName) {
                    let columns = JSON.parse(JSON.stringify(response.columnStructure));
                    if (standardValueSetName === 'OpportunityStage') {
                        columns.forEach(eachColumn => {
                            if (eachColumn.fieldName === 'forecastCategory' && response.forecastCategories) {
                                let typeAttribute = {};
                                typeAttribute['options'] = response.forecastCategories;
                                typeAttribute['value'] = { fieldName: 'forecastCategory' };
                                typeAttribute['stageValue'] = { fieldName: 'fullName' };
                                typeAttribute['placeholder'] = 'Select a value';

                                eachColumn['typeAttributes'] = typeAttribute;
                                eachColumn['type'] = 'picklistCell';
                                eachColumn['wrapText'] = true;
                            }
                            else if (eachColumn.fieldName === 'description') {
                                let typeAttribute = {};
                                typeAttribute['value'] = { fieldName: 'description' };
                                typeAttribute['stageValue'] = { fieldName: 'fullName' };

                                eachColumn['typeAttributes'] = typeAttribute;
                                eachColumn['type'] = 'textAreaCell';
                                eachColumn['wrapText'] = true;
                            }
                        });
                    }
                    else if (response.additionalRecordTypesToDisplay.length) {
                        this.additionalRecordTypesToDisplay = response.additionalRecordTypesToDisplay;
                        recordTypeOrBusinessProcessInfo = response.additionalRecordTypesToDisplay;
                    }

                    this.columns = columns;
                    this.recordTypeOrBusinessProcessInfo = recordTypeOrBusinessProcessInfo;
                }

                setTimeout(() => {
                    self.showSpinner = false;
                    self.activeSection = 'addNewPicklistValue';
                }, 200);
            }
            else if (response && response.globalValueSetName) {
                this.showSpinner = false;
                this.picklistSelectionSectionError = true;
                this.showToast(
                    '',
                    'Sorry, this field is controlled by a Global Value Set (' +
                    response.globalValueSetName + ') and therefore cannot by updated from here.',
                    'error', null, 'sticky'
                );
            }
            else {
                this.showSpinner = false;
                this.picklistSelectionSectionError = true;
                this.showToast('', genericErrorMessage, 'error', null, 'sticky');
            }
        });
    }

    getGlobalValueSetValues() {
        let self = this;
        let data = [];
        let counter = -1;
        this.showSpinner = true;

        getGlobalValueSetDetail({ valueSetName: this.valueSetName }).then(response => {
            if (response && response.length) {
                response.forEach(eachValue => {
                    data.push({
                        label: eachValue.label, value: eachValue.value, fullName: eachValue.value,
                        default_x: ++counter === 0,
                        allowEmail: false, closed: false, converted: false, cssExposed: false,
                        forecastCategory: null, highPriority: false, probability: null,
                        reverseRole: null, reviewed: false, won: false
                    });
                });
                this.data = data;
                this.valueDetails = data;
                this.recordTypeOrBusinessProcessInfo = this.rtInfo;
                this.displayRTOrBPOptionsSection = true;

                setTimeout(() => {
                    self.activeSection = 'rtOrBPOptions';
                    let rtOrBPDualListBox = self.template.querySelectorAll('.rtOrBPDualListBox');
                    if (rtOrBPDualListBox) {
                        rtOrBPDualListBox.forEach(eachList => {
                            eachList.required = true;
                        });
                    }
                }, 200);
            }
            else {
                this.showToast(
                    '',
                    'Error in retrieving Global Value Set - ' + this.valueSetName +
                    ', please try again later. If the issue persists, please contact the administrator.',
                    'error'
                );
            }
        }).catch(error => {
            console.error(error);
        }).finally(() => {
            this.showSpinner = false;
        });
    }

    createPicklistField() {
        let variant;
        let recordTypeOrBusinessProcessInfo = this.checkRTOrBPInfoToUpdate();

        let valueDetails = JSON.parse(JSON.stringify(this.valueDetails));
        valueDetails.forEach(eachValue => {
            delete eachValue.value;
            delete eachValue.rowNumber;
        });

        let profileFLSDetails = this.profileFLSDetails ? JSON.parse(JSON.stringify(this.profileFLSDetails)) : null;
        if (profileFLSDetails) {
            for (let counter = 0; counter < profileFLSDetails.length; counter++) {
                if (!profileFLSDetails[counter].readable && !profileFLSDetails[counter].readOnly) {
                    profileFLSDetails.splice(counter, 1);
                    --counter;
                }
            }
        }

        let fieldDetail = JSON.parse(JSON.stringify(this.fieldDetail));
        fieldDetail.name += '__c';
        let fieldAPIName = fieldDetail.name;

        let details = {
            isSorted: this.otherFieldDetail.isSorted,
            fieldDetail: JSON.stringify(fieldDetail),
            fieldAPIName: JSON.stringify(fieldAPIName),
            valueDetails: JSON.stringify(valueDetails),
            isRestricted: this.otherFieldDetail.isRestricted,
            selectedObject: JSON.stringify(this.selectedObject),
            valueSetName: JSON.stringify(this.valueSetName || ''),
            rtDetails: recordTypeOrBusinessProcessInfo ? JSON.stringify(recordTypeOrBusinessProcessInfo) : '',
            profileFLSDetails: (this.profileFLSDetails && profileFLSDetails.length > 0 && !fieldDetail.required) ?
                JSON.stringify(profileFLSDetails) : ''
        };

        this.showSpinner = true;
        createField({ details: details }).then(response => {
            if (response && response.message) {
                variant = response.variant;

                this.showToast(
                    'Error..!!', response.message, variant,
                    response.messageData,
                    variant === 'error' ? 'sticky' : 'pester'
                );
            }
        }).catch(error => {
            console.error(error);
        }).finally(() => {
            if (variant && variant !== 'error') {
                this.displayFLSSection = false;
                let self = this;

                setTimeout(() => {
                    self.resetFieldDetailsAndBelowSectionDetails();
                    self.activeSection = 'fieldDetails';
                    self.showSpinner = false;
                }, 1000);
            }
            else {
                this.showSpinner = false;
            }
        });
    }

    updatePicklistField() {
        let variant;
        let fieldFullName = this.selectedObject + '.' + this.selectedPicklistField;
        let standardValueSetName = this.standardValueSetMap[fieldFullName];
        let recordTypeOrBusinessProcessInfo = this.checkRTOrBPInfoToUpdate();
        let isBPControlled = recordTypeOrBusinessProcessInfo && businessProcessControlledPicklists.indexOf(fieldFullName) !== -1;
        let isRecordTypeOrBusinessProcess = isBPControlled ? 'BP' : (recordTypeOrBusinessProcessInfo ? 'RT' : '');

        let valueDetails = JSON.parse(JSON.stringify(this.valueDetails));
        valueDetails.forEach(eachValue => {
            delete eachValue.value;
            delete eachValue.rowNumber;
        });

        let details = {
            valueDetails: JSON.stringify(valueDetails),
            selectedObject: JSON.stringify(this.selectedObject),
            fieldAPIName: JSON.stringify(this.selectedPicklistField),
            standardValueSetName: standardValueSetName ? JSON.stringify(standardValueSetName) : '',
            isRecordTypeOrBusinessProcess: isRecordTypeOrBusinessProcess ? JSON.stringify(isRecordTypeOrBusinessProcess) : '',
            recordTypeOrBusinessProcessInfo: recordTypeOrBusinessProcessInfo ? JSON.stringify(recordTypeOrBusinessProcessInfo) : ''
        };

        this.showSpinner = true;
        updateField({ details: details }).then(response => {
            if (response && response.message) {
                variant = response.variant;

                this.showToast(
                    variant === 'error' ? 'Error..!!' : 'Success..!!',
                    response.message, variant, response.messageData,
                    variant === 'error' ? 'sticky' : 'pester'
                );
            }
        }).catch(error => {
            console.error(error);
            this.showSpinner = false;
        }).finally(() => {
            if (variant !== 'error') {
                let self = this;
                setTimeout(() => {
                    self.resetPicklistSelectionAndBelowSectionDetails();

                    setTimeout(() => {
                        self.activeSection = 'picklistSelectionSection';
                        self.showSpinner = false;
                    }, 200);
                }, 1000);
            }
            else {
                this.showSpinner = false;
            }
        });
    }

    checkNameValidity() {
        let fieldName = this.template.querySelector('.fieldName');
        fieldName.setCustomValidity('');
        let isValid = fieldName.checkValidity();
        fieldName.reportValidity();

        if (
            isValid &&
            this.existingFieldNames.indexOf(';' + this.fieldDetail.name.toLowerCase() + ';') !== -1
        ) {
            isValid = false;
            fieldName.setCustomValidity(
                'The name matches with an existing field\'s name. Please change the value.'
            );
            fieldName.reportValidity();
        }

        return isValid;
    }

    checkRTOrBPInfoToUpdate() {
        let recordTypeOrBusinessProcessInfo = JSON.parse(JSON.stringify(this.recordTypeOrBusinessProcessInfo));
        if (recordTypeOrBusinessProcessInfo) {
            for (let counter = 0; counter < recordTypeOrBusinessProcessInfo.length; counter++) {
                if (
                    !recordTypeOrBusinessProcessInfo[counter].selectedValues ||
                    !recordTypeOrBusinessProcessInfo[counter].selectedValues.length ||
                    (
                        recordTypeOrBusinessProcessInfo[counter].selectedValues.length == 1 &&
                        !recordTypeOrBusinessProcessInfo[counter].selectedValues[0].value
                    )
                ) {
                    recordTypeOrBusinessProcessInfo.splice(counter, 1);
                    --counter;
                }
                else {
                    recordTypeOrBusinessProcessInfo[counter].selectedValues =
                        recordTypeOrBusinessProcessInfo[counter].selectedValues.slice(1);
                }
            }

            if (!recordTypeOrBusinessProcessInfo.length) {
                recordTypeOrBusinessProcessInfo = null;
            }
        }

        return recordTypeOrBusinessProcessInfo;
    }

    checkRTInfoValidity() {
        let isValid = true;
        let rtOrBPDualListBox = this.template.querySelectorAll('.rtOrBPDualListBox');

        if (rtOrBPDualListBox && rtOrBPDualListBox.length && this.selectedOperation === 'create') {
            rtOrBPDualListBox.forEach(eachRTInfo => {
                isValid = isValid ? eachRTInfo.checkValidity() : isValid;
                eachRTInfo.reportValidity();
            });
        }

        return isValid;
    }

    checkForDTErrors() {
        this.checkRequiredDTFields();
        this.checkDuplicateEntries();
    }

    checkRequiredDTFields() {
        let fieldName = this.selectedObject + '.' + this.selectedPicklistField;
        let data = this.data;
        let erroneousRows = {};
        let defaultValue;

        for (let counter = 0; counter < data.length; counter++) {
            if (data[counter].default_x) {
                defaultValue = data[counter].value;
            }

            let isForecastOrProbablityError =
                fieldName === 'Opportunity.StageName' && (
                    !data[counter].forecastCategory || !data[counter].probability ||
                    data[counter].probability < 0 || data[counter].probability > 100
                );

            if (!data[counter].label || !data[counter].value || isForecastOrProbablityError) {
                let messages = [
                    ...(!data[counter].label ? ['Please fill up Label'] : []),
                    ...(!data[counter].value ? ['Please fill up Value'] : []),
                    ...(
                        isForecastOrProbablityError && !data[counter].forecastCategory ?
                            ['Please fill up Forecast Category'] : []
                    ),
                    ...(
                        isForecastOrProbablityError ? (
                            !data[counter].probability ? ['Please fill up Probability'] : (
                                data[counter].probability < 0 || data[counter].probability > 100 ?
                                    ['Probability must be between 0 and 100'] : []
                            )
                        ) : []
                    )
                ];
                let fieldNames = [
                    ...(!data[counter].label ? ['label'] : []),
                    ...(!data[counter].value ? ['fullName'] : []),
                    ...(isForecastOrProbablityError && !data[counter].forecastCategory ? ['forecastCategory'] : []),
                    ...(messages.filter(
                        eachMessage => eachMessage.indexOf('Probability') !== -1
                    ).length ? ['probability'] : [])
                ];

                erroneousRows[counter] = { title: 'Error!!', messages: messages, fieldNames: fieldNames };
            }
        }

        this.dtErrors = { rows: erroneousRows };
        this.userDefaultError = this.selectedObject === 'User' && this.selectedOperation === 'create' &&
            this.fieldDetail.required && !defaultValue;
    }

    checkDuplicateEntries() {
        let data = JSON.parse(JSON.stringify(this.data));
        let erroneousRows = JSON.parse(JSON.stringify(this.dtErrors.rows));
        let allLabels = data.map(eachEntry => eachEntry.label);
        let allValues = data.map(eachEntry => eachEntry.value);

        for (let counter = 0; counter < data.length; counter++) {
            if (erroneousRows.hasOwnProperty(counter)) {
                for (let dupCounter = 0; dupCounter < erroneousRows[counter].messages.length; dupCounter++) {
                    let message = erroneousRows[counter].messages[dupCounter];
                    if (message.startsWith('Duplicate')) {
                        let fieldToRemove = message.indexOf('label') !== -1 ? 'label' : (
                            message.indexOf('value') !== -1 ? 'fullName' : ''
                        );
                        if (fieldToRemove) {
                            for (
                                let fieldCounter = 0;
                                fieldCounter < erroneousRows[counter].fieldNames.length;
                                fieldCounter++
                            ) {
                                if (erroneousRows[counter].fieldNames[fieldCounter] === fieldToRemove) {
                                    erroneousRows[counter].fieldNames.splice(fieldCounter, 1);
                                    --fieldCounter;
                                }
                            }
                        }

                        erroneousRows[counter].messages.splice(dupCounter, 1);
                        --dupCounter;
                    }
                }

                if (!erroneousRows[counter].messages.length && !erroneousRows[counter].fieldNames.length) {
                    delete erroneousRows[counter];
                }
            }


            let duplicateLabelPositions = [], duplicateValuePositions = [];
            for (let dupCounter = 0; dupCounter < allLabels.length; dupCounter++) {
                if (
                    allLabels[dupCounter] && dupCounter != counter &&
                    allLabels[dupCounter].toLowerCase() === data[counter].label.toLowerCase()
                ) {
                    duplicateLabelPositions.push(dupCounter + 1);
                }

                if (
                    allValues[dupCounter] && dupCounter != counter &&
                    allValues[dupCounter].toLowerCase() === data[counter].value.toLowerCase()
                ) {
                    duplicateValuePositions.push(dupCounter + 1);
                }
            }

            if (duplicateLabelPositions.length || duplicateValuePositions.length) {
                let labelMessage = duplicateLabelPositions.length ?
                    ['Duplicate with label(s) at Row Number(s) ' + duplicateLabelPositions.join(', ')] : [];
                let valueMessage = duplicateValuePositions.length ?
                    ['Duplicate with value(s) at Row Number(s) ' + duplicateValuePositions.join(', ')] : [];
                let fieldNames = [
                    ...(labelMessage.length ? ['label'] : []),
                    ...(valueMessage.length ? ['fullName'] : [])
                ];

                let existingMessages = erroneousRows.hasOwnProperty(counter) ?
                    erroneousRows[counter].messages : [];
                let existingFieldNames = erroneousRows.hasOwnProperty(counter) ?
                    erroneousRows[counter].fieldNames : [];
                erroneousRows[counter] = {
                    title: 'Error!!',
                    messages: Array.from(new Set([...existingMessages, ...labelMessage.concat(valueMessage)])),
                    fieldNames: Array.from(new Set([...existingFieldNames, ...fieldNames]))
                };
            }

            if (this.selectedOperation === 'update') {
                let labelMessage = data[counter].label && this.existingPicklistValues.filter(
                    existing => existing.label.toLowerCase() === data[counter].label.toLowerCase()
                ).length > 0 ? ['Duplicate with an existing picklist label'] : [];

                let valueMessage = data[counter].value && this.existingPicklistValues.filter(
                    existing => existing.value.toLowerCase() === data[counter].value.toLowerCase()
                ).length > 0 ? ['Duplicate with an existing picklist value'] : [];

                if (labelMessage.length || valueMessage.length) {
                    if (erroneousRows.hasOwnProperty(counter)) {
                        erroneousRows[counter].messages =
                            erroneousRows[counter].messages.concat(labelMessage.concat(valueMessage));
                        erroneousRows[counter].fieldNames = erroneousRows[counter].fieldNames.concat([
                            ...labelMessage.length ? ['label'] : [],
                            ...valueMessage.length ? ['fullName'] : []
                        ]);
                    }
                    else {
                        erroneousRows[counter] = {
                            title: 'Error!!',
                            messages: labelMessage.concat(valueMessage),
                            fieldNames: [
                                ...(labelMessage.length ? ['label'] : []),
                                ...(valueMessage.length ? ['fullName'] : [])
                            ]
                        };
                    }
                }
            }
        }

        this.dtErrors = { rows: erroneousRows };
    }

    updateTopLevelCheckboxes() {
        let areAllReadable = this.profileFLSDetails.find(eachProfile => { return !eachProfile.readable; }) ? false : true;
        let areAllReadOnly = this.profileFLSDetails.find(eachProfile => { return !eachProfile.readOnly; }) ? false : true;

        let readableToAll = this.template.querySelector('.readableToAll');
        let readOnlyToAll = this.template.querySelector('.readOnlyToAll');

        if (readableToAll) {
            readableToAll.checked = areAllReadable;
        }
        if (readOnlyToAll) {
            readOnlyToAll.checked = areAllReadOnly;
        }
    }

    showToast(title, message, variant, messageData, mode) {
        this.dispatchEvent(new ShowToastEvent({
            title: title, message: message, variant: variant, messageData: messageData, mode: mode
        }));
    }
}