/**
 * @description       : Called from the UpdateRecordTypesBatch class, updates the RT, one at a time
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-28-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public without sharing class UpdateRecordTypePicklistValues {
    private static String errorMessage;

    /**
    * @description Update the RT, one at a time
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param recordTypeInfo
    * @param fieldAPIName
    * @param selectedOperation
    * @return String
    **/
    public static String updateRecordType(
        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo recordTypeInfo, String fieldAPIName, String selectedOperation
    ){
        try{
            List<String> splitDetails = recordTypeInfo.value.split('\\.');
            String recordTypeId = !Test.isRunningTest() ? [
                SELECT Id FROM RecordType
                WHERE SobjectType =: splitDetails[0] AND DeveloperName =: splitDetails[1]
            ].Id : '012000000000000AAA';

            PicklistManagerWrappers.Metadata rtToUpdate = getRecordType(recordTypeInfo.value);

            if(rtToUpdate != null){
                patchRecordType(rtToUpdate, recordTypeInfo, fieldAPIName, selectedOperation, recordTypeId);
            }
            else{
                errorMessage = 'Could not find the ' + recordTypeInfo.value + ' record type';
            }
        }
        catch(Exception e){
            errorMessage = e.getMessage();
            System.debug(LOGGINGLEVEL.DEBUG, errorMessage);

            if(errorMessage.toLowerCase().indexOf('timed out') != -1){
                errorMessage += '. This record type update may or may not succeed.';
            }
            else{
                errorMessage = 'Exception :: ' + errorMessage + ' at ' + e.getLineNumber();
            }
        }

        return errorMessage;
    }

    /**
    * @description Using metadata service, queries the record type
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param recordTypeFullName
    * @return PicklistManagerWrappers.Metadata
    **/
    private static PicklistManagerWrappers.Metadata getRecordType(String recordTypeFullName){
        PicklistManagerWrappers.Metadata rtMeta;
        MetadataServiceForPicklistManager.MetadataPort service = MetadataServiceForPicklistManager.createService();
        List<MetadataServiceForPicklistManager.RecordType> recordTypes = (List<MetadataServiceForPicklistManager.RecordType>)
            service.ReadMetadata('RecordType', new List<String>{recordTypeFullName}).getRecords();

        if(!recordTypes.isEmpty() && recordTypes[0].active){
            rtMeta = new PicklistManagerWrappers.Metadata();
            rtMeta.active = recordTypes[0].active;
            rtMeta.businessProcess = recordTypes[0].businessProcess;
            rtMeta.compactLayoutAssignment = recordTypes[0].compactLayoutAssignment;
            rtMeta.description = recordTypes[0].description;
            rtMeta.label = recordTypes[0].label;
            rtMeta.picklistValues = new List<PicklistManagerWrappers.PicklistValue>();

            for(MetadataServiceForPicklistManager.RecordTypePicklistValue rpk : recordTypes[0].picklistValues){
                PicklistManagerWrappers.PicklistValue pVal = new PicklistManagerWrappers.PicklistValue();
                pVal.picklist = rpk.picklist;
                pVal.values = new List<PicklistManagerWrappers.Value>();

                for(MetadataServiceForPicklistManager.PickListValue eachExistingValue : rpk.values){
                    PicklistManagerWrappers.Value val = new PicklistManagerWrappers.Value();
                    val.valueName = eachExistingValue.fullName;
                    val.default_x = eachExistingValue.default_x;
                    pVal.values.add(val);
                }

                rtMeta.picklistValues.add(pVal);
            }
        }

        return rtMeta;
    }

    /**
    * @description Patches the Record Type to update it.
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param rtToUpdate
    * @param recordTypeInfo
    * @param fieldAPIName
    * @param selectedOperation
    * @param recordTypeId
    **/
    private static void patchRecordType(
        PicklistManagerWrappers.Metadata rtToUpdate,
        PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo recordTypeInfo,
        String fieldAPIName, String selectedOperation, String recordTypeId
    ){
        List<PicklistManagerWrappers.Value> newValues = new List<PicklistManagerWrappers.Value>();
        Boolean isDefaultUpdated = false;

        for(PicklistManagerWrappers.SelectOption eachSelectedOption : recordTypeInfo.selectedValues){
            PicklistManagerWrappers.Value newValue = new PicklistManagerWrappers.Value();
            newValue.valueName = eachSelectedOption.value;
            newValue.default_x = eachSelectedOption.value.equalsIgnoreCase(recordTypeInfo.defaultValue);
            newValues.add(newValue);
            isDefaultUpdated = !isDefaultUpdated ? newValue.default_x : isDefaultUpdated;
        }

        String body = alterValues(rtToUpdate, newValues, fieldAPIName, selectedOperation, isDefaultUpdated);
        String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        String resourcePath = '/services/data/v54.0/tooling/sobjects/RecordType/' + recordTypeId;
        String endpoint = baseURL + resourcePath;
        HttpResponse response = ToolingAPIService.callToolingAPI(endpoint, 'PATCH', body);
        errorMessage = response.getStatusCode() == 204 ? '' : (response.getStatus() + ' ' + response.getBody());
    }

    /**
    * @description Alters the values and prepares the metadata JSON body for patching
    * @author chayan.batabyal@neuraflash.com | 08-27-2022
    * @param rtToUpdate
    * @param newValues
    * @param fieldAPIName
    * @param selectedOperation
    * @param isDefaultUpdated
    * @return String
    **/
    private static String alterValues(
        PicklistManagerWrappers.Metadata rtToUpdate, List<PicklistManagerWrappers.Value> newValues,
        String fieldAPIName, String selectedOperation, Boolean isDefaultUpdated
    ){
        for(PicklistManagerWrappers.PicklistValue eachPicklist : rtToUpdate.picklistValues){
            if(
                eachPicklist.picklist.equalsIgnoreCase(fieldAPIName) ||
                (fieldAPIName.endsWith('Source') && eachPicklist.picklist.endsWith('Source'))
            ){
                if(selectedOperation == 'create'){
                    eachPicklist.values = new List<PicklistManagerWrappers.Value>();
                }
                else if(isDefaultUpdated){
                    for(PicklistManagerWrappers.Value eachExistingValue : eachPicklist.values){
                        eachExistingValue.default_x = false;
                    }
                }

                eachPicklist.values.addAll(newValues);
            }
        }

        return '{"Metadata":' + JSON.serialize(rtToUpdate, true).replaceAll('"default_x"','"default"') + '}';
    }
}