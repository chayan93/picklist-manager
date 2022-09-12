import { LightningElement, api } from 'lwc';

export default class DatatablePicklist extends LightningElement {
    @api value;
    @api stageValue;

    handleBlur(event) {
        //show the selected value on UI
        this.value = event.target.value;

        //fire event to send stageValue and selected value to the data table
        this.dispatchEvent(new CustomEvent('stagenamedescchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: { data: { stageValue: this.stageValue, value: this.value || '' } }
        }));
    }
}