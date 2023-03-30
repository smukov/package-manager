import { parseServerResponse } from "c/utilServer";
import { versionCompare } from "./utils";
import getPackageVersionsFromApex from "@salesforce/apex/PKGR_AppCnt.getPackageVersions";
import getPackageSubscribersFromApex from "@salesforce/apex/PKGR_AppCnt.getPackageSubscribers";
import submitPushRequestToApex from "@salesforce/apex/PKGR_AppCnt.submitPushRequest";
import getPushRequestJobsFromApex from "@salesforce/apex/PKGR_AppCnt.getPushRequestJobs";
import abortInitiatedPushJobFromApex from "@salesforce/apex/PKGR_AppCnt.abortInitiatedPushJob";
import abortInitiatedPushRequestFromApex from "@salesforce/apex/PKGR_AppCnt.abortInitiatedPushRequest";

async function getPackageVersions(packageId) {
  const results = await getPackageVersionsFromApex({ packageId });
  const { records } = parseServerResponse(results);

  // add additional columns to the records
  return records.map((r) => {
    return {
      ...r,
      version: `${r.MajorVersion}.${r.MinorVersion}.${r.PatchVersion}.${r.BuildNumber}`
    };
  });
}

async function getPackageSubscribers(selectedPackageVersion, packageVersions) {
  const {
    MetadataPackageId: packageId,
    version: selectedVersion,
    ReleaseState
  } = selectedPackageVersion;

  const isBetaPackageSelected = ReleaseState !== "Released";
  const results = await getPackageSubscribersFromApex({ packageId });
  const { records } = parseServerResponse(results);

  // add additional columns to the records
  return records.map((r) => {
    // get the installed version string
    const {
      version: installedVersion,
      ReleaseState: installedVersionReleaseState
    } = packageVersions.filter(
      (pVersion) => pVersion.Id === r.MetadataPackageVersionId
    )[0];

    let installedVersionIcon = "utility:dash";
    let actionLabel = "Up to date";
    let actionDisabled = true;

    const versionComparison = versionCompare(installedVersion, selectedVersion);
    if (versionComparison < 0) {
      installedVersionIcon = "utility:up";
      actionLabel = "Upgrade";
      actionDisabled = false;
    } else if (versionComparison > 0) {
      installedVersionIcon = "utility:down";
      actionLabel = "Downgrade";
      actionDisabled = false;
    }

    if (isBetaPackageSelected) {
      actionLabel = "Beta Selected";
      actionDisabled = true;
    } else if (installedVersionReleaseState === "Beta") {
      actionLabel = "Beta Installed";
      actionDisabled = true;
    }

    return {
      ...r,
      installedVersion,
      installedVersionIcon,
      storedActionLabel: actionLabel,
      actionLabel,
      actionDisabled
    };
  });
}

async function submitPushRequest(selectedPackageVersion, subscribers) {
  const { Id: packageVersionId } = selectedPackageVersion;

  // get only the enqueued subscribers
  const subscriberIds = subscribers.reduce((queue, r) => {
    if (r.enqueued) {
      queue.push(r.OrgKey);
    }
    return queue;
  }, []);

  const response = await submitPushRequestToApex({
    packageVersionId,
    subscriberIds
  });
  const { pushRequestId } = parseServerResponse(response);

  return pushRequestId;
}

async function getPushRequestJobs(pushRequestId, subscribers) {
  const results = await getPushRequestJobsFromApex({ pushRequestId });
  const {
    pushRequest: {
      records: [pushRequest]
    },
    pushJobs: { records: pushJobRecords }
  } = parseServerResponse(results);

  const pushJobs = pushJobRecords.map((job) => {
    // get the subscriber for this pushRequest
    const subscriber = subscribers.filter(
      (subscriber) => subscriber.OrgKey === job.SubscriberOrganizationKey
    )[0];

    const abortButtonDisabled =
      job.Status !== "Created" &&
      job.Status !== "In Progress" &&
      job.Status !== "Pending";

    return {
      ...job,
      abortButtonDisabled,
      OrgName: subscriber.OrgName,
      OrgType: subscriber.OrgType,
      OrgStatus: subscriber.OrgStatus,
      InstanceName: subscriber.InstanceName
    };
  });

  return {
    pushRequest,
    pushJobs
  };
}

async function abortInitiatedPushRequest(pushRequestId) {
  const results = await abortInitiatedPushRequestFromApex({ pushRequestId });
  console.log("abortInitiatedPushRequest", results);
  return results;
}

async function abortInitiatedPushJob(pushJobId) {
  const results = await abortInitiatedPushJobFromApex({ pushJobId });
  console.log("abortInitiatedPushJob", results);
  return results;
}

export {
  getPackageVersions,
  getPackageSubscribers,
  getPushRequestJobs,
  submitPushRequest,
  abortInitiatedPushJob,
  abortInitiatedPushRequest
};
