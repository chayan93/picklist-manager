/**
 * @description       : Helper class for updating a picklist field
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-11-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public inherited sharing class UpdatePicklistFieldHelper {
    public static MetadataServiceForPicklistManager.MetadataPort service =
        MetadataServiceForPicklistManager.createService();

    /**
    * @description Retrieves additional information like column structure,
    * existingPicklistValues, forecast categories, etc.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param masterLabel
    * @return PicklistManagerWrappers.AdditionalPicklistInfo
    **/
    public static PicklistManagerWrappers.AdditionalPicklistInfo getAdditionalPicklistInfo(String masterLabel){
        PicklistManagerWrappers.AdditionalPicklistInfo responseToSend =
            new PicklistManagerWrappers.AdditionalPicklistInfo();

        Map<String, List<String>> standardValueSetToMultipleObjects =
            StandardValueSet.getStandardValueSetToMultipleObjectMapping();

        try{
            responseToSend.columnStructure.add(
                new PicklistManagerWrappers.StandardValueColumnStructure('Label', 'label', 'text')
            );
            responseToSend.columnStructure.add(
                new PicklistManagerWrappers.StandardValueColumnStructure('Value', 'fullName', 'text')
            );
            responseToSend.columnStructure.add(
                new PicklistManagerWrappers.StandardValueColumnStructure('Default', 'default_x', 'boolean')
            );

            switch on masterLabel {
                when 'OpportunityStage' {
                    responseToSend.forecastCategories = getOppForecaseCategory();
                    responseToSend.columnStructure.remove(2);
                    responseToSend.columnStructure.add(new PicklistManagerWrappers.StandardValueColumnStructure(
                        'Description', 'description', 'text'
                    ));
                }
                when else {
                    if(standardValueSetToMultipleObjects.containsKey(masterLabel)){
                        responseToSend.additionalRecordTypesToDisplay = PicklistManagerHelper.getRecordTypeInfo(
                            standardValueSetToMultipleObjects.get(masterLabel)
                        );
                    }
                }
            }

            getStandardValueSetDetails(responseToSend, masterLabel);
        }
        catch(Exception e){
            responseToSend = null;
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage());
        }

        return responseToSend;
    }

    /**
    * @description If the selected picklist is a standard field, get it's details from StandardValueSet
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param responseToSend
    * @param masterLabel
    **/
    private static void getStandardValueSetDetails(
        PicklistManagerWrappers.AdditionalPicklistInfo responseToSend, String masterLabel
    ){
        Set<String> fieldsToCheck = new Set<String>{
            'allowEmail', 'closed', 'converted', 'cssExposed', 'forecastCategory',
            'highPriority', 'probability', 'reverseRole', 'reviewed', 'won', 'description'
        };

        Set<String> booleanFields = new Set<String>{
            'allowEmail', 'closed', 'converted', 'cssExposed',
            'highPriority', 'reviewed', 'won'
        };

        List<MetadataServiceForPicklistManager.StandardValueSet> valueSet =
            (List<MetadataServiceForPicklistManager.StandardValueSet>)service.ReadMetadata(
                'StandardValueSet', new List<String>{masterLabel}
            ).getRecords();

        for(MetadataServiceForPicklistManager.StandardValue eachValue: valueSet[0].standardValue){
            Map<String, Object> valueMeta =
                (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(eachValue));

            switch on responseToSend.columnStructure.size() {
                when 0, 1, 2, 3 {
                    for(String eachKey : valueMeta.keySet()){
                        if(fieldsToCheck.contains(eachKey) && valueMeta.get(eachKey) != null){
                            List<String> splitLabel = eachKey.splitByCharacterTypeCamelCase();
                            splitLabel[0] = splitLabel[0].capitalize();
                            String label = eachKey == 'cssExposed' ? 'Available in Self-Service' : (
                                splitLabel.toString().replace('(', '').replaceAll(',', '').replace(')', '')
                            );
                            String type = booleanFields.contains(eachKey) ?
                                'boolean' : (eachKey == 'probability' ? 'number' : 'text');

                            responseToSend.columnStructure.add(
                                new PicklistManagerWrappers.StandardValueColumnStructure(label, eachKey, type)
                            );
                        }
                    }
                }
            }

            responseToSend.existingPicklistValues.add(new PicklistManagerWrappers.SelectOption(
                String.valueOf(valueMeta.get('label')), String.valueOf(valueMeta.get('fullName'))
            ));
        }
    }

    /**
    * @description Static Forecast Category options
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @return List<PicklistManagerWrappers.SelectOption>
    **/
    private static List<PicklistManagerWrappers.SelectOption> getOppForecaseCategory(){
        return new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('Omitted', 'Omitted'),
            new PicklistManagerWrappers.SelectOption('Pipeline', 'Pipeline'),
            new PicklistManagerWrappers.SelectOption('Best Case', 'BestCase'),
            new PicklistManagerWrappers.SelectOption('Most Likely', 'MostLikely'),
            new PicklistManagerWrappers.SelectOption('Commit', 'Forecast'),
            new PicklistManagerWrappers.SelectOption('Closed', 'Closed')
        };
    }

    /**
    * @description Fetches the existing picklist values for the specified picklist field
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param selectedObject
    * @param fieldAPIName
    * @return PicklistManagerWrappers.AdditionalPicklistInfo
    **/
    public static PicklistManagerWrappers.AdditionalPicklistInfo getExistingPicklistValues(
        String selectedObject, String fieldAPIName
    ){
        PicklistManagerWrappers.AdditionalPicklistInfo responseToSend =
            new PicklistManagerWrappers.AdditionalPicklistInfo();

        try{
            List<MetadataServiceForPicklistManager.CustomField> customFieldDefinition =
                (List<MetadataServiceForPicklistManager.CustomField>)service.ReadMetadata(
                    'CustomField', new List<String>{selectedObject + '.' + fieldAPIName}
                ).getRecords();
            responseToSend.globalValueSetName = customFieldDefinition[0].valueSet.valueSetName;

            if(String.isBlank(responseToSend.globalValueSetName)){
                for(
                    MetadataServiceForPicklistManager.CustomValue eachValue:
                    customFieldDefinition[0].valueSet.valueSetDefinition.value
                ){
                    responseToSend.existingPicklistValues.add(new PicklistManagerWrappers.SelectOption(
                        eachValue.label, eachValue.fullName
                    ));
                }
            }
        }
        catch(Exception e) {
            responseToSend = null;
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
        }

        return responseToSend;
    }

    /**
    * @description Updates the picklist field
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param details
    * @return PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse
    **/
    public static PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse updatePicklistField(Object details){
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse responseToSend =
            new PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse();

        try{
            Map<String, Object> detailMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(details));
            String valueDetails = String.valueOf(detailMap.get('valueDetails'));
            String fieldAPIName = String.valueOf(detailMap.get('fieldAPIName'));
            String selectedObject = String.valueOf(detailMap.get('selectedObject'));
            String standardValueSetName = String.valueOf(detailMap.get('standardValueSetName'));
            String isRecordTypeOrBusinessProcess = String.valueOf(detailMap.get('isRecordTypeOrBusinessProcess'));
            String recordTypeOrBusinessProcessInfo = String.valueOf(detailMap.get('recordTypeOrBusinessProcessInfo'));

            fieldAPIName = (String)JSON.deserialize(fieldAPIName, String.class);
            selectedObject = (String)JSON.deserialize(selectedObject, String.class);
            standardValueSetName = (String)JSON.deserialize(standardValueSetName, String.class);
            isRecordTypeOrBusinessProcess = (String)JSON.deserialize(isRecordTypeOrBusinessProcess, String.class);

            List<MetadataServiceForPicklistManager.SaveResult> result;
            if(String.isNotBlank(standardValueSetName)){
                result = updateStandardValueSet(
                    valueDetails, fieldAPIName, selectedObject, standardValueSetName
                );
            }
            else{
                result = updateCustomField(valueDetails, fieldAPIName, selectedObject);
            }

            if(result[0].success){
                responseToSend.message = selectedObject + '.' + fieldAPIName + ' was updated successfully.';
                responseToSend.variant = 'success';

                String urlToRedirectTo = PicklistManagerHelper.getFieldURL(fieldAPIName, selectedObject);
                if(String.isNotBlank(urlToRedirectTo)){
                    responseToSend.message += ' See the field {0}.';
                    responseToSend.messageData = new List<Object>{new Map<String, Object>{
                        'url' => urlToRedirectTo,
                        'label' => 'here'
                    }};
                }

                if(String.isNotBlank(isRecordTypeOrBusinessProcess)){
                    List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> rtOrBPDetails =
                        (List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>)JSON.deserialize(
                            recordTypeOrBusinessProcessInfo, Type.forName('List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>')
                        );

                    if(isRecordTypeOrBusinessProcess == 'BP'){
                        addValuesToBusinessProcess(responseToSend, rtOrBPDetails);
                    }
                    else{
                        try{
                            PicklistManagerHelper.handleRTUpdate(responseToSend, rtOrBPDetails, fieldAPIName, 'update');
                        }
                        catch(Exception e){
                            responseToSend.variant = 'error';
                            responseToSend.message += ' But Record Type(s) update wasn\'t successful.';
                            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
                        }
                    }
                }
            }
            else{
                responseToSend.variant = 'error';
                responseToSend.message = result[0].errors[0].message;
                System.debug(LOGGINGLEVEL.DEBUG, result[0].errors[0].message);
            }
        }
        catch(Exception e){
            responseToSend.message = 'The following error was encountered during field update: ' +
                e.getMessage() + ' at ' + e.getLineNumber();
            responseToSend.variant = 'error';
        }

        return responseToSend;
    }

    /**
    * @description If the specified field is a standard field, update the StandardValueSet
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param valueDetails
    * @param fieldAPIName
    * @param selectedObject
    * @param standardValueSetName
    * @return List<MetadataServiceForPicklistManager.SaveResult>
    **/
    private static List<MetadataServiceForPicklistManager.SaveResult> updateStandardValueSet(
        String valueDetails, String fieldAPIName, String selectedObject, String standardValueSetName
    ){
        List<MetadataServiceForPicklistManager.StandardValueSet> standardValueSetToUpdate =
            (List<MetadataServiceForPicklistManager.StandardValueSet>)service.ReadMetadata(
                'StandardValueSet', new List<String>{standardValueSetName}
            ).getRecords();
        standardValueSetToUpdate[0].standardValue = standardValueSetToUpdate[0].standardValue == null ?
            new List<MetadataServiceForPicklistManager.StandardValue>() :
            standardValueSetToUpdate[0].standardValue;

        List<MetadataServiceForPicklistManager.StandardValue> valuesToCreate =
            (List<MetadataServiceForPicklistManager.StandardValue>)JSON.deserialize(
                valueDetails, Type.forName('List<MetadataServiceForPicklistManager.StandardValue>')
            );
        List<MetadataServiceForPicklistManager.StandardValue> values =
            new List<MetadataServiceForPicklistManager.StandardValue>();

        for(MetadataServiceForPicklistManager.StandardValue eachValue : valuesToCreate){
            MetadataServiceForPicklistManager.StandardValue newValue =
                new MetadataServiceForPicklistManager.StandardValue();
            newValue.fullName = eachValue.fullName;
            newValue.label = eachValue.label;
            newValue.default_x = eachValue.default_x;
            newValue.isActive = true;
            newValue.allowEmail = eachValue.allowEmail;
            newValue.closed = eachValue.closed;
            newValue.converted = eachValue.converted;
            newValue.cssExposed = eachValue.cssExposed;
            newValue.forecastCategory = eachValue.forecastCategory;
            newValue.highPriority = eachValue.highPriority;
            newValue.probability = Integer.valueOf(eachValue.probability);
            newValue.reverseRole = eachValue.reverseRole;
            newValue.reviewed = eachValue.reviewed;
            newValue.won = eachValue.won;
            newValue.description = eachValue.description;
            values.add(newValue);

            if(eachValue.default_x){
                for(
                    MetadataServiceForPicklistManager.StandardValue eachExistingValue :
                    standardValueSetToUpdate[0].standardValue
                ){
                    eachExistingValue.default_x = false;
                }
            }
        }

        standardValueSetToUpdate[0].standardValue.addAll(values);

        return service.updateMetadata(standardValueSetToUpdate);
    }

    /**
    * @description If the specified field is a Custom Field field, update it.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param valueDetails
    * @param fieldAPIName
    * @param selectedObject
    * @return List<MetadataServiceForPicklistManager.SaveResult>
    **/
    private static List<MetadataServiceForPicklistManager.SaveResult> updateCustomField(
        String valueDetails, String fieldAPIName, String selectedObject
    ){
        List<MetadataServiceForPicklistManager.CustomField> fieldToUpdate =
            (List<MetadataServiceForPicklistManager.CustomField>)service.ReadMetadata(
                'CustomField', new List<String>{selectedObject + '.' + fieldAPIName}
            ).getRecords();

        List<MetadataServiceForPicklistManager.CustomValue> valuesToCreate =
            (List<MetadataServiceForPicklistManager.CustomValue>)JSON.deserialize(
                valueDetails, Type.forName('List<MetadataServiceForPicklistManager.CustomValue>')
            );
        List<MetadataServiceForPicklistManager.CustomValue> values =
            new List<MetadataServiceForPicklistManager.CustomValue>();

        for(MetadataServiceForPicklistManager.CustomValue eachValue : valuesToCreate){
            MetadataServiceForPicklistManager.CustomValue newValue =
                new MetadataServiceForPicklistManager.CustomValue();
            newValue.fullName = eachValue.fullName;
            newValue.label = eachValue.label;
            newValue.default_x = eachValue.default_x;
            newValue.isActive = true;
            values.add(newValue);

            if(eachValue.default_x){
                for(
                    MetadataServiceForPicklistManager.CustomValue eachExistingValue :
                    fieldToUpdate[0].valueSet.valueSetDefinition.value
                ){
                    eachExistingValue.default_x = false;
                }
            }
        }

        fieldToUpdate[0].valueSet.valueSetDefinition.value.addAll(values);
        return service.updateMetadata(fieldToUpdate);
    }

    /**
    * @description Add the selected values to the Business Process if the field is any of the following:
    * Case.Status, Lead.Status, Solution.Status, Opportunity.StageName
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param responseToSend
    * @param bpInfo
    **/
    private static void addValuesToBusinessProcess(
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse responseToSend,
        List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> bpInfo
    ){
        List<MetadataServiceForPicklistManager.PickListValue> newPicklistValues =
            new List<MetadataServiceForPicklistManager.PickListValue>();
        List<String> bpsToGet = new List<String>();
        Set<String> updatedDefaults = new Set<String>();

        for(PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo eachInfo : bpInfo){
            bpsToGet.add(eachInfo.value);

            for(PicklistManagerWrappers.SelectOption eachSelectedOption : eachInfo.selectedValues){
                MetadataServiceForPicklistManager.PickListValue objPickListValue =
                    new MetadataServiceForPicklistManager.PickListValue();
                objPickListValue.fullName = eachSelectedOption.value;
                objPickListValue.default_x = eachInfo.defaultValue == eachSelectedOption.value;
                newPicklistValues.add(objPickListValue);

                if(objPickListValue.default_x){
                    updatedDefaults.add(eachInfo.value);
                }
            }
        }

        //read businessProcess
        List<MetadataServiceForPicklistManager.BusinessProcess> businessProcesses =
            (List<MetadataServiceForPicklistManager.BusinessProcess>)
            service.ReadMetadata('BusinessProcess', bpsToGet).getRecords();

        //get picklist and it's values for the specified record types
        for(MetadataServiceForPicklistManager.BusinessProcess eachBP : businessProcesses){
            eachBP.values.addAll(newPicklistValues);
        }

        List<MetadataServiceForPicklistManager.SaveResult> result = service.updateMetadata(businessProcesses);
        if(result[0].success){
            responseToSend.variant = 'success';
            responseToSend.message += ' And the Business Process was updated successfully.';
        }
        else{
            responseToSend.variant = 'error';
            responseToSend.message = ' But, the Business Process update was not successful.';
            System.debug(LOGGINGLEVEL.DEBUG, result[0].errors[0].message);
        }
    }
}