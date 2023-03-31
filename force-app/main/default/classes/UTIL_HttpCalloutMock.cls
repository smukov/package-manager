/**
 * @description Utility class for creating mocked Http Callout responses
 *
 * @author M.Smukov
 * @since  13-09-2019
 */
@isTest
global class UTIL_HttpCalloutMock implements HttpCalloutMock {
    // default response that will be used if no adequate response  is found in responseMap
    private HttpResponse defaultResponse;
    // endpoint -> response map
    private Map<String, HttpResponse> responseMap;

    global UTIL_HttpCalloutMock(HttpResponse defaultResponse, Map<String, HttpResponse> responseMap) {
        this.defaultResponse = defaultResponse;
        this.responseMap = responseMap;
    }

    global UTIL_HttpCalloutMock(HttpResponse defaultResponse) {
        this(defaultResponse, new Map<String, HttpResponse>());
    }

    /**
     * This is called implicitly by salesforce
     */
    global HTTPResponse respond(HTTPRequest req) {
        String endpoint = req.getEndpoint();

        HttpResponse res = responseMap.get(endpoint);
        return res != null ? res : this.defaultResponse;
    }

    /**
     * Prepare an HTTP Response
     * @param  statusCode response status code
     * @param  body       response body
     * @return            return HttpResponse
     */
    global static HttpResponse prepareResponse(Integer statusCode, String body) {
        return prepareResponse(statusCode, body, new Map<String, String>());
    }

    /**
     * Preapre an HTTP Response
     * @param  statusCode response status code
     * @param  body       response body
     * @param  headers    response headers
     * @return            return HttpResponse
     */
    global static HttpResponse prepareResponse(Integer statusCode, String body, Map<String, String> headers) {
        HttpResponse res = new HttpResponse();

        for (String key : headers.keySet()) {
            res.setHeader(key, headers.get(key));
        }

        res.setBody(body);
        res.setStatusCode(statusCode);

        return res;
    }
}