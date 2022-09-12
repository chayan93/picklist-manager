/**
 * @description       : Test class for PicklistManagerHelper
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest
public class PicklistManagerHelperTest {
    private class HttpCalloutMockImpl implements HttpCalloutMock {
        String body;
        public HttpCalloutMockImpl(String body){
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    public static void getObjectOptionsTest(){
        Test.startTest();

        System.assert(
            PicklistManagerHelper.getObjectOptions('create').objectOptions.isEmpty(),
            'No Object options retrieved.'
        );

        PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
            new PicklistManagerWrappers.ToolingAPIQueryResponse();
        toolingResponse.records = new List<PicklistManagerWrappers.Record>{
            new PicklistManagerWrappers.Record()
		};
		Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl(JSON.serialize(toolingResponse)));
        System.assert(
            !PicklistManagerHelper.getObjectOptions('create').objectOptions.isEmpty(),
            'Object options retrieved.'
        );

        Test.stopTest();
    }

    @IsTest
    public static void getSelectedObjectDetailsTest(){
        Test.startTest();

        System.assert(
            !PicklistManagerHelper.getSelectedObjectDetails('Account').existingPicklistFields.isEmpty(),
            'Retrieved Existing Picklist Fields.'
        );

        Test.stopTest();
    }

    @IsTest
    public static void getFieldURLTest(){
        Test.startTest();

        System.assert(
            String.isNotBlank(PicklistManagerHelper.getFieldURL('Industry','Account')),
            'Retrieved Field\'s URL.'
        );

        PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
            new PicklistManagerWrappers.ToolingAPIQueryResponse();
        toolingResponse.records = new List<PicklistManagerWrappers.Record>{
            new PicklistManagerWrappers.Record()
		};

		Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl(JSON.serialize(toolingResponse)));

        System.assert(
            String.isNotBlank(PicklistManagerHelper.getFieldURL('URLTest__c','URLTest__c')),
            'Retrieved Field\'s URL.'
        );

        System.assert(String.isBlank(PicklistManagerHelper.getFieldURL(null,null)), 'Error.');

        Test.stopTest();
    }

    @IsTest
    public static void handleRTUpdateTest(){
        Test.startTest();

        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            new PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse();
        response.message = '';

        String jobId = PicklistManagerHelper.handleRTUpdate(
            response,
            new List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>{
                new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo()
            }, 'fieldAPIName', 'selectedOperation'
        );
        System.assert(String.isNotBlank(jobId), 'Job Scheduled.');

        Test.stopTest();
    }
}