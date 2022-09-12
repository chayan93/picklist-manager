/**
 * @description       : Test class for UpdateRecordTypesBatch
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-30-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class UpdateRecordTypesBatchTest {
    @IsTest
    private static void testBatchClass(){
        Test.startTest();

        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo rtInfo1 =
            new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo();
        rtInfo1.label = 'Test1';
        rtInfo1.value = 'Test1';
        rtInfo1.defaultValue = 'Test1';
        rtInfo1.selectedValues = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Test1', 'Test1')
        };

        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo rtInfo2 =
            new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo();
        rtInfo2.label = 'Test2';
        rtInfo2.value = 'Test2';
        rtInfo2.defaultValue = 'Test2';
        rtInfo2.selectedValues = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Test2', 'Test2')
        };

        Record_Type_Update_Detail__c objRTUpdateDetail = new Record_Type_Update_Detail__c();
        insert objRTUpdateDetail;

        UpdateRecordTypesBatch batchable = new UpdateRecordTypesBatch(
            new List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>{rtInfo1, rtInfo2},
            'Test__c', 'create', objRTUpdateDetail.Id, new List<Map<String, Object>>()
        );
        Id jobId = Database.executeBatch(batchable);
        System.assert(![SELECT Id FROM AsyncApexJob WHERE Id =: jobId].isEmpty(), 'Job in queue.');

        Test.stopTest();

    }
}