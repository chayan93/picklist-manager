/**
 * @description       : Test clas for ToolingAPIService
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-31-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@IsTest
public class ToolingAPIServiceTest {
    private class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void callToolingAPITest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        System.assert(
            ToolingAPIService.callToolingAPI('www.salesforce.com', 'GET', 'null').getStatusCode() == 200,
            'Status 200 OK'
        );
        Test.stopTest();
    }
}