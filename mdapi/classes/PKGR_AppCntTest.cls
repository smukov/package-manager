@isTest(isParallel=true)
private class PKGR_AppCntTest {
    @isTest
    static void shouldNotMockResponses() {
        System.assertEquals(
            false,
            PKGR_AppCnt.MOCK_RESPONSES,
            'MOCK_RESPONSES should only be TRUE during development phase'
        );
    }

    @isTest
    static void shouldReturnPackages() {
        // Arrange
        HttpResponse mockRes = UTIL_HttpCalloutMock.prepareResponse(200, PKGR_MockResponses.getPackages());
        Test.setMock(HttpCalloutMock.class, new UTIL_HttpCalloutMock(mockRes));

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.getPackages();
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assertEquals(18, (Integer) response.data.get('totalSize'));
    }

    @isTest
    static void shouldReturnPackageVersions() {
        // Arrange
        HttpResponse mockRes = UTIL_HttpCalloutMock.prepareResponse(200, PKGR_MockResponses.getPackageVersions());
        Test.setMock(HttpCalloutMock.class, new UTIL_HttpCalloutMock(mockRes));

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.getPackageVersions('03369000000S2SBAA0');
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assertEquals(9, (Integer) response.data.get('totalSize'));
    }

    @isTest
    static void shouldReturnPackageSubscribers() {
        // Arrange
        HttpResponse mockRes = UTIL_HttpCalloutMock.prepareResponse(200, PKGR_MockResponses.getPackageSubscribers());
        Test.setMock(HttpCalloutMock.class, new UTIL_HttpCalloutMock(mockRes));

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.getPackageSubscribers('03369000000S2SBAA0');
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assertEquals(4, (Integer) response.data.get('totalSize'));
    }

    @isTest
    static void shouldReturnPushRequestJobs() {
        // Arrange
        Test.setMock(
            HttpCalloutMock.class,
            new UTIL_HttpCalloutMock(
                null,
                new Map<String, HttpResponse>{
                    UTIL_Domain.getBaseApiUrl() +
                    'query/?q=SELECT+Id%2C+Status+FROM+PackagePushRequest+WHERE+Id+%3D+%270DV69000000ChjQ%27' => UTIL_HttpCalloutMock.prepareResponse(
                        200,
                        PKGR_MockResponses.getPushRequest()
                    ),
                    UTIL_Domain.getBaseApiUrl() +
                    'query/?q=SELECT+Id%2C+SubscriberOrganizationKey%2C+Status+FROM+PackagePushJob+WHERE+PackagePushRequestId+%3D+%270DV69000000ChjQ%27ORDER+BY+Id' => UTIL_HttpCalloutMock.prepareResponse(
                        200,
                        PKGR_MockResponses.getPushRequestJobs()
                    )
                }
            )
        );

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.getPushRequestJobs('0DV69000000ChjQ');
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assertEquals(1, (Integer) ((Map<String, Object>) response.data.get('pushRequest')).get('totalSize'));
        System.assertEquals(2, (Integer) ((Map<String, Object>) response.data.get('pushJobs')).get('totalSize'));
    }

    @isTest
    static void shouldSubmitPushRequest() {
        Test.setMock(
            HttpCalloutMock.class,
            new UTIL_HttpCalloutMock(
                null,
                new Map<String, HttpResponse>{
                    UTIL_Domain.getBaseApiUrl() +
                    'sobjects/packagepushrequest/' => UTIL_HttpCalloutMock.prepareResponse(
                        200,
                        PKGR_MockResponses.makePackagePushRequest()
                    ),
                    UTIL_Domain.getBaseApiUrl() + 'sobjects/packagepushjob/' => UTIL_HttpCalloutMock.prepareResponse(
                        200,
                        PKGR_MockResponses.makePackagePushJob()
                    ),
                    UTIL_Domain.getBaseApiUrl() +
                    'sobjects/packagepushrequest/0DV69000000ChjQ' => UTIL_HttpCalloutMock.prepareResponse(
                        204,
                        PKGR_MockResponses.initiatePushRequest()
                    )
                }
            )
        );

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.submitPushRequest(
            '0DV69000000ChjQ',
            new List<String>{ '00D5E0000109oOg', '00D0D0000108edA' }
        );
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assertEquals('0DV69000000ChjQ', (String) response.data.get('pushRequestId'));
    }

    @isTest
    static void shouldAbortInitiatedPushRequest() {
        // Arrange
        HttpResponse mockRes = UTIL_HttpCalloutMock.prepareResponse(204, PKGR_MockResponses.abortPushRequest());
        Test.setMock(HttpCalloutMock.class, new UTIL_HttpCalloutMock(mockRes));

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.abortInitiatedPushRequest('0DV69000000ChjQ');
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assert(String.isBlank((String) response.data.get('response')));
    }

    @isTest
    static void shouldAbortInitiatedPushJob() {
        // Arrange
        HttpResponse mockRes = UTIL_HttpCalloutMock.prepareResponse(204, PKGR_MockResponses.abortPushJob());
        Test.setMock(HttpCalloutMock.class, new UTIL_HttpCalloutMock(mockRes));

        // Act
        Test.startTest();
        ServerResponse response = PKGR_AppCnt.abortInitiatedPushJob('0DX69000000NEdp');
        Test.stopTest();

        //Assert
        System.assert(response.success);
        System.assert(String.isBlank((String) response.data.get('response')));
    }

    @isTest
    static void shouldTestDefensiveCoding() {
        // Act & Assert
        {
            ServerResponse response = PKGR_AppCnt.getPackageVersions('');
            System.assertEquals(false, response.success);
            System.assertEquals('packageId cannot be blank', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.getPackageSubscribers('');
            System.assertEquals(false, response.success);
            System.assertEquals('packageId cannot be blank', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.getPushRequestJobs('');
            System.assertEquals(false, response.success);
            System.assertEquals('pushRequestId cannot be blank', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.submitPushRequest('', null);
            System.assertEquals(false, response.success);
            System.assertEquals('packageVersionId cannot be blank', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.submitPushRequest('0DV69000000ChjQ', null);
            System.assertEquals(false, response.success);
            System.assertEquals('subscriberIds list cannot be empty', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.submitPushRequest('0DV69000000ChjQ', new List<String>());
            System.assertEquals(false, response.success);
            System.assertEquals('subscriberIds list cannot be empty', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.abortInitiatedPushRequest(null);
            System.assertEquals(false, response.success);
            System.assertEquals('pushRequestId cannot be blank', response.error.get('message'));
        }
        {
            ServerResponse response = PKGR_AppCnt.abortInitiatedPushJob(null);
            System.assertEquals(false, response.success);
            System.assertEquals('pushJobId cannot be blank', response.error.get('message'));
        }
    }
}