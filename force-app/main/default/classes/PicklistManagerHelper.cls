/**
 * @description       : Helper class for PicklistManagerController class
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-11-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public inherited sharing class PicklistManagerHelper {
    /**
    * @description Returns the list of objects for selection.
    * If it's a create operation, returns all the objects on which field could be created.
    * If it's an update operation, returns all the objects on which picklist fields already exists.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param selectedOperation
    * @return PicklistManagerWrappers.ObjectResponse
    **/
    public static PicklistManagerWrappers.ObjectResponse getObjectOptions(String selectedOperation){
        PicklistManagerWrappers.ObjectResponse responseToSend = new PicklistManagerWrappers.ObjectResponse();

        try{
            responseToSend.objectOptions = new List<PicklistManagerWrappers.SelectOption>();
            Set<String> objectsWithPicklist = new Set<String>();
            responseToSend.standardValueSetMap = StandardValueSet.getObjectAndFieldToStandardValueSetMapping();

            for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().values()){
                Schema.DescribeSObjectResult sObjectResult = objTyp.getDescribe();
                String value = sObjectResult.getName();

                if(sObjectResult.isCreateable()){
                    Map<String, Schema.SObjectField> fieldMap = sObjectResult.fields.getMap();
                    for(String eachField : fieldMap.keySet()){
                        Schema.DescribeFieldResult fieldResult = fieldMap.get(eachField).getDescribe();

                        if((
                            fieldResult.GetType() == Schema.DisplayType.Picklist ||
                            fieldResult.GetType() == Schema.DisplayType.MultiPicklist
                        ) && (
                            fieldResult.isCustom() ||
                            responseToSend.standardValueSetMap.containsKey(value + '.' + fieldResult.getName())
                        )){
                            objectsWithPicklist.add(value);
                            break;
                        }
                    }
                }
            }

            getObjectDetailsFromToolingAPI(responseToSend, selectedOperation, objectsWithPicklist);
            getGlobalPicklistValueSets(responseToSend, selectedOperation);
        }
        catch(Exception e){
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage());
        }

        return responseToSend;
    }

    /**
    * @description Retrieves the object details from the Tooling API.
    * Neglecting DandBCompany object because field creation/value updation is not allowed.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param responseToSend
    * @param selectedOperation
    * @param objectsWithPicklist
    **/
    private static void getObjectDetailsFromToolingAPI(
        PicklistManagerWrappers.ObjectResponse responseToSend, String selectedOperation,
        Set<String> objectsWithPicklist
    ){
        String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        String resourcePath = '/services/data/v54.0/tooling/query/?q=';
        String query = 'SELECT+Label,QualifiedApiName+FROM+EntityDefinition+';
        query += 'WHERE+IsTriggerable+=+true+AND+IsCustomizable+=+true+AND+';
        query += 'IsLayoutable+=+true+AND+QualifiedApiName+!=+\'DandBCompany\'';
        String endpoint = baseURL + resourcePath + query;
        HttpResponse response = ToolingAPIService.callToolingAPI(endpoint, 'GET', null);

        if(response != null && response.getStatusCode() == 200){
            PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
                (PicklistManagerWrappers.ToolingAPIQueryResponse)JSON.deserialize(
                    response.getBody().removeStart('"').removeEnd('"'),
                    PicklistManagerWrappers.ToolingAPIQueryResponse.class
                );

            for(PicklistManagerWrappers.Record eachRecord : toolingResponse.records){
                if(selectedOperation == 'create' || objectsWithPicklist.contains(eachRecord.QualifiedApiName)){
                    responseToSend.objectOptions.add(new PicklistManagerWrappers.SelectOption(
                        eachRecord.Label + ' (' + eachRecord.QualifiedApiName + ')',
                        eachRecord.QualifiedApiName
                    ));
                }
            }

            responseToSend.objectOptions.sort();
        }
    }

    /**
    * @description Retrieves all the GlobalValueSets with Label and DeveloperName
    * @author chayan.batabyal@neuraflash.com | 09-07-2022
    * @param responseToSend
    * @param selectedOperation
    **/
    private static void getGlobalPicklistValueSets(
        PicklistManagerWrappers.ObjectResponse responseToSend, String selectedOperation
    ){
        if(selectedOperation == 'create'){
            String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
            String resourcePath = '/services/data/v54.0/tooling/query/?q=';
            String query = 'SELECT+MasterLabel,DeveloperName+FROM+GlobalValueSet+ORDER+BY+MasterLabel';
            String endpoint = baseURL + resourcePath + query;
            HttpResponse response = ToolingAPIService.callToolingAPI(endpoint, 'GET', null);

            if(response != null && response.getStatusCode() == 200){
                PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
                    (PicklistManagerWrappers.ToolingAPIQueryResponse)JSON.deserialize(
                        response.getBody().removeStart('"').removeEnd('"'),
                        PicklistManagerWrappers.ToolingAPIQueryResponse.class
                    );

                if(toolingResponse.records != null && !toolingResponse.records.isEmpty()){
                    responseToSend.globalValueSetOptions = new List<PicklistManagerWrappers.SelectOption>();
                    for(PicklistManagerWrappers.Record eachRecord : toolingResponse.records){
                        responseToSend.globalValueSetOptions.add(new PicklistManagerWrappers.SelectOption(
                            eachRecord.MasterLabel + ' (' + eachRecord.DeveloperName + ')',
                            eachRecord.DeveloperName
                        ));
                    }
                }
            }
        }
    }

    /**
    * @description Fetches the details like existing fields' API Names, record types,
    * business processes and eligible profiles for FLS.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param selectedObject
    * @return PicklistManagerWrappers.SelectedObjectResponse
    **/
    public static PicklistManagerWrappers.SelectedObjectResponse getSelectedObjectDetails(
        String selectedObject
    ){
        PicklistManagerWrappers.SelectedObjectResponse responseToSend =
            new PicklistManagerWrappers.SelectedObjectResponse();

        getExistingFieldAPINamesOfAnObject(selectedObject, responseToSend);
        responseToSend.rtInfo = getRecordTypeInfo(new List<String>{selectedObject});
        getBusinessProcessInfo(selectedObject, responseToSend);
        getEligibleProfiles(selectedObject, responseToSend);

        return responseToSend;
    }

    /**
    * @description Fetches the API names of all the fields of the specified object.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param objectAPIName
    * @param responseToSend
    **/
    private static void getExistingFieldAPINamesOfAnObject(
        String objectAPIName, PicklistManagerWrappers.SelectedObjectResponse responseToSend
    ){
        Map<String, String> standardValueSetMap = StandardValueSet.getObjectAndFieldToStandardValueSetMapping();
        Schema.DescribeSObjectResult sObjectResult =
            Schema.describeSObjects(new List<String>{objectAPIName})[0];
        Map<String, Schema.SObjectField> fieldMap = sObjectResult.fields.getMap();

        for(String eachField : fieldMap.keySet()){
            Schema.DescribeFieldResult fieldResult = fieldMap.get(eachField).getDescribe();
            responseToSend.existingFieldNames += (fieldResult.Name).toLowerCase().replace('__c', '') + ';';

            if((
                fieldResult.GetType() == Schema.DisplayType.Picklist ||
                fieldResult.GetType() == Schema.DisplayType.MultiPicklist
            ) && (
                fieldResult.isCustom() ||
                standardValueSetMap.containsKey(objectAPIName + '.' + fieldResult.Name)
            )){
                responseToSend.existingPicklistFields.add(new PicklistManagerWrappers.SelectOption(
                    fieldResult.Label + ' (' + fieldResult.Name + ')', fieldResult.Name
                ));
            }
        }
    }

    /**
    * @description Returns the active record types for the specified objects.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param objectNames
    * @return List<PicklistManagerWrappers.SelectOption>
    **/
    public static List<PicklistManagerWrappers.SelectOption> getRecordTypeInfo(List<String> objectNames){
        List<PicklistManagerWrappers.SelectOption> options =
            new List<PicklistManagerWrappers.SelectOption>();
        for(RecordType eachRT : [
            SELECT Name, DeveloperName, SObjectType FROM RecordType
            WHERE SObjectType IN : objectNames AND isActive = true
            ORDER BY SObjectType, Name
        ]){
            options.add(new PicklistManagerWrappers.SelectOption(
                eachRT.SObjectType + ' Record Type: ' + eachRT.Name + '(' + eachRT.DeveloperName + ')',
                eachRT.SObjectType + '.' + eachRT.DeveloperName
            ));
        }

        options.sort();
        return options;
    }

    /**
    * @description Fetches the active Business Processes for the specified object.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param objectAPIName
    * @param responseToSend
    **/
    private static void getBusinessProcessInfo(
        String objectAPIName, PicklistManagerWrappers.SelectedObjectResponse responseToSend
    ){
        for(BusinessProcess eachBP: [
            SELECT Name, IsActive, TableEnumOrId FROM BusinessProcess
            WHERE TableEnumOrId =: objectAPIName AND IsActive = true
        ]){
            responseToSend.businessProcessInfo.add(new PicklistManagerWrappers.SelectOption(
                'Business Process: ' + eachBP.Name, eachBP.TableEnumOrId + '.' + eachBP.Name
            ));
        }

        responseToSend.businessProcessInfo.sort();
    }

    /**
    * @description Fetches the ObjectPermissions first to check the profiles with the object read access.
    * If no details are found, fetch all the profile details.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param selectedObject
    * @param responseToSend
    **/
    private static void getEligibleProfiles(
        String selectedObject, PicklistManagerWrappers.SelectedObjectResponse responseToSend
    ){
        for(ObjectPermissions eachObjPermission : [
            SELECT ParentId, Parent.Profile.Name FROM ObjectPermissions
            WHERE SobjectType =: selectedObject
            AND PermissionsRead = true
            AND Parent.ProfileId != null
            ORDER BY Parent.Profile.Name
        ]){
            responseToSend.eligibleProfiles.add(new PicklistManagerWrappers.ProfileFLSDetails(
                eachObjPermission.Parent.Profile.Name, eachObjPermission.ParentId
            ));
        }

        if(responseToSend.eligibleProfiles.isEmpty()){
            for(PermissionSet eachPS : [
                SELECT Id, Name, Profile.Name, IsOwnedByProfile
                FROM PermissionSet
                WHERE IsOwnedByProfile = true
                ORDER BY Profile.Name
            ]){
                responseToSend.eligibleProfiles.add(new PicklistManagerWrappers.ProfileFLSDetails(
                    eachPS.Profile.Name, eachPS.Id
                ));
            }
        }
    }

    /**
    * @description Retrieves the values of the supplied globalValueSet through Tooling API
    * @author chayan.batabyal@neuraflash.com | 09-07-2022
    * @param valueSetName
    * @return List<PicklistManagerWrappers.SelectOption>
    **/
    public static List<PicklistManagerWrappers.SelectOption> getGlobalValueSetDetail(String valueSetName){
        List<PicklistManagerWrappers.SelectOption> options;

        try{
            String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
            String resourcePath = '/services/data/v54.0/tooling/query/?q=';
            String query = 'SELECT+Metadata+FROM+GlobalValueSet+WHERE+DeveloperName+=+\'' + valueSetName + '\'';
            String endpoint = baseURL + resourcePath + query;
            HttpResponse response = ToolingAPIService.callToolingAPI(endpoint, 'GET', null);

            if(response != null && response.getStatusCode() == 200){
                PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
                    (PicklistManagerWrappers.ToolingAPIQueryResponse)JSON.deserialize(
                        response.getBody().removeStart('"').removeEnd('"').replaceAll('"default":', '"default_x":'),
                        PicklistManagerWrappers.ToolingAPIQueryResponse.class
                    );

                if(!toolingResponse.records.isEmpty()){
                    options = new List<PicklistManagerWrappers.SelectOption>();
                    for(PicklistManagerWrappers.CustomValue eachValue : toolingResponse.records[0].Metadata.customValue){
                        if(eachValue.isActive != false){
                            options.add(new PicklistManagerWrappers.SelectOption(
                                eachValue.label, eachValue.valueName
                            ));
                        }
                    }
                }
            }
        }
        catch(Exception e) {
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
        }

        return options;
    }

    /**
    * @description Returns the field URL so that the user can check the details.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param fieldAPIName
    * @param selectedObject
    * @return String
    **/
    public static String getFieldURL(String fieldAPIName, String selectedObject){
        String fieldURL;

        try{
            String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();

            if(fieldAPIName.endsWith('__c')){
                String resourcePath = '/services/data/v54.0/tooling/query/?q=';
                String query = 'SELECT+Id,EntityDefinitionId+FROM+CustomField+WHERE+DeveloperName=\'[FIELD_NAME]\'+';
                query += 'AND+EntityDefinition.DeveloperName=\'[OBJECT_NAME]\'';
                query = query.replace('[FIELD_NAME]', fieldAPIName.removeEnd('__c'))
                    .replace('[OBJECT_NAME]', selectedObject.removeEnd('__c'));
                String endpoint = baseURL + resourcePath + query;
                HttpResponse response = ToolingAPIService.callToolingAPI(endpoint, 'GET', null);

                if(response != null && response.getStatusCode() == 200){
                    PicklistManagerWrappers.ToolingAPIQueryResponse toolingResponse =
                        (PicklistManagerWrappers.ToolingAPIQueryResponse)JSON.deserialize(
                            response.getBody().removeStart('"').removeEnd('"'),
                            PicklistManagerWrappers.ToolingAPIQueryResponse.class
                        );

                    fieldURL = baseURL + '/lightning/setup/ObjectManager/';
                    fieldURL += toolingResponse.records[0].EntityDefinitionId + '/FieldsAndRelationships/';
                    fieldURL += toolingResponse.records[0].Id + '/view';
                }
            }
            else{
                fieldURL = baseURL + '/lightning/setup/ObjectManager/' +
                    selectedObject + '/FieldsAndRelationships/' + fieldAPIName + '/view';
            }
        }
        catch(Exception e){
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage());
        }

        return fieldURL;
    }

    /**
    * @description Schedules the Record Type upadate batch class 1 minute from the current time.
    * @author chayan.batabyal@neuraflash.com | 08-28-2022
    * @param responseToSend
    * @param rtOrBPDetails
    * @param fieldAPIName
    * @param selectedOperation
    * @return String
    **/
    public static String handleRTUpdate(
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse responseToSend,
        List<PicklistManagerWrappers.RecordTypeOrBusinessProcessInfo> rtOrBPDetails,
        String fieldAPIName, String selectedOperation
    ){
        Record_Type_Update_Detail__c rtUpdateDetail = new Record_Type_Update_Detail__c();
        insert rtUpdateDetail;
        rtUpdateDetail = [SELECT Id, Name FROM Record_Type_Update_Detail__c WHERE Id =: rtUpdateDetail.Id];

        String counter = responseToSend.message.indexOf('{0}') == -1 ? '{0}' : '{1}';
        responseToSend.message += ' Now, we\'ll update the Record Type(s) through batch class.';
        responseToSend.message += ' Check the ' + counter + ' record to view the progress/details after some time.';
        responseToSend.messageData = responseToSend.messageData != null ?
            responseToSend.messageData : new List<Object>();
        responseToSend.messageData.add(new Map<String, Object>{
            'url' => System.URL.getSalesforceBaseUrl().toExternalForm() +
                '/lightning/r/Record_Type_Update_Detail__c/' + rtUpdateDetail.Id + '/view',
            'label' => rtUpdateDetail.Name
        });

        return System.scheduleBatch(
            new UpdateRecordTypesBatch(
                rtOrBPDetails, fieldAPIName, selectedOperation,
                rtUpdateDetail.Id, new List<Map<String, Object>>()
            ), rtOrBPDetails[0].value + ' Record Type Update', 1
        );
    }
}