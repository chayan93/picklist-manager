/**
 * @description       : Batch class to update the record types
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-28-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public with sharing class UpdateRecordTypesBatch implements
    Database.Batchable<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>, Database.AllowsCallouts, Database.Stateful {

    String fieldAPIName;
    String selectedOperation;
    List<Map<String, Object>> updatedDetails;
    Record_Type_Update_Detail__c recordToUpdate;
    List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> recordTypeInfoList;

    /**
    * @description Parameterized constructor to take inputs from the calling class
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param recordTypeInfoList
    * @param fieldAPIName
    * @param selectedOperation
    * @param recordIdToUpdate
    * @param updatedDetails
    **/
    public UpdateRecordTypesBatch(
        List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> recordTypeInfoList,
        String fieldAPIName, String selectedOperation, String recordIdToUpdate,
        List<Map<String, Object>> updatedDetails
    ) {
        this.recordTypeInfoList = recordTypeInfoList;
        this.fieldAPIName = fieldAPIName;
        this.selectedOperation = selectedOperation;
        this.updatedDetails = updatedDetails;

        if(this.recordToUpdate == null){
            this.recordToUpdate = new Record_Type_Update_Detail__c(Id = recordIdToUpdate);
        }
    }

    /**
    * @description start method implementation.
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param BC
    * @return Iterable
    **/
    public Iterable<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> start(Database.BatchableContext BC) {
        return this.recordTypeInfoList;
    }

    /**
    * @description execute method implementation.
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param BC
    * @param recordTypeInfo
    **/
    public void execute(Database.BatchableContext BC, List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> recordTypeInfo) {
        String errorMessage = UpdateRecordTypePicklistValues.updateRecordType(recordTypeInfo[0], this.fieldAPIName, this.selectedOperation);

        Map<String, Object> rtUpdateDetails = new Map<String, Object>{
            'fullName' => recordTypeInfo[0].value, 'isSuccess' => String.isBlank(errorMessage)
        };
        if(rtUpdateDetails.get('isSuccess') == false){
            rtUpdateDetails.put('errorMessage', errorMessage);
        }

        this.updatedDetails.add(rtUpdateDetails);
    }

    /**
    * @description finish method implementation.
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param BC
    **/
    public void finish(Database.BatchableContext BC) {
        System.abortJob([SELECT Id FROM AsyncApexJob WHERE Id =: BC.getJobId() LIMIT 1].Id);

        this.recordToUpdate.Detail__c = JSON.serializePretty(this.updatedDetails, true);
        this.recordToUpdate.Status__c = 'Completed';
        update this.recordToUpdate;

        if(this.recordTypeInfoList.size() != 1){
            this.recordTypeInfoList.remove(0);
            System.scheduleBatch(
                new UpdateRecordTypesBatch(
                    this.recordTypeInfoList, this.fieldAPIName, this.selectedOperation, this.recordToUpdate.Id, this.updatedDetails
                ), this.recordTypeInfoList[0].value + ' Record Type Update', 1
            );
        }
    }
}