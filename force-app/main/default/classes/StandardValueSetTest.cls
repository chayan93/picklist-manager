/**
 * @description       : Test clas for StandardValueSet
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class StandardValueSetTest {
    @IsTest
    private static void getObjectAndFieldToStandardValueSetMappingTest(){
        Test.startTest();
        System.assert(
            !StandardValueSet.getObjectAndFieldToStandardValueSetMapping().keySet().isEmpty(),
            'Non-empty'
        );
        Test.stopTest();
    }

    @IsTest
    private static void getStandardValueSetToMultipleObjectMappingTest(){
        Test.startTest();
        System.assert(
            !StandardValueSet.getStandardValueSetToMultipleObjectMapping().keySet().isEmpty(),
            'Non-empty'
        );
        Test.stopTest();
    }
}