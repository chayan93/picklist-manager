import { LightningElement, api } from 'lwc';

export default class DatatablePicklist extends LightningElement {
    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api stageValue;

    handleChange(event) {
        //show the selected value on UI
        this.value = event.detail.value;

        //fire event to send stageValue and selected value to the data table
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { stageValue: this.stageValue, value: this.value }
            }
        }));
    }
}