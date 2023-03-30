import { LightningElement, api } from "lwc";

export default class PkgrPushJobs extends LightningElement {
  columns = [
    {
      label: "Org Key",
      fieldName: "SubscriberOrganizationKey",
      hideDefaultActions: true
    },
    { label: "Org Name", fieldName: "OrgName", hideDefaultActions: true },
    { label: "Org Type", fieldName: "OrgType", hideDefaultActions: true },
    { label: "Org Status", fieldName: "OrgStatus", hideDefaultActions: true },
    {
      label: "Instance Name",
      fieldName: "InstanceName",
      hideDefaultActions: true
    },
    {
      label: "Installation Status",
      fieldName: "Status",
      hideDefaultActions: true
    },
    {
      type: "button",
      typeAttributes: {
        label: "Abort",
        variant: "destructive-text",
        disabled: { fieldName: "abortButtonDisabled" }
      },
      cellAttributes: { alignment: "right" }
    }
  ];

  @api pushJobs = [];

  handleAbortPushJob(event) {
    const { row } = event.detail;

    row.abortButtonDisabled = true;

    this.dispatchEvent(
      new CustomEvent("abortpushjob", {
        detail: {
          pushJob: row
        }
      })
    );
  }
}