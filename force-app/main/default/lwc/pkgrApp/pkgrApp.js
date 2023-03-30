import { LightningElement, track } from "lwc";
import { setTabLabelAndIcon } from "c/utilSalesforceConsole";
import {
  getPackageVersions,
  getPackageSubscribers,
  getPushRequestJobs,
  submitPushRequest,
  abortInitiatedPushJob,
  abortInitiatedPushRequest
} from "./server";

export default class PkgrApp extends LightningElement {
  label = {
    packageManager: "Package Manager",
    packages: "Packages",
    packageVersions: "Package Versions",
    subscribers: "Subscribers",
    pushRequest: "Push Request"
  };

  @track disableSubmitPushRequestButton = false;
  @track disableAbortPushRequestButton = false;
  @track disableRefreshPushRequestStatusButton = false;

  @track selectedPackage;
  @track packageVersions;
  @track selectedPackageVersion;
  @track subscribers;
  @track pushRequest;
  @track pushJobs;

  get subtitle() {
    let text = "";
    if (this.isStepOne) {
      text = this.label.packages;
    } else if (this.isStepTwo) {
      text = this.label.packageVersions;
    } else if (this.isStepThree) {
      text = this.label.subscribers;
    } else if (this.isStepFour) {
      text = this.label.pushRequest;
    }

    return `- ${text}`;
  }

  get isStepOne() {
    return !this.selectedPackage;
  }

  get isStepTwo() {
    return this.selectedPackage && !this.selectedPackageVersion;
  }

  get isStepThree() {
    return (
      this.selectedPackage && this.selectedPackageVersion && !this.pushRequest
    );
  }

  get isStepFour() {
    return this.pushRequest && this.pushJobs;
  }

  get isSubmitPushRequestDisabled() {
    // disable submit button if there are no enqueued subscribers,
    // or if the button is disabled because there is an in progress request

    return (
      !this.subscribers ||
      !this.subscribers.some((s) => s.enqueued) ||
      this.disableSubmitPushRequestButton
    );
  }

  get isAbortPushRequestDisabled() {
    return (
      this.disableAbortPushRequestButton ||
      (this.pushRequest &&
        (this.pushRequest.Status === "Succeeded" ||
          this.pushRequest.Status === "Canceled" ||
          this.pushRequest.Status === "Failed"))
    );
  }

  get pushRequestBreadcrump() {
    if (!this.pushRequest) {
      return "";
    }
    return `{Id: ${this.pushRequest.Id}, Status: ${this.pushRequest.Status}}`;
  }

  async connectedCallback() {
    // setting tab and icon here with timeout because, if i execute immediatelly, it will
    // fire too early and set the tab and icon for the wrong tab
    setTimeout(() => {
      setTabLabelAndIcon(this.label.packageManager, "custom:custom63");
    }, 500);
  }

  handleNavigateToPackages() {
    this.handleNavigateToPackageVersions();
    this.selectedPackage = null;
  }

  handleNavigateToPackageVersions() {
    this.handleNavigateToPackageSubscribers();
    this.selectedPackageVersion = null;
  }

  handleNavigateToPackageSubscribers() {
    this.pushRequest = null;
    this.pushJobs = null;
  }

  async handleOpenPackage(event) {
    const { unlockedPackage } = event.detail;
    this.selectedPackage = unlockedPackage;

    this.packageVersions = await getPackageVersions(this.selectedPackage.Id);
  }

  async handleOpenPackageVersion(event) {
    const { unlockedPackageVersion } = event.detail;
    this.selectedPackageVersion = unlockedPackageVersion;

    this.subscribers = await getPackageSubscribers(
      this.selectedPackageVersion,
      this.packageVersions
    );
  }

  handleEnqueueSubscriberToggle() {
    this.subscribers = this.subscribers.map((r) => {
      return {
        ...r
      };
    });
  }

  async handleSubmitPushRequest() {
    this.disableSubmitPushRequestButton = true;

    const pushRequestId = await submitPushRequest(
      this.selectedPackageVersion,
      this.subscribers
    );

    this.pushRequest = {
      Id: pushRequestId
    };

    await this.handleRefreshPushRequestStatus();
    this.disableSubmitPushRequestButton = false;
  }

  async handleAbortPushRequest() {
    this.disableAbortPushRequestButton = true;
    await abortInitiatedPushRequest(this.pushRequest.Id);
    await this.handleRefreshPushRequestStatus();
    this.disableAbortPushRequestButton = false;
  }

  async handleAbortPushJob(event) {
    const {
      pushJob: { Id }
    } = event.detail;

    await abortInitiatedPushJob(Id);
    await this.handleRefreshPushRequestStatus();
  }

  async handleRefreshPushRequestStatus() {
    this.disableRefreshPushRequestStatusButton = true;
    const { pushRequest, pushJobs } = await getPushRequestJobs(
      this.pushRequest.Id,
      this.subscribers
    );

    this.pushRequest = pushRequest;
    this.pushJobs = pushJobs;
    this.disableRefreshPushRequestStatusButton = false;
  }
}
