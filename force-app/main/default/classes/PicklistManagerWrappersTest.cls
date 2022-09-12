/**
 * @description       : Test class for PicklistManagerWrappers
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class PicklistManagerWrappersTest {
    @IsTest
    private static void wrappersTest(){
        PicklistManagerWrappers.AdditionalPicklistInfo addInfo =
            new PicklistManagerWrappers.AdditionalPicklistInfo();
        addInfo.columnStructure.add(
            new PicklistManagerWrappers.StandardValueColumnStructure('test', 'test', 'test')
        );

        PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse createOrUpdateRes =
            new PicklistManagerWrappers.CreateOrUpdatePicklistFieldResponse();

        PicklistManagerWrappers.ObjectResponse objResponse =
            new PicklistManagerWrappers.ObjectResponse();
        objResponse.objectOptions = new List<PicklistManagerWrappers.SelectOption>{
            new PicklistManagerWrappers.SelectOption('2', '2')
        };
        objResponse.objectOptions[0].compareTo(
            (Object)new PicklistManagerWrappers.SelectOption('1', '1')
        );
        objResponse.objectOptions[0].compareTo(
            (Object)new PicklistManagerWrappers.SelectOption('2', '2')
        );
        objResponse.objectOptions[0].compareTo(
            (Object)new PicklistManagerWrappers.SelectOption('3', '3')
        );

        PicklistManagerWrappers.SelectedObjectResponse selectedObjResponse =
            new PicklistManagerWrappers.SelectedObjectResponse();
        selectedObjResponse.eligibleProfiles.add(
            new PicklistManagerWrappers.ProfileFLSDetails('test', 'test')
        );

        PicklistManagerWrappers.ToolingAPIQueryResponse tool =
            new PicklistManagerWrappers.ToolingAPIQueryResponse();
        tool.records = new List<PicklistManagerWrappers.Record>{
            new PicklistManagerWrappers.Record()
        };
        tool.records[0].attributes = new PicklistManagerWrappers.Attribute();
        tool.records[0].Metadata = new PicklistManagerWrappers.Metadata();
        tool.records[0].Metadata.picklistValues = new List<PicklistManagerWrappers.PicklistValue>{
            new PicklistManagerWrappers.PicklistValue()
        };
        tool.records[0].Metadata.picklistValues[0].values = new List<PicklistManagerWrappers.Value>{
            new PicklistManagerWrappers.Value()
        };

        System.assert(!tool.records[0].Metadata.picklistValues[0].values.isEmpty(), 'Non-Empty');
    }
}