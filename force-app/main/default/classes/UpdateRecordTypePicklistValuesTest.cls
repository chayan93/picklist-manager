/**
 * @description       : Test class for UpdateRecordTypePicklistValues
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-30-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class UpdateRecordTypePicklistValuesTest {
    private static MetadataServiceForPicklistManager.readRecordTypeResponse_element rtResult;

    private static void getReadRecordTypeResponseElement(){
        rtResult = new MetadataServiceForPicklistManager.readRecordTypeResponse_element();
        rtResult.result = new MetadataServiceForPicklistManager.ReadRecordTypeResult();
        rtResult.result.records = new List<MetadataServiceForPicklistManager.RecordType>{
            new MetadataServiceForPicklistManager.RecordType()
        };

        rtResult.result.records[0].label = 'Test';
        rtResult.result.records[0].fullName = 'Test';
        rtResult.result.records[0].active = true;
        rtResult.result.records[0].picklistValues =
            new List<MetadataServiceForPicklistManager.RecordTypePicklistValue>{
				new MetadataServiceForPicklistManager.RecordTypePicklistValue()
			};
		rtResult.result.records[0].picklistValues[0].picklist = 'LeadSource';
        rtResult.result.records[0].picklistValues[0].values =
            new List<MetadataServiceForPicklistManager.PicklistValue>{
                new MetadataServiceForPicklistManager.PicklistValue()
			};
		rtResult.result.records[0].picklistValues[0].values[0].fullName = 'Test';
    }

    private class WebServiceMockImpl implements WebServiceMock {
        public Object result;

        public WebServiceMockImpl(Object result){
            this.result = result;
        }

        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            response.put('response_x', result);
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
            res.setStatusCode(204);
            return res;
        }
    }

    @IsTest
    private static void updateRecordTypePositive(){
        Test.startTest();

        getReadRecordTypeResponseElement();

        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo rtInfo1 =
            new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo();
        rtInfo1.label = 'Test1';
        rtInfo1.value = 'Test1';
        rtInfo1.defaultValue = 'Test1';
        rtInfo1.selectedValues = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Test1', 'Test1')
        };

        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(rtResult));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        System.assert(String.isBlank(UpdateRecordTypePicklistValues.updateRecordType(
            rtInfo1, 'AccountSource', 'update'
        )), 'Success');

        Test.stopTest();
    }

    @IsTest
    private static void updateRecordTypeNegative(){
        Test.startTest();

        getReadRecordTypeResponseElement();

        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo rtInfo1 =
            new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo();
        rtInfo1.label = 'Test1';
        rtInfo1.value = 'Test1';
        rtInfo1.defaultValue = 'Test1';
        rtInfo1.selectedValues = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Test1', 'Test1')
        };

        UpdateRecordTypePicklistValues.updateRecordType(rtInfo1, 'AccountSource', 'update');

        rtResult.result.records[0].active = false;
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(rtResult));
        System.assert(String.isNotBlank(UpdateRecordTypePicklistValues.updateRecordType(
            rtInfo1, 'AccountSource', 'update'
        )), 'Failure');

        Test.stopTest();
    }
}