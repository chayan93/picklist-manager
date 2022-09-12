/**
 * @description       : Test class for UpdatePicklistFieldHelper
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-29-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class UpdatePicklistFieldHelperTest {
    private static MetadataServiceForPicklistManager.readStandardValueSetResponse_element svsResult;
    private static MetadataServiceForPicklistManager.readBusinessProcessResponse_element bpResult;
    private static MetadataServiceForPicklistManager.readCustomFieldResponse_element cfResult;

    private static void readSVSResponseElement(){
        svsResult = new MetadataServiceForPicklistManager.readStandardValueSetResponse_element();
        svsResult.result =
            new MetadataServiceForPicklistManager.ReadStandardValueSetResult();
            svsResult.result.records = new List<MetadataServiceForPicklistManager.StandardValueSet>{
            new MetadataServiceForPicklistManager.StandardValueSet()
        };
        svsResult.result.records[0].standardValue =
            new List<MetadataServiceForPicklistManager.StandardValue>{
                new MetadataServiceForPicklistManager.StandardValue()
            };
        svsResult.result.records[0].standardValue[0].label = 'Test';
        svsResult.result.records[0].standardValue[0].fullName = 'Test';
    }

    private static void readBusinessProcessResponseElement(){
        bpResult = new MetadataServiceForPicklistManager.readBusinessProcessResponse_element();
        bpResult.result =
            new MetadataServiceForPicklistManager.ReadBusinessProcessResult();
            bpResult.result.records = new List<MetadataServiceForPicklistManager.BusinessProcess>{
            new MetadataServiceForPicklistManager.BusinessProcess()
        };
        bpResult.result.records[0].values = new List<MetadataServiceForPicklistManager.PicklistValue>{
            new MetadataServiceForPicklistManager.PicklistValue()
        };
        bpResult.result.records[0].values[0].fullName = 'Test';
    }

    private static void readCustomFieldResponseElement(){
        cfResult = new MetadataServiceForPicklistManager.readCustomFieldResponse_element();
        cfResult.result =
            new MetadataServiceForPicklistManager.ReadCustomFieldResult();
            cfResult.result.records = new List<MetadataServiceForPicklistManager.CustomField>{
            new MetadataServiceForPicklistManager.CustomField()
        };
        cfResult.result.records[0].valueSet = new MetadataServiceForPicklistManager.ValueSet();
        cfResult.result.records[0].valueSet.valueSetDefinition =
            new MetadataServiceForPicklistManager.ValueSetValuesDefinition();
        cfResult.result.records[0].valueSet.valueSetDefinition.value =
            new List<MetadataServiceForPicklistManager.CustomValue>{
                new MetadataServiceForPicklistManager.CustomValue()
            };
        cfResult.result.records[0].valueSet.valueSetDefinition.value[0].label = 'Test';
        cfResult.result.records[0].valueSet.valueSetDefinition.value[0].fullName = 'Test';
    }

    private static Map<String, Object> getDetails(){
        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo rtInfo =
            new PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo();
        rtInfo.label = 'Test';
        rtInfo.value = 'Test';
        rtInfo.defaultValue = 'Test';
        rtInfo.selectedValues = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Test', 'Test')
        };

        MetadataServiceForPicklistManager.CustomValue value =
            new MetadataServiceForPicklistManager.CustomValue();
        value.fullName = 'Test';
        value.default_x = true;
        value.description = '';
        value.isActive = true;
        value.label = 'Test';

        Map<String, Object> details = new Map<String, Object>();
        details.put(
            'valueDetails',
            JSON.serialize(new List<MetadataServiceForPicklistManager.CustomValue>{value})
        );
        details.put('fieldAPIName', '"Test"');
        details.put('selectedObject', '"Opportunity"');
        details.put('standardValueSetName', '"OpportunityStage"');
        details.put('isRecordTypeOrBusinessProcess', '"BP"');
        details.put(
            'recordTypeOrBusinessProcessInfo',
            JSON.serialize(new List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>{rtInfo})
        );

        return details;
    }

    private class WebServiceMockImpl implements WebServiceMock {
        public Object svsResult;
        public Object bpResult;
        public Object cfResult;
        public Boolean isSuccess;

        public WebServiceMockImpl(
            Object svsResult, Object bpResult, Object cfResult, Boolean isSuccess
        ){
            this.svsResult = svsResult;
            this.bpResult = bpResult;
            this.cfResult = cfResult;
            this.isSuccess = isSuccess;
        }

        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            if(request instanceof MetadataServiceForPicklistManager.readMetadata_element){
                switch on responseType{
                    when 'MetadataServiceForPicklistManager.readStandardValueSetResponse_element'{
                        response.put('response_x', this.svsResult);
                    }
                    when 'MetadataServiceForPicklistManager.readBusinessProcessResponse_element'{
                        response.put('response_x', this.bpResult);
                    }
                    when 'MetadataServiceForPicklistManager.readCustomFieldResponse_element'{
                        response.put('response_x', this.cfResult);
                    }
                }
            }
            else if(request instanceof MetadataServiceForPicklistManager.updateMetadata_element){
                MetadataServiceForPicklistManager.updateMetadataResponse_element successResult =
                    new MetadataServiceForPicklistManager.updateMetadataResponse_element();
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
    private static void getAdditionalPicklistInfoTestPositive(){
        Test.startTest();

        readSVSResponseElement();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(svsResult, null, null, null));
        PicklistManagerWrappers.AdditionalPicklistInfo response =
            UpdatePicklistFieldHelper.getAdditionalPicklistInfo('OpportunityStage');
        System.assert(response.forecastCategories.size() == 6, 'Forecast Categories Exist');

        response = UpdatePicklistFieldHelper.getAdditionalPicklistInfo('Industry');
        System.assert(response.columnStructure.size() == 3, '3 standard Columns');

        svsResult.result.records[0].standardValue[0].highPriority = true;
        response = UpdatePicklistFieldHelper.getAdditionalPicklistInfo('CasePriority');
        System.assert(response.columnStructure.size() == 4, '4 Columns Including HighPriority');

        Test.stopTest();
    }

    @IsTest
    private static void getAdditionalPicklistInfoTestNegative1(){
        Test.startTest();

        PicklistManagerWrappers.AdditionalPicklistInfo response =
            UpdatePicklistFieldHelper.getAdditionalPicklistInfo('OpportunityStage');
        System.assert(response.columnStructure.size() == 3, 'No Extra Column for OpportunityStage');

        Test.stopTest();
    }

    @IsTest
    private static void getExistingPicklistValuesTest(){
        Test.startTest();

        PicklistManagerWrappers.AdditionalPicklistInfo response =
            UpdatePicklistFieldHelper.getExistingPicklistValues('Opportunity', 'StageName');
        System.assert(!response.existingPicklistValues.isEmpty(), 'Retrieved StageNames');

        Test.stopTest();
    }

    @IsTest
    private static void updatePicklistFieldTestPositive(){
        Test.startTest();

        readSVSResponseElement();
        readBusinessProcessResponseElement();
        readCustomFieldResponseElement();

        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(
            svsResult, bpResult, cfResult, true
        ));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Map<String, Object> details = getDetails();

        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            UpdatePicklistFieldHelper.updatePicklistField(details);
        System.assert(response.variant == 'success', 'Success');

        details.put('standardValueSetName', '');
        details.put('isRecordTypeOrBusinessProcess', '"RT"');
        response = UpdatePicklistFieldHelper.updatePicklistField(details);
        System.assert(response.variant == 'success', 'Success');
        Test.stopTest();
    }

    @IsTest
    private static void updatePicklistFieldTestNegative1(){
        Test.startTest();

        readSVSResponseElement();
        readBusinessProcessResponseElement();
        readCustomFieldResponseElement();

        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(
            svsResult, bpResult, cfResult, false
        ));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Map<String, Object> details = getDetails();

        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            UpdatePicklistFieldHelper.updatePicklistField(details);
        System.assert(response.variant == 'error', 'Failure');
        Test.stopTest();
    }
}