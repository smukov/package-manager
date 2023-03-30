import { LightningElement, track } from "lwc";
import { parseServerResponse } from "c/utilServer";
import getPackages from "@salesforce/apex/PKGR_AppCnt.getPackages";

export default class PkgrPackages extends LightningElement {
  columns = [
    { label: "Name", fieldName: "Name", hideDefaultActions: true },
    {
      label: "Package Category",
      fieldName: "PackageCategory",
      hideDefaultActions: true
    },
    {
      label: "Namespace",
      fieldName: "NamespacePrefix",
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

  @track packages = [];

  connectedCallback() {
    Promise.all([getPackages()]).then((results) => {
      const response = parseServerResponse(results[0]);
      console.log("getPackages", response);

      const { records } = response;
      this.packages = records;
    });
  }

  handleOpenPackage(event) {
    const { row } = event.detail;

    this.dispatchEvent(
      new CustomEvent("openpackage", {
        detail: {
          unlockedPackage: row
        }
      })
    );
  }
}
