/**
 * @description       : Test class for CreatePicklistFieldHelper
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-02-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class CreatePicklistFieldHelperTest {
    private static Map<String, Object> getDetails(){
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

        MetadataServiceForPicklistManager.CustomField customField =
            new MetadataServiceForPicklistManager.CustomField();
        customField.fullName = 'Test.Test__c';
        customField.label = 'Test';
        customField.required = true;

        MetadataServiceForPicklistManager.CustomValue value =
            new MetadataServiceForPicklistManager.CustomValue();
        value.fullName = 'Test';
        value.default_x = true;
        value.description = '';
        value.isActive = true;
        value.label = 'Test';

        PicklistManagerWrappers.ProfileFLSDetails fls = new PicklistManagerWrappers.ProfileFLSDetails(
            'Test', [SELECT Id FROM PermissionSet WHERE ProfileId =: UserInfo.getProfileId()].Id
        );
        fls.readable = false;
        fls.readOnly = false;

        Map<String, Object> details = new Map<String, Object>();
        details.put('isSorted', false);
        details.put('rtDetails', JSON.serialize(
            new List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>{rtInfo1, rtInfo2}
        ));
        details.put('fieldDetail', JSON.serialize(customField));
        details.put(
            'valueDetails',
            JSON.serialize(new List<MetadataServiceForPicklistManager.CustomValue>{value})
        );
        details.put('fieldAPIName', '"Test__c"');
        details.put('isRestricted', true);
        details.put('selectedObject', '"User"');
        details.put(
            'profileFLSDetails',
            JSON.serialize(new List<PicklistManagerWrappers.ProfileFLSDetails>{fls})
        );

        return details;
    }

    private class WebServiceMockImpl implements WebServiceMock {
        public Boolean isSuccess;

        public WebServiceMockImpl(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }

        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            if(request instanceof  MetadataServiceForPicklistManager.createMetadata_element){
                MetadataServiceForPicklistManager.createMetadataResponse_element successResult =
                    new MetadataServiceForPicklistManager.createMetadataResponse_element();
                successResult.result = new List<MetadataServiceForPicklistManager.SaveResult>();
                successResult.result.add(new MetadataServiceForPicklistManager.SaveResult());
                successResult.result[0].success = this.isSuccess;
                response.put('response_x', successResult);
            }
        }
    }

    private class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
                new PicklistManagerWrappers.ToolingAPIQueryResponse();
            toolingResponse.records = new List<PicklistManagerWrappers.Record>{
                new PicklistManagerWrappers.Record()
            };
            HttpResponse res = new HttpResponse();
            res.setBody(JSON.serialize(toolingResponse));
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void createPicklistFieldTestPositive(){
        Test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(true));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            CreatePicklistFieldHelper.createPicklistField(getDetails());
        System.assert(response.variant.equalsIgnoreCase('success'), 'Success');
        Test.stopTest();
    }

    @IsTest
    private static void createPicklistFieldTestNegative1(){
        Test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(false));
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            CreatePicklistFieldHelper.createPicklistField(getDetails());
        System.assert(response.variant.equalsIgnoreCase('error'), 'Failure');
        Test.stopTest();
    }

    @IsTest
    private static void createPicklistFieldTestNegative2(){
        Map<String, Object> details = getDetails();
        details.put('rtDetails', 'abc');
        Test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(true));
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            CreatePicklistFieldHelper.createPicklistField(details);
        System.assert(response.variant.equalsIgnoreCase('info'), 'Partial Success');
        Test.stopTest();
    }
}