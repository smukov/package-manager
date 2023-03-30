import { LightningElement, api } from "lwc";

export default class PkgrPackageVersions extends LightningElement {
  columns = [
    { label: "Org Key", fieldName: "OrgKey", hideDefaultActions: true },
    { label: "Org Name", fieldName: "OrgName", hideDefaultActions: true },
    { label: "Org Type", fieldName: "OrgType", hideDefaultActions: true },
    { label: "Org Status", fieldName: "OrgStatus", hideDefaultActions: true },
    {
      label: "Instance Name",
      fieldName: "InstanceName",
      hideDefaultActions: true
    },
    {
      label: "Installed Status",
      fieldName: "InstalledStatus",
      hideDefaultActions: true
    },
    {
      label: "Installed Version",
      fieldName: "installedVersion",
      hideDefaultActions: true,
      cellAttributes: {
        iconName: {
          fieldName: "installedVersionIcon"
        },
        iconPosition: "left",
        iconAlternativeText: "Installed Version Icon"
      }
    },
    {
      type: "button",
      typeAttributes: {
        label: { fieldName: "actionLabel" },
        disabled: { fieldName: "actionDisabled" },
        variant: { fieldName: "actionVariant" }
      },
      cellAttributes: { alignment: "right" }
    }
  ];

  @api subscribers = [];

  handleEnqueueSubscriberToggle(event) {
    const { row } = event.detail;

    row.enqueued = !row.enqueued;

    if (row.enqueued) {
      row.actionLabel = "Cancel";
      row.actionVariant = "destructive-text";
    } else {
      row.actionLabel = row.storedActionLabel;
      row.actionVariant = "";
    }

    this.dispatchEvent(new CustomEvent("enqueuesubscribertoggle"));
  }
}