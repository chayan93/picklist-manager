import { LightningElement, api } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import cellWithPicklist from './cellWithPicklist';
import cellWithTextArea from './cellWithTextArea';

export default class CustomLightningDatatable extends LightningDatatable {
    static customTypes = {
        picklistCell: {
            template: cellWithPicklist,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'stageValue'],
        },
        textAreaCell: {
            template: cellWithTextArea,
            typeAttributes: ['value', 'stageValue']
        }
    };
}