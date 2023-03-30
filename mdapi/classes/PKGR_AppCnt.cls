/**
 * @description Controller for the Package Manager app
 * 
 * TODO Some of the query calls could be converted from REST API calls to simple SOQL queries. This would optimize the logic a lot. 
 * 
 * @author M.Smukov
 * @since 09-09-2021
 */
public with sharing class PKGR_AppCnt {
    // we have to mock the responses because:
    // a) we don't want to push package upgrades by accident during development
    // b) most of the calls are only valid inside of a DevHub, which is PROD
    @TestVisible
    private final static Boolean MOCK_RESPONSES = true;

    @AuraEnabled(cacheable=true)
    public static ServerResponse getPackages() {
        final String query = 'SELECT Id, Name, NamespacePrefix, PackageCategory FROM MetadataPackage ORDER BY Name ASC';

        return new ServerResponse(
            (Map<String, Object>) JSON.deserializeUntyped(
                MOCK_RESPONSES ? PKGR_MockResponses.getPackages() : makeApiQuery(query, true)
            )
        );
    }

    @AuraEnabled
    public static ServerResponse getPackageVersions(String packageId) {
        if (String.isBlank(packageId)) {
            return new ServerResponse('packageId cannot be blank');
        }

        final String query = String.format(
            'SELECT Id, MetadataPackageId, Name, ReleaseState, MajorVersion, MinorVersion, PatchVersion, BuildNumber, IsDeprecated ' +
            'FROM MetadataPackageVersion ' +
            'WHERE MetadataPackageId = \'\'{0}\'\'' +
            'ORDER BY MajorVersion DESC, MinorVersion DESC, PatchVersion DESC, BuildNumber DESC ',
            new List<String>{ packageId }
        );

        return new ServerResponse(
            (Map<String, Object>) JSON.deserializeUntyped(
                MOCK_RESPONSES ? PKGR_MockResponses.getPackageVersions() : makeApiQuery(query, true)
            )
        );
    }

    @AuraEnabled
    public static ServerResponse getPackageSubscribers(String packageId) {
        if (String.isBlank(packageId)) {
            return new ServerResponse('packageId cannot be blank');
        }

        final String query = String.format(
            'SELECT Id, MetadataPackageId, MetadataPackageVersionId, InstalledStatus, OrgKey, OrgName, OrgType, OrgStatus, InstanceName, ParentOrg ' +
            'FROM PackageSubscriber ' +
            'WHERE MetadataPackageId = \'\'{0}\'\'' +
            'AND InstalledStatus = \'\'i\'\'' +
            'ORDER BY OrgStatus, OrgName ',
            new List<String>{ packageId }
        );

        return new ServerResponse(
            (Map<String, Object>) JSON.deserializeUntyped(
                MOCK_RESPONSES ? PKGR_MockResponses.getPackageSubscribers() : makeApiQuery(query, false)
            )
        );
    }

    @AuraEnabled
    public static ServerResponse getPushRequestJobs(String pushRequestId) {
        if (String.isBlank(pushRequestId)) {
            return new ServerResponse('pushRequestId cannot be blank');
        }

        final String queryPushRequest = String.format(
            'SELECT Id, Status ' +
            'FROM PackagePushRequest ' +
            'WHERE Id = \'\'{0}\'\'',
            new List<String>{ pushRequestId }
        );
        Map<String, Object> pushRequest = (Map<String, Object>) JSON.deserializeUntyped(
            MOCK_RESPONSES ? PKGR_MockResponses.getPushRequest() : makeApiQuery(queryPushRequest, false)
        );

        final String queryPushJobs = String.format(
            'SELECT Id, SubscriberOrganizationKey, Status ' +
            'FROM PackagePushJob ' +
            'WHERE PackagePushRequestId = \'\'{0}\'\'' +
            'ORDER BY Id',
            new List<String>{ pushRequestId }
        );
        Map<String, Object> pushJobs = (Map<String, Object>) JSON.deserializeUntyped(
            MOCK_RESPONSES ? PKGR_MockResponses.getPushRequestJobs() : makeApiQuery(queryPushJobs, false)
        );

        return new ServerResponse(new Map<String, Object>{ 'pushRequest' => pushRequest, 'pushJobs' => pushJobs });
    }

    @AuraEnabled
    public static ServerResponse submitPushRequest(String packageVersionId, List<String> subscriberIds) {
        if (String.isBlank(packageVersionId)) {
            return new ServerResponse('packageVersionId cannot be blank');
        }

        if (subscriberIds == null || subscriberIds.isEmpty()) {
            return new ServerResponse('subscriberIds list cannot be empty');
        }

        // create a push request
        String packagePushRequestId = makePackagePushRequest(packageVersionId);

        // submit each org to the same push request
        for (String subId : subscriberIds) {
            makePackagePushJob(packagePushRequestId, subId);
        }

        // change the status to "Pending"
        initiatePushRequest(packagePushRequestId);

        return new ServerResponse(new Map<String, Object>{ 'pushRequestId' => packagePushRequestId });
    }

    @AuraEnabled
    public static ServerResponse abortInitiatedPushRequest(String pushRequestId) {
        if (String.isBlank(pushRequestId)) {
            return new ServerResponse('pushRequestId cannot be blank');
        }

        // change the status to "Canceled"
        String response = abortPushRequest(pushRequestId);

        return new ServerResponse(new Map<String, Object>{ 'response' => response });
    }

    @AuraEnabled
    public static ServerResponse abortInitiatedPushJob(String pushJobId) {
        if (String.isBlank(pushJobId)) {
            return new ServerResponse('pushJobId cannot be blank');
        }

        // change the status to "Canceled"
        String response = abortPushJob(pushJobId);

        return new ServerResponse(new Map<String, Object>{ 'response' => response });
    }

    private static String makeApiQuery(String query, Boolean isToolingApi) {
        final String endpoint = (isToolingApi ? 'tooling/' : '') + 'query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        final String method = 'GET';
        final String body = null;

        final String response = makeApiRequest(endpoint, method, body);

        return response;
    }

    private static String makePackagePushRequest(String packageVersionId) {
        final String endpoint = 'sobjects/packagepushrequest/';
        final String method = 'POST';
        final String body = JSON.serialize(new Map<String, String>{ 'PackageVersionId' => packageVersionId });

        final String response = MOCK_RESPONSES
            ? PKGR_MockResponses.makePackagePushRequest()
            : makeApiRequest(endpoint, method, body);

        return (String) ((Map<String, Object>) JSON.deserializeUntyped(response)).get('id');
    }

    private static String makePackagePushJob(String packagePushRequestId, String subscriberOrganizationKey) {
        final String endpoint = 'sobjects/packagepushjob/';
        final String method = 'POST';
        final String body = JSON.serialize(
            new Map<String, String>{
                'PackagePushRequestId' => packagePushRequestId,
                'SubscriberOrganizationKey' => subscriberOrganizationKey
            }
        );

        final String response = MOCK_RESPONSES
            ? PKGR_MockResponses.makePackagePushJob()
            : makeApiRequest(endpoint, method, body);

        return (String) ((Map<String, Object>) JSON.deserializeUntyped(response)).get('id');
    }

    private static String initiatePushRequest(String pushRequestId) {
        final String endpoint = 'sobjects/packagepushrequest/' + pushRequestId;
        final String method = 'PATCH';
        final String body = JSON.serialize(new Map<String, String>{ 'Status' => 'Pending' });

        final String response = MOCK_RESPONSES
            ? PKGR_MockResponses.initiatePushRequest()
            : makeApiRequest(endpoint, method, body);

        return response;
    }

    private static String abortPushRequest(String pushRequestId) {
        final String endpoint = 'sobjects/packagepushrequest/' + pushRequestId;
        final String method = 'PATCH';
        final String body = JSON.serialize(new Map<String, String>{ 'Status' => 'Canceled' });

        final String response = MOCK_RESPONSES
            ? PKGR_MockResponses.abortPushRequest()
            : makeApiRequest(endpoint, method, body);

        return response;
    }

    private static String abortPushJob(String pushJobId) {
        final String endpoint = 'sobjects/packagepushjob/' + pushJobId;
        final String method = 'PATCH';
        final String body = JSON.serialize(new Map<String, String>{ 'Status' => 'Canceled' });

        final String response = MOCK_RESPONSES
            ? PKGR_MockResponses.abortPushJob()
            : makeApiRequest(endpoint, method, body);

        return response;
    }

    /**
     * Make API requests back to Salesforce
     * @param  endpoint endpoint description
     * @param  method   method description
     * @param  body     body description
     * @return          return description
     */
    private static String makeApiRequest(String endpoint, String method, String body) {
        final HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + (Test.isRunningTest() ? '' : getSessionId()));
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(UTIL_Domain.getBaseApiUrl() + endpoint);
        req.setMethod(method);
        if (String.isNotBlank(body)) {
            req.setBody(body);
            System.debug('requestBody:');
            System.debug(body);
        }

        final Http h = new Http();
        final HttpResponse res = h.send(req);

        final String responseBody = res.getBody();
        System.debug('responseBody:');
        System.debug(responseBody);

        return responseBody;
    }

    /**
     * Get the Session Id that can make API requests, as normal LWC cannot do it.
     * If this stops working, we'll have to create Named Credentials instead.
     *
     * ! Never return this value back to Client !
     *
     * @return   API capable Session Id
     */
    private static String getSessionId() {
        String content = Page.ApiSessionId.getContent().toString();
        return (String) ((Map<String, Object>) JSON.deserializeUntyped(content)).get('sessionId');
    }
}