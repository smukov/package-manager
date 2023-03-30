# Salesforce Package Manager

Very simple Package Manager app that can be used to easily push package upgrades to subscribers of Salesforce unlocked packages.

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Quick Documentation

Before deploying to your DevHub, set the `PKGR_AppCnt.MOCK_RESPONSES` to `false` in order to see the actual packages from your org.

After the deployment assign to your user the **App - Package Manager** permission set in order to gain access to the *Package Manager* tab.

## Quick Overview

### See all of your packages
![Packages Overview](/imgs/1.png)

### Show available versions of the selected package
![Package Versions](/imgs/2.png)

### Check package subscribers and select them for updates or downgrades
![Subscribers](/imgs/3.png)

### Monitor the update progress
![Push Request](/imgs/4.png)
