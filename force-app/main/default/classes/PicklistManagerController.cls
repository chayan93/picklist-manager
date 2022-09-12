/**
 * @description       : Controller class for the PicklistManager LWC
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-11-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public without sharing class PicklistManagerController{
    @AuraEnabled
    public static PicklistManagerWrappers.ObjectResponse getObjectOptions(String selectedOperation){
        return PicklistManagerHelper.getObjectOptions(selectedOperation);
    }

    @AuraEnabled
    public static PicklistManagerWrappers.SelectedObjectResponse getSelectedObjectDetails(String selectedObject){
        return PicklistManagerHelper.getSelectedObjectDetails(selectedObject);
    }

    @AuraEnabled
    public static List<PicklistManagerWrappers.SelectOption> getGlobalValueSetDetail(String valueSetName){
        return PicklistManagerHelper.getGlobalValueSetDetail(valueSetName);
    }

    @AuraEnabled
    public static PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse createPicklistField(Object details){
        return CreatePicklistFieldHelper.createPicklistField(details);
    }

    @AuraEnabled
    public static PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse updatePicklistField(Object details){
        return UpdatePicklistFieldHelper.updatePicklistField(details);
    }

    @AuraEnabled
    public static PicklistManagerWrappers.AdditionalPicklistInfo getAdditionalDetailsForPicklist(
        String masterLabel, String selectedObject, String fieldAPIName
    ){
        if(String.isNotBlank(masterLabel)){
            return UpdatePicklistFieldHelper.getAdditionalPicklistInfo(masterLabel);
        }

        return UpdatePicklistFieldHelper.getExistingPicklistValues(selectedObject, fieldAPIName);
    }
}