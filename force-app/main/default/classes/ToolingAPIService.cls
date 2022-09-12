/**
 * @description       : Tooling API Callout class
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 08-27-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public with sharing class ToolingAPIService {
    private static FINAL String SESSION_ID = apiEnabledSessionId();

    public static HttpResponse callToolingAPI(String endpoint, String method, String body){
        System.debug(LOGGINGLEVEL.DEBUG, 'endpoint :: ' + endpoint);
        System.debug(LOGGINGLEVEL.DEBUG, 'method :: ' + method);
        System.debug(LOGGINGLEVEL.DEBUG, 'body :: ' + body);

        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + SESSION_ID);
        req.setMethod(method);
        req.setEndpoint(endpoint);
        req.setTimeout(120000);

        if(String.isNotBlank(body)){
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
        }

        HttpResponse response = new Http().send(req);
        System.debug(LOGGINGLEVEL.DEBUG, 'response :: ' + response);
        return response;
    }

    private static String apiEnabledSessionId(){
        PageReference sessionPage = Page.SessionId;
        String vfContent = Test.isRunningTest() ?
            'SESSION_ID_START__XYZ__SESSION_ID_END' : sessionPage.getContent().toString();
        Integer startIndex = vfContent.indexOf('SESSION_ID_START') + 'SESSION_ID_START'.length();
        Integer endIndex = vfContent.indexOf('SESSION_ID_END');

        return vfContent.substring(startIndex, endIndex);
    }
}