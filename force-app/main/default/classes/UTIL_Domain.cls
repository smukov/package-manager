/**
 * @description
 *
 * @author M.Smukov
 * @since  05-05-2021
 */
public with sharing class UTIL_Domain {
    @TestVisible
    private static final String BASE_API_ENDPOINT_VERSION = '/services/data/v52.0/';
    private static String baseApiUrl;
    public static String getBaseApiUrl() {
        if (String.isBlank(baseApiUrl)) {
            baseApiUrl = URL.getSalesforceBaseUrl().toExternalForm() + BASE_API_ENDPOINT_VERSION;
        }
        return baseApiUrl;
    }
}