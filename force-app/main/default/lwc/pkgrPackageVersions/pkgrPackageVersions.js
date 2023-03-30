import { LightningElement, api } from "lwc";

export default class PkgrPackageVersions extends LightningElement {
  columns = [
    { label: "Name", fieldName: "Name", hideDefaultActions: true },
    {
      label: "Release State",
      fieldName: "ReleaseState",
      hideDefaultActions: true
    },
    { label: "Version", fieldName: "version", hideDefaultActions: true },
    {
      label: "IsDeprecated",
      fieldName: "IsDeprecated",
      hideDefaultActions: true
    },
    {
      type: "button",
      typeAttributes: {
        iconName: "utility:chevronright",
        label: "Open"
      },
      cellAttributes: { alignment: "right" }
    }
  ];

  @api packageId;
  @api packageVersions = [];

  handleOpenPackageVersion(event) {
    const { row } = event.detail;

    this.dispatchEvent(
      new CustomEvent("openpackageversion", {
        detail: {
          unlockedPackageVersion: row
        }
      })
    );
  }
}