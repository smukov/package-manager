/**
 * Utility function for invoking WorkspaceAPI (console) methods from LWC without needing to wrap in Aura
 * @param {string} methodName
 * @param {any[]} methodArgs
 * @returns
 */
function invokeWorkspaceAPI(methodName, methodArgs) {
  return new Promise((resolve, reject) => {
    const apiEvent = new CustomEvent("internalapievent", {
      bubbles: true,
      composed: true,
      cancelable: false,
      detail: {
        category: "workspaceAPI",
        methodName: methodName,
        methodArgs: methodArgs,
        callback: (err, response) => {
          if (err) {
            return reject(err);
          }
          return resolve(response);
        }
      }
    });

    window.dispatchEvent(apiEvent);
  });
}

/**
 * Set Salesforce Console tab Label and Icon
 * @param {string} label  tab label
 * @param {string} icon   tab icon
 */
async function setTabLabelAndIcon(label, icon) {
  const isConsole = await invokeWorkspaceAPI("isConsoleNavigation");

  if (isConsole) {
    const { tabId } = await invokeWorkspaceAPI("getFocusedTabInfo");
    if (label) {
      invokeWorkspaceAPI("setTabLabel", {
        tabId: tabId,
        label
      });
    }
    if (icon) {
      invokeWorkspaceAPI("setTabIcon", {
        tabId: tabId,
        icon
      });
    }
  }
}

export { invokeWorkspaceAPI, setTabLabelAndIcon };
