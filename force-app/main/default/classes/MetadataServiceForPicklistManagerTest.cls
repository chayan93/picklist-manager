/**
 * @description       : Test class for MetadataServiceForPicklistManager
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest
public class MetadataServiceForPicklistManagerTest {
    private class WebServiceMockImpl implements WebServiceMock {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType
        ) {
            if(request instanceof  MetadataServiceForPicklistManager.createMetadata_element){
                response.put(
                    'response_x',
                    new MetadataServiceForPicklistManager.createMetadataResponse_element()
                );
            }
            else if(request instanceof MetadataServiceForPicklistManager.readMetadata_element){
                response.put(
                    'response_x',
                    new MetadataServiceForPicklistManager.readRecordTypeResponse_element()
                );
            }
            else if(request instanceof MetadataServiceForPicklistManager.updateMetadata_element){
                response.put(
                    'response_x',
                    new MetadataServiceForPicklistManager.updateMetadataResponse_element()
                );
            }
        }
    }

    @IsTest
    private static void generatedCodeFileBasedOperationsTest() {
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        Test.startTest();
        MetadataServiceForPicklistManager.MetadataPort metaDataPort =
            new MetadataServiceForPicklistManager.MetadataPort();
        MetadataServiceForPicklistManager.SaveResult[] result = metaDataPort.createMetadata(null);
        System.assert(result == null, 'Result null');
        metaDataPort.readMetadata('RecordType', null);
        metaDataPort.updateMetadata(null);
        Test.stopTest();
    }

    @IsTest
    private static void generatedCodeTypesTest() {
        Test.startTest();
        new MetadataServiceForPicklistManager();
        new MetadataServiceForPicklistManager.Error();
        new MetadataServiceForPicklistManager.ExtendedErrorDetails();
        new MetadataServiceForPicklistManager.AllOrNoneHeader_element();
        new MetadataServiceForPicklistManager.CallOptions_element();
        new MetadataServiceForPicklistManager.LogInfo();
        new MetadataServiceForPicklistManager.LookupFilter();
        new MetadataServiceForPicklistManager.FilterItem();
        new MetadataServiceForPicklistManager.BusinessProcess();
        new MetadataServiceForPicklistManager.RecordType();
        new MetadataServiceForPicklistManager.RecordTypePicklistValue();
        new MetadataServiceForPicklistManager.CustomField();
        new MetadataServiceForPicklistManager.DebuggingHeader_element();
        new MetadataServiceForPicklistManager.Metadata();
        new MetadataServiceForPicklistManager.SessionHeader_element();
        new MetadataServiceForPicklistManager.PicklistValue();
        new MetadataServiceForPicklistManager.DebuggingInfo_element();
        new MetadataServiceForPicklistManager.SaveResult();
        new MetadataServiceForPicklistManager.readMetadataResponse_element();
        new MetadataServiceForPicklistManager.createMetadataResponse_element();
        new MetadataServiceForPicklistManager.updateMetadata_element();
        new MetadataServiceForPicklistManager.updateMetadataResponse_element();
        new MetadataServiceForPicklistManager.createMetadata_element();
        new MetadataServiceForPicklistManager.readMetadata_element();
        new MetadataServiceForPicklistManager.ReadRecordTypeResult();
        new MetadataServiceForPicklistManager.readRecordTypeResponse_element();
        new MetadataServiceForPicklistManager.ReadPicklistValueResult();
        new MetadataServiceForPicklistManager.readPicklistValueResponse_element();
        new MetadataServiceForPicklistManager.ReadCustomFieldResult();
        new MetadataServiceForPicklistManager.readCustomFieldResponse_element();
        new MetadataServiceForPicklistManager.ReadBusinessProcessResult();
        new MetadataServiceForPicklistManager.readBusinessProcessResponse_element();
        new MetadataServiceForPicklistManager.ReadResult();
        new MetadataServiceForPicklistManager.GlobalPicklistValue();
        new MetadataServiceForPicklistManager.PicklistValue();
        new MetadataServiceForPicklistManager.GlobalValueSet();
        new MetadataServiceForPicklistManager.ValueSetValuesDefinition();
        new MetadataServiceForPicklistManager.ValueSet();
        new MetadataServiceForPicklistManager.StandardValueSet();
        new MetadataServiceForPicklistManager.StandardValue();
        MetadataServiceForPicklistManager.ValueSettings settings =
            new MetadataServiceForPicklistManager.ValueSettings();
        System.assert(settings.valueName == null, 'valueName null');
        Test.stopTest();
    }

    @IsTest
    private static void getRecordsTest() {
        Test.startTest();
        new MetadataServiceForPicklistManager.ReadCustomFieldResult().getRecords();
        new MetadataServiceForPicklistManager.ReadPicklistValueResult().getRecords();
        new MetadataServiceForPicklistManager.ReadRecordTypeResult().getRecords();
        new MetadataServiceForPicklistManager.ReadCustomValueResult().getRecords();
        new MetadataServiceForPicklistManager.ReadStandardValueResult().getRecords();
        new MetadataServiceForPicklistManager.ReadStandardValueSetResult().getRecords();
        new MetadataServiceForPicklistManager.ReadGlobalPicklistValueResult().getRecords();
        new MetadataServiceForPicklistManager.ReadGlobalValueSetResult().getRecords();
        List<MetadataServiceForPicklistManager.Metadata> records =
            new MetadataServiceForPicklistManager.ReadBusinessProcessResult().getRecords();
        System.assert(records == null, 'Records null');
        Test.stopTest();
    }

    @IsTest
    private static void getResultTest() {
        Test.startTest();
        new MetadataServiceForPicklistManager.readCustomFieldResponse_element().getResult();
        new MetadataServiceForPicklistManager.readPicklistValueResponse_element().getResult();
        new MetadataServiceForPicklistManager.readRecordTypeResponse_element().getResult();
        new MetadataServiceForPicklistManager.readCustomValueResponse_element().getResult();
        new MetadataServiceForPicklistManager.readStandardValueResponse_element().getResult();
        new MetadataServiceForPicklistManager.readStandardValueSetResponse_element().getResult();
        new MetadataServiceForPicklistManager.readGlobalPicklistValueResponse_element().getResult();
        new MetadataServiceForPicklistManager.readGlobalValueSetResponse_element().getResult();
        MetadataServiceForPicklistManager.IReadResult result =
            new MetadataServiceForPicklistManager.readBusinessProcessResponse_element().getResult();
        System.assert(result == null, 'Result null');
        Test.stopTest();
    }

    @IsTest
    private static void createServiceTest() {
        Test.startTest();
        MetadataServiceForPicklistManager.MetadataPort service =
            MetadataServiceForPicklistManager.createService();
        System.assert(service.timeout_x == 120000, 'Timeout is 120000');
        Test.stopTest();
    }
}