/**
 * @description       : Test class for PicklistManagerController
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class PicklistManagerControllerTest {
    @IsTest
    public static void getObjectOptionsTest(){
        Test.startTest();
        System.assert(
            PicklistManagerController.getObjectOptions('create').objectOptions.isEmpty(),
            'No Object options retrieved.'
        );
        Test.stopTest();
    }

    @IsTest
    public static void getSelectedObjectDetailsTest(){
        Test.startTest();
        System.assert(
            !PicklistManagerController.getSelectedObjectDetails('Account').existingPicklistFields.isEmpty(),
            'Retrieved Existing Picklist Fields.'
        );
        Test.stopTest();
    }

    @IsTest
    private static void createPicklistFieldTest(){
        Test.startTest();
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            PicklistManagerController.createPicklistField(new Map<String, Object>());
        System.assert(response.variant.equalsIgnoreCase('error'), 'Error');
        Test.stopTest();
    }

    @IsTest
    private static void updatePicklistFieldTest(){
        Test.startTest();
        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse response =
            PicklistManagerController.updatePicklistField(new Map<String, Object>());
        System.assert(response.variant == 'error', 'Error');
        Test.stopTest();
    }

    @IsTest
    private static void getAdditionalDetailsForPicklistTest(){
        Test.startTest();

        PicklistManagerWrappers.AdditionalPicklistInfo response =
            PicklistManagerController.getAdditionalDetailsForPicklist('test', null, null);

        System.assert(!response.columnStructure.isEmpty(), 'Non-Empty Columns');

        response = PicklistManagerController.getAdditionalDetailsForPicklist(
            null, 'Account', 'Industry'
        );

        System.assert(!response.existingPicklistValues.isEmpty(), 'Non-Empty Response');
        Test.stopTest();
    }
}