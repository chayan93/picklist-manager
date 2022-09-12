/**
 * @description       : Helper class for new picklist field
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-11-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public inherited sharing class CreatePicklistFieldHelper {
    public static MetadataServiceForPicklistManager.MetadataPort service =
        MetadataServiceForPicklistManager.createService();
    public static PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse responseToSend =
        new PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse();

    /**
    * @description Creates a new Picklist field as per the specified details.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param details
    * @return PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse
    **/
    public static PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse createPicklistField(Object details){
        try{
            Map<String, Object> detailMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(details));
            Boolean isSorted = Boolean.valueOf(detailMap.get('isSorted'));
            String rtDetails = String.valueOf(detailMap.get('rtDetails'));
            String fieldDetail = String.valueOf(detailMap.get('fieldDetail'));
            String valueDetails = String.valueOf(detailMap.get('valueDetails'));
            String fieldAPIName = String.valueOf(detailMap.get('fieldAPIName'));
            Boolean isRestricted = Boolean.valueOf(detailMap.get('isRestricted'));
            String selectedObject = String.valueOf(detailMap.get('selectedObject'));
            String valueSetName = String.valueOf(detailMap.get('valueSetName'));
            String profileFLSDetails = String.valueOf(detailMap.get('profileFLSDetails'));

            valueSetName = (String)JSON.deserialize(valueSetName, String.class);
            fieldAPIName = (String)JSON.deserialize(fieldAPIName, String.class);
            selectedObject = (String)JSON.deserialize(selectedObject, String.class);
            String actualObject =
                selectedObject == 'Task' || selectedObject == 'Event' ? 'Activity' : selectedObject;

            MetadataServiceForPicklistManager.CustomField fieldToCreate =
                (MetadataServiceForPicklistManager.CustomField)JSON.deserialize(
                    fieldDetail, MetadataServiceForPicklistManager.CustomField.class
                );

            List<MetadataServiceForPicklistManager.CustomValue> valuesToCreate =
                (List<MetadataServiceForPicklistManager.CustomValue>)JSON.deserialize(
                    valueDetails, Type.forName('List<MetadataServiceForPicklistManager.CustomValue>')
                );

            MetadataServiceForPicklistManager.CustomField customField =
                new MetadataServiceForPicklistManager.CustomField();
            customField.fullName = actualObject + '.' + fieldAPIName;
            customField.label = fieldToCreate.label;
            customField.inlineHelpText = fieldToCreate.inlineHelpText;
            customField.type_x = fieldToCreate.type_x;
            customField.required = fieldToCreate.required;
            customField.description = fieldToCreate.description;
            customField.visibleLines = fieldToCreate.visibleLines;
            populateValues(customField, valueSetName, valuesToCreate, isSorted, isRestricted, selectedObject);

            List<MetadataServiceForPicklistManager.SaveResult> result = service.createMetadata(
                new List<MetadataServiceForPicklistManager.Metadata>{customField}
            );

            if(result[0].success){
                handlePostFieldCreationOperations(
                    selectedObject, fieldAPIName, actualObject, rtDetails, profileFLSDetails
                );
            }
            else{
                responseToSend.variant = 'error';
                responseToSend.message = 'The following error was encountered during field creation: ' +
                    result[0].errors[0].message;
            }
        }
        catch(Exception e) {
            responseToSend.message = 'The following error was encountered during field creation: ' +
                e.getMessage() + ' at ' + e.getLineNumber();
            responseToSend.variant = 'error';
        }

        return responseToSend;
    }

    private static void populateValues(
        MetadataServiceForPicklistManager.CustomField customField, String valueSetName,
        List<MetadataServiceForPicklistManager.CustomValue> valuesToCreate,
        Boolean isSorted, Boolean isRestricted, String selectedObject
    ){
        //Create the valueSetName_type_info for picklist type
        MetadataServiceForPicklistManager.ValueSet picklistValueSet =
        new MetadataServiceForPicklistManager.ValueSet();

        //set the valueSetDefinition
        if(String.isBlank(valueSetName)){
            List<MetadataServiceForPicklistManager.CustomValue> values =
                new List<MetadataServiceForPicklistManager.CustomValue>();
            for(MetadataServiceForPicklistManager.CustomValue eachValue : valuesToCreate){
                MetadataServiceForPicklistManager.CustomValue value =
                    new MetadataServiceForPicklistManager.CustomValue();
                value.fullName = eachValue.fullName;
                value.default_x = eachValue.default_x;
                value.description = '';
                value.isActive = true;
                value.label = eachValue.label;
                values.add(value);

                if(eachValue.default_x && selectedObject == 'User' && customField.required){
                    customField.defaultValue = '\'' + eachValue.fullName + '\'';
                }
            }

            //For each ValueSet, we have either ValueSetValuesDefinition or ValueSettings and some other attributes
            MetadataServiceForPicklistManager.ValueSetValuesDefinition valueDefinition =
                new MetadataServiceForPicklistManager.ValueSetValuesDefinition();
            //It will be list of CustomValue
            valueDefinition.value = values;
            valueDefinition.sorted = isSorted;

            picklistValueSet.valueSetDefinition = valueDefinition;
            picklistValueSet.restricted = isRestricted;
        }
        else{
            picklistValueSet.valueSetName = valueSetName;
            picklistValueSet.restricted = true;
        }

        //Set the valueSet for picklist type
        customField.valueSet = picklistValueSet;
    }

    /**
    * @description Handles the operations like Record Type & FLS update, post field creation.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param selectedObject
    * @param fieldAPIName
    * @param actualObject
    * @param rtDetails
    * @param profileFLSDetails
    **/
    private static void handlePostFieldCreationOperations(
        String selectedObject, String fieldAPIName, String actualObject, String rtDetails, String profileFLSDetails
    ){
        responseToSend.message = selectedObject + '.' + fieldAPIName + ' was created successfully.';
        responseToSend.variant = 'success';

        String urlToRedirectTo = PicklistManagerHelper.getFieldURL(fieldAPIName, actualObject);

        if(String.isNotBlank(urlToRedirectTo)){
            responseToSend.message += ' See the field {0}.';
            responseToSend.messageData = new List<Object>{new Map<String, Object>{
                'url' => urlToRedirectTo,
                'label' => 'here'
            }};
        }

        if(String.isNotBlank(rtDetails)){
            try{
                List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> rtInfo =
                    (List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>)JSON.deserialize(
                        rtDetails, Type.forName('List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo>')
                    );
                PicklistManagerHelper.handleRTUpdate(responseToSend, rtInfo, fieldAPIName, 'create');
            }
            catch(Exception e){
                responseToSend.variant = 'info';
                responseToSend.message += ' But Record Type(s) update wasn\'t successful.';
                System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
            }
        }

        if(String.isNotBlank(profileFLSDetails)){
            updateFieldLevelSecurity(profileFLSDetails, selectedObject, fieldAPIName);
        }
    }

    /**
    * @description Updates the field level security of the new picklist field
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param profileFLSDetails
    * @param objectName
    * @param fieldName
    **/
    @future
    private static void updateFieldLevelSecurity(String profileFLSDetails, String objectName, String fieldName){
        List<PicklistManagerWrappers.ProfileFLSDetails> flsDetails = (List<PicklistManagerWrappers.ProfileFLSDetails>)JSON.deserialize(
            profileFLSDetails, Type.forName('List<PicklistManagerWrappers.ProfileFLSDetails>')
        );
        List<FieldPermissions> flsToInsert = new List<FieldPermissions>();

        for(PicklistManagerWrappers.ProfileFLSDetails eachProfile : flsDetails){
            flsToInsert.add(new FieldPermissions(
                ParentId = eachProfile.value,
                SobjectType = objectName,
                Field = objectName + '.' + fieldName,
                PermissionsRead = eachProfile.readable,
                PermissionsEdit = !eachProfile.readOnly
            ));
        }

        Database.insert(new List<FieldPermissions>(new Set<FieldPermissions>(flsToInsert)), false);
    }
}